import AppKit
import Quartz

/// A quick look at a photo without opening it: the same Quick Look window
/// Finder shows. Force click a photo, press Space while the pointer rests
/// on one, or choose Quick Look from its menu. The arrow keys go through
/// the rest of the line, and Space or Escape closes it.
///
/// The line never takes the keyboard from the app you are in: Space is
/// borrowed only while the pointer rests on a photo, and handed back the
/// moment the window opens or the pointer leaves, so the window takes the
/// keyboard and closes itself with Space.
@MainActor
final class QuickLook: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLook()

    private var urls: [URL] = []

    /// Whether the panel is up. Space belongs to it while it is: the panel
    /// closes itself with it, so the line does not take the key then.
    var isOpen: Bool { !urls.isEmpty }

    func show(_ urls: [URL], at index: Int) {
        guard !urls.isEmpty, let panel = QLPreviewPanel.shared() else { return }
        self.urls = urls
        NSApp.activate(ignoringOtherApps: true)
        // Quick Look asks the responder chain who controls it; with no
        // window of ours that is the app delegate, which hands it to us.
        panel.updateController()
        panel.reloadData()
        panel.currentPreviewItemIndex = index
        place(panel)
        panel.makeKeyAndOrderFront(nil)
        // The panel puts itself back in the middle of the screen it remembers
        // while it comes up, so it is put right once more after that.
        DispatchQueue.main.async { [weak panel] in
            guard let panel else { return }
            self.place(panel)
        }
    }

    /// Opens the panel on the screen the pointer is on. The panel remembers
    /// where it was last shown, so on a desk with more than one screen it
    /// settles on whichever one it first landed on: the photo opens and the
    /// preview is somewhere else. A preview you have to go looking for is no
    /// preview, so the panel is put where the pointer is, every time.
    private func place(_ panel: QLPreviewPanel) {
        let pointer = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) }) ?? NSScreen.main
        else { return }
        var frame = panel.frame
        // Before its first showing the panel has no size of its own.
        if frame.width < 200 || frame.height < 200 {
            frame.size = CGSize(width: 900, height: 600)
        }
        let room = screen.visibleFrame
        frame.size.width = min(frame.width, room.width)
        frame.size.height = min(frame.height, room.height)
        frame.origin = CGPoint(x: room.midX - frame.width / 2, y: room.midY - frame.height / 2)
        panel.setFrame(frame, display: false)
    }

    func take(_ panel: QLPreviewPanel) {
        panel.dataSource = self
        panel.delegate = self
    }

    func release(_ panel: QLPreviewPanel) {
        panel.dataSource = nil
        panel.delegate = nil
        urls = []
    }

    // MARK: QLPreviewPanelDataSource

    nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        MainActor.assumeIsolated { urls.count }
    }

    nonisolated func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        MainActor.assumeIsolated { urls.indices.contains(index) ? urls[index] as NSURL : nil }
    }

    // MARK: QLPreviewPanelDelegate

    /// Left and right go to the photo before or after it on the line.
    nonisolated func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        guard event.type == .keyDown, let panel else { return false }
        let step: Int
        switch Int(event.keyCode) {
        case 123: step = -1 // left arrow
        case 124: step = 1 // right arrow
        default: return false
        }
        return MainActor.assumeIsolated {
            let next = panel.currentPreviewItemIndex + step
            guard urls.indices.contains(next) else { return true }
            panel.currentPreviewItemIndex = next
            return true
        }
    }
}
