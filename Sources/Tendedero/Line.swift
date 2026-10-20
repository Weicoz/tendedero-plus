import AppKit
import AVFoundation
import Combine
import ImageIO
import os

let log = Logger(subsystem: "app.tendedero.Tendedero", category: "line")

/// One screenshot hanging on the line.
struct Pegged: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    /// The decoded photo. Only kept while the line is in view: a screenful of
    /// them is the line's biggest footprint, and away they are let go.
    var thumb: NSImage?
    /// How big the photo on the card is. Read from the file's header alone, so
    /// the card keeps its shape with no image at hand.
    var thumbSize: NSSize
    /// Every photo hangs a little crooked, like on a real line.
    let tilt = Double.random(in: -2.5...2.5)
    var falling = false
    /// Still flying in from where it was captured; the card waits hidden.
    var flying = false
    /// A screen recording rather than a screenshot.
    var isRecording: Bool { Tendedero.isRecording(url) }

    static func == (a: Pegged, b: Pegged) -> Bool {
        a.id == b.id && a.falling == b.falling && a.flying == b.flying && a.thumb === b.thumb
    }
}

/// The line itself: what hangs on it and what you can do with each item.
/// The files never move. The line is only a view onto them.
@MainActor
final class Line: ObservableObject {
    @Published private(set) var items: [Pegged] = []
    @Published private(set) var gust = 0
    @Published var copiedID: UUID?
    @Published var draggingID: UUID?
    @Published var pressedID: UUID?
    /// Whether the line has slid down into view.
    @Published var revealed = false

    /// Card frames in window coordinates, reported by the views. The panel
    /// uses them to only catch clicks over photos and let the rest through.
    var hitRects: [UUID: CGRect] = [:]
    /// The photos that have already dropped onto the line. The cards are
    /// rebuilt whenever the line comes down, and a photo that is already
    /// hanging must not fall in a second time.
    private var arrivedIDs: Set<UUID> = []

    /// Decoding a screenshot is slow enough to feel: a screenful of Retina
    /// captures takes close to a second. The line never waits for it — the
    /// photos are decoded off the main thread and drop onto their cards as
    /// they arrive.
    ///
    /// One at a time, on purpose. Decoding a 5K capture means holding its
    /// whole bitmap at once — some 15 MB — and eight of those at once would
    /// grow the heap to well over a hundred megabytes that malloc then keeps.
    /// One after another the peak is a single bitmap, and the cards fill in
    /// just as the line settles.
    private let decodeQueue = DispatchQueue(label: "app.tendedero.decode", qos: .userInitiated)
    /// Bumped every time the photos are let go, so a decode still running
    /// drops its result instead of putting a photo back after the fact.
    private var decodeGeneration = 0

    var maxItems = 8
    /// How many photos fit across the screen. With Keep on line set, the
    /// line can hold more, and the rest are reached by scrolling.
    var visibleCount = 8
    /// How far the line is scrolled towards older photos, in points; 0 shows
    /// the newest.
    @Published var scroll: CGFloat = 0

    /// Keep on line, from the menu bar: how many photos the line keeps, or
    /// nil for as many as fit across the screen.
    nonisolated static let keepChoices = [25, 50, 100]
    nonisolated static var keepOnLine: Int? {
        get {
            let n = UserDefaults.standard.integer(forKey: "keepOnLine")
            return keepChoices.contains(n) ? n : nil
        }
        set { UserDefaults.standard.set(newValue ?? 0, forKey: "keepOnLine") }
    }


    var soundOn: Bool {
        get { !UserDefaults.standard.bool(forKey: "soundOff") }
        set { UserDefaults.standard.set(!newValue, forKey: "soundOff") }
    }

    var liveCount: Int { items.filter { !$0.falling }.count }

    func hasArrived(_ id: UUID) -> Bool { arrivedIDs.contains(id) }

    /// The photo for a card, decoded here if it is still on its way. Dragging
    /// one off the line and letting one fall both need pixels at once, and
    /// both happen well after the line came down: this is the rare case of
    /// reaching a card before its own photo has arrived.
    func photo(_ id: UUID) -> NSImage? {
        guard let item = items.first(where: { $0.id == id }) else { return nil }
        return item.thumb ?? makeThumbnail(item.url)
    }

    func markArrived(_ id: UUID) {
        arrivedIDs.insert(id)
        // Only ever holds the photos that are on the line right now, plus a
        // few that have just come off it. The ones still hanging are kept, or
        // they would drop in a second time.
        if arrivedIDs.count > 200 { arrivedIDs = Set(items.map(\.id)) }
    }

    private let storeKey = "pegged"

    init() {
        restore()
        scheduleGust()
    }

    // MARK: Hanging and dropping

    @discardableResult
    func hang(_ url: URL, quietly: Bool = false, flying: Bool = false) -> UUID? {
        guard !items.contains(where: { $0.url == url && !$0.falling }),
              var item = peg(url) else { return nil }
        item.flying = flying
        items.append(item)
        if revealed, item.thumb == nil { decode(item.id, decodeGeneration) }
        scroll = 0
        // A full line lets the oldest photo fall off the far end. Only one: a
        // line hung on a wider screen keeps its length here instead of losing
        // several photos to a single capture.
        if liveCount > maxItems, let oldest = items.first(where: { !$0.falling }) {
            letGo(oldest.id)
        }
        save()
        if !quietly { play("Tink", volume: 0.35) }
        return item.id
    }

    /// The capture has reached the line: the real card takes over.
    func land(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].flying = false
    }

    /// Called just before a photo starts falling, so the fall can be drawn
    /// over the whole screen.
    var onFall: ((Pegged) -> Void)?

    func drop(_ id: UUID, quietly: Bool = false) {
        guard let i = items.firstIndex(where: { $0.id == id }), !items[i].falling else { return }
        onFall?(items[i])
        items[i].falling = true
        hitRects[id] = nil
        save()
        if !quietly { play("Pop", volume: 0.25) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.items.removeAll { $0.id == id }
            malloc_zone_pressure_relief(nil, 0)
        }
    }

    /// "Take everything down": every photo goes the way of its corner cross.
    func clear() {
        takeDown(items.filter { !$0.falling })
    }

    /// The photos hung before (left) or after (right) this one.
    func neighbours(of id: UUID, toTheLeft: Bool) -> [Pegged] {
        let live = items.filter { !$0.falling }
        guard let i = live.firstIndex(where: { $0.id == id }) else { return [] }
        return toTheLeft ? Array(live[..<i]) : Array(live[(i + 1)...])
    }

    /// Takes down everything on one side of a photo. Each one goes the way
    /// of its own corner button: to the Trash from Tendedero's folder, and
    /// only off the line from anywhere else.
    func takeDown(_ id: UUID, toTheLeft: Bool) {
        takeDown(neighbours(of: id, toTheLeft: toTheLeft))
    }

    /// One after another, and only the first makes a sound.
    private func takeDown(_ live: [Pegged]) {
        for (n, item) in live.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 * Double(n)) { [weak self] in
                self?.discard(item.id, quietly: n > 0)
            }
        }
    }

    /// Photos whose file was deleted or moved away fall off by themselves.
    func prune() {
        for item in items where !item.falling && !FileManager.default.fileExists(atPath: item.url.path) {
            drop(item.id, quietly: true)
        }
    }

    // MARK: Actions on one photo

    func copy(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let entry = NSPasteboardItem()
        // A recording is copied as the file, which apps paste as the video.
        if !item.isRecording, let png = pngData(item.url) { entry.setData(png, forType: .png) }
        entry.setString(item.url.absoluteString, forType: .fileURL)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([entry])

        copiedID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.copiedID == id { self?.copiedID = nil }
        }
    }

    func open(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.open(item.url)
    }

    /// Moves the file to the Trash and takes the photo off the line. When a
    /// drag ends on the Dock's Trash, macOS only reports it: deleting the file
    /// is the source app's job, as Finder does.
    @discardableResult
    func trash(_ id: UUID, quietly: Bool = false) -> Bool {
        guard let item = items.first(where: { $0.id == id }) else { return false }
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            log.notice("Trashed \(item.url.lastPathComponent, privacy: .public)")
            if soundOn && !quietly { Line.trashSound?.play() }
            drop(id, quietly: true)
            return true
        } catch {
            log.error("Could not trash \(item.url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            if !quietly { NSSound.beep() }
            return false
        }
    }

    private static let trashSound = NSSound(
        contentsOfFile: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/drag to trash.aif",
        byReference: true)

    /// Whether the file lives in Tendedero's own folder. Those are discarded
    /// to the Trash, or the folder would fill up with forgotten screenshots.
    /// Files anywhere else, like the Desktop, stay where they are.
    func isInInbox(_ id: UUID) -> Bool {
        guard let item = items.first(where: { $0.id == id }) else { return false }
        return item.url.standardizedFileURL.path.hasPrefix(Inbox.folder.standardizedFileURL.path + "/")
    }

    /// The corner cross and "Take down" both end up here.
    func discard(_ id: UUID, quietly: Bool = false) {
        if isInInbox(id) { trash(id, quietly: quietly) } else { drop(id, quietly: quietly) }
    }

    /// The oldest photo falling off a full line. Like the cross, a file from
    /// Tendedero's folder goes to the Trash, or nothing would ever take it out
    /// of that folder. If the Trash refuses it, it still leaves the line.
    /// Moves along a line that holds more than fit, from a scroll gesture.
    func scroll(by delta: CGFloat) {
        let most = CGFloat(max(0, items.count - visibleCount)) * Layout.spacing
        let next = min(most, max(0, scroll + delta))
        guard next != scroll else { return }
        scroll = next
        // Photos scrolled into view are decoded as they come in.
        if revealed { loadThumbnails() }
    }

    /// After Keep on line is lowered, the oldest photos past it go the way
    /// of a full line.
    func trim() {
        while liveCount > maxItems, let oldest = items.first(where: { !$0.falling }) {
            letGo(oldest.id)
        }
        scroll = 0
    }

    private func letGo(_ id: UUID) {
        if isInInbox(id), trash(id, quietly: true) { return }
        drop(id, quietly: true)
    }

    /// Inbox mode: keep a screenshot by moving it to the Desktop.
    func saveToDesktop(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let target = uniqueURL(in: desktop, for: item.url.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: item.url, to: target)
            drop(id, quietly: true)
        } catch {
            log.error("Could not save to Desktop: \(error.localizedDescription, privacy: .public)")
            NSSound.beep()
        }
    }

    private func uniqueURL(in folder: URL, for name: String) -> URL {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = folder.appendingPathComponent(name)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(base) \(n)").appendingPathExtension(ext)
            n += 1
        }
        return candidate
    }

    /// Long press: open the photo in the system Markup editor. Markup does
    /// not edit video, so a recording opens in the trimming editor instead.
    func markup(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        if item.isRecording {
            Trim.shared.edit(item.url, size: item.thumbSize)
        } else {
            Markup.shared.edit(item.url)
        }
    }

    /// After editing, the photo on the line shows the new version.
    func reloadThumbnail(for url: URL) {
        guard let item = items.first(where: { $0.url == url && !$0.falling }) else { return }
        decode(item.id, decodeGeneration)
    }

    /// Quick Look on this photo, with the rest of the line a key press away.
    func quickLook(_ id: UUID) {
        let live = items.filter { !$0.falling }
        guard let index = live.firstIndex(where: { $0.id == id }) else { return }
        QuickLook.shared.show(live.map(\.url), at: index)
    }

    /// After a change of size, every photo is redrawn sharp at the new one.
    /// Away from the screen only the card's size is worked out: the images
    /// wait until the line comes down again.
    func reloadThumbnails() {
        let generation = decodeGeneration
        let showing = onScreen
        for i in items.indices where !items[i].falling {
            if revealed {
                items[i].thumb = nil
                if showing.contains(i) { decode(items[i].id, generation) }
            } else if let size = thumbnailSize(items[i].url) {
                items[i].thumbSize = size
            }
        }
    }

    /// The cards on screen right now, with one either side of them so a
    /// scroll has something to show while the next ones arrive. A long line
    /// keeps the photos it is not showing off the heap.
    private var onScreen: Range<Int> {
        let count = items.count
        guard count > visibleCount else { return 0..<count }
        let step = max(0, Int((scroll / Layout.spacing).rounded(.down)))
        let newest = count - 1 - step
        return max(0, newest - visibleCount)..<min(count, newest + 2)
    }

    /// The line is coming down: every photo without one starts decoding. The
    /// cards are on screen before any of them is ready, which is the point.
    func loadThumbnails() {
        let generation = decodeGeneration
        for i in onScreen where items[i].thumb == nil { decode(items[i].id, generation) }
    }

    /// Tucked away, the photos are let go and their pages handed back.
    func unloadThumbnails() {
        decodeGeneration &+= 1
        for i in items.indices where items[i].thumb != nil { items[i].thumb = nil }
        malloc_zone_pressure_relief(nil, 0)
    }

    /// One photo, decoded away from the main thread and hung on its card if
    /// the card is still there and the line is still down.
    private func decode(_ id: UUID, _ generation: Int) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let url = item.url
        decodeQueue.async { [weak self] in
            let thumb = makeThumbnail(url)
            DispatchQueue.main.async {
                guard let self, generation == self.decodeGeneration, self.revealed,
                      let thumb, let i = self.items.firstIndex(where: { $0.id == id })
                else { return }
                self.items[i].thumb = thumb
                self.items[i].thumbSize = thumb.size
            }
        }
    }

    func reveal(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    // MARK: Breeze

    /// Every so often a little wind moves the line. It is the detail that
    /// makes it feel like an object and not a widget.
    private func scheduleGust() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 7...16)) { [weak self] in
            guard let self else { return }
            if !self.items.isEmpty && self.draggingID == nil { self.gust += 1 }
            self.scheduleGust()
        }
    }

    // MARK: Persistence

    private func save() {
        let paths = items.filter { !$0.falling }.map(\.url.path)
        UserDefaults.standard.set(paths, forKey: storeKey)
    }

    /// Everything comes back as it was. This runs before the line knows its
    /// screen, so the capacity is still the default one: hanging through
    /// `hang` would let photos fall off a wide screen's line at every launch.
    private func restore() {
        let paths = UserDefaults.standard.stringArray(forKey: storeKey) ?? []
        for path in paths where FileManager.default.fileExists(atPath: path) {
            let url = URL(fileURLWithPath: path)
            guard !items.contains(where: { $0.url == url }), let item = peg(url) else { continue }
            items.append(item)
        }
    }

    // MARK: Helpers

    private func play(_ name: String, volume: Float) {
        guard soundOn, let sound = NSSound(named: name)?.copy() as? NSSound else { return }
        sound.volume = volume
        sound.play()
    }

    /// One photo ready for the line. A screenshot's card is sized from the
    /// file's own header, and its pixels are decoded later, off the main
    /// thread: a capture must not wait for its own picture to be drawn.
    private func peg(_ url: URL) -> Pegged? {
        // A recording has no header to read, so its first frame is decoded to
        // find the card's shape. It is kept only if the line is down to show
        // it; otherwise it goes straight back.
        if isRecording(url) {
            guard let frame = makeThumbnail(url) else { return nil }
            return Pegged(url: url, thumb: revealed ? frame : nil, thumbSize: frame.size)
        }
        guard let size = thumbnailSize(url) else { return nil }
        return Pegged(url: url, thumb: nil, thumbSize: size)
    }

    private func pngData(_ url: URL) -> Data? {
        if url.pathExtension.lowercased() == "png" { return try? Data(contentsOf: url) }
        guard let tiff = NSImage(contentsOf: url)?.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}

/// Screen recordings, as macOS saves them.
func isRecording(_ url: URL) -> Bool {
    ["mov", "mp4"].contains(url.pathExtension.lowercased())
}

/// The default size covers a card at twice its size in points, as on a
/// Retina screen, and no more: every photo on the line keeps one in memory.
func makeThumbnail(_ url: URL, maxPixels: Int = Int(320 * Layout.size.scale)) -> NSImage? {
    autoreleasepool {
        if isRecording(url) { return firstFrame(url, maxPixels: maxPixels) }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}

/// How big the photo on the line is, from the file's header alone: no pixels
/// are decoded, so a whole line of them costs nothing to know about.
func thumbnailSize(_ url: URL, maxPixels: Int = Int(320 * Layout.size.scale)) -> NSSize? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let pixelsWide = props[kCGImagePropertyPixelWidth] as? Int,
          let pixelsHigh = props[kCGImagePropertyPixelHeight] as? Int,
          pixelsWide > 0, pixelsHigh > 0 else { return nil }
    var width = CGFloat(pixelsWide)
    var height = CGFloat(pixelsHigh)
    // An orientation from 5 to 8 turns the photo on its side.
    if let orientation = props[kCGImagePropertyOrientation] as? Int, (5...8).contains(orientation) {
        swap(&width, &height)
    }
    let scale = min(1, CGFloat(maxPixels) / max(width, height))
    return NSSize(width: (width * scale).rounded(), height: (height * scale).rounded())
}

/// A recording shows its first frame.
private func firstFrame(_ url: URL, maxPixels: Int) -> NSImage? {
    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: maxPixels, height: maxPixels)
    guard let cg = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
    return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
}
