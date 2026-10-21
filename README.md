<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/hero-dark.png">
  <img src="docs/images/hero-light.png" alt="Tendedero. Screenshots, hung out to dry. Three screenshots in glass frames hang from a thin line under the macOS menu bar.">
</picture>

<h3 align="center"><a href="https://tendedero.app/?lang=en">Try it in your browser at tendedero.app&nbsp;&rsaquo;</a></h3>

<p align="center">
  <b>Tendedero Plus — Extreme Memory Optimization Edition</b>
  <br>
  Optimized for ultra-low memory footprint: 12 MB resident with an empty line, 19 MB with eight screenshots on it
  (official build: 16 MB / 27 MB). Numbers are for the current source build; the released image is older.
  <br>
  <a href="#vs-upstream">What is different from upstream&nbsp;&rsaquo;</a>
  <br>
  Free and open source. For macOS 14 and later.
  <br>
  <a href="../../releases/latest">Download&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#build-from-source">Build from source&nbsp;&rsaquo;</a>
  <br><br>
  English&nbsp;·&nbsp;<a href="docs/i18n/README.es.md">Español</a>&nbsp;·&nbsp;<a href="docs/i18n/README.gl.md">Galego</a>&nbsp;·&nbsp;<a href="docs/i18n/README.fr.md">Français</a>&nbsp;·&nbsp;<a href="docs/i18n/README.pt-BR.md">Português (Brasil)</a>&nbsp;·&nbsp;<a href="docs/i18n/README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="docs/i18n/README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="docs/i18n/README.zh-Hans.md">简体中文</a>&nbsp;·&nbsp;<a href="docs/i18n/README.tr.md">Türkçe</a>&nbsp;·&nbsp;<a href="docs/i18n/README.az.md">Azərbaycanca</a>
</p>

---

<a id="vs-upstream"></a>

### ✨ 相对官方原版的优化 (What is different from upstream)

> 本仓库是官方 [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero)（下称**官方原版**）的 fork，基线为官方 v1.5.0。
> 功能与交互与官方一致，改动集中在三处：**常驻内存**、**命名标识**、**打包脚本**。

#### 1. 常驻内存（主要改动）

| 线收起稳态 | 官方原版 1.5.0 | Plus 已发布版 v1.5.0-plus | Plus 当前源码 1.5.2-plus |
|:--|--:|--:|--:|
| 空晾衣绳 | 16 MB | 16 MB | **12 MB** |
| 挂 8 张真实尺寸截图 | 27 MB | 28 MB | **19 MB** |

测量口径：同一台机器、均为 arm64 release 构建；官方按官方脚本参数，Plus 按本项目脚本参数。取系统 `footprint` 的 `64-bit Footprint` 值，指针离开菜单栏、线收起稳态；每档 3 轮 × 3 次读数取中位数（官方 16–17 / 24–28 MB，已发布 Plus 16–17 / 26–30 MB，当前源码 11–12 / 19 MB）。

> **版本提示**：截至 2026-10-21，GitHub 已发布的 DMG 是 **v1.5.0-plus (build 6)**，不含 `MallocSpaceEfficient` 与照片按需解码，所以它的内存与官方原版相当（上表第 2 列）。第 3 列是当前源码 `scripts/build-app.sh` 的构建结果，也就是下一版会发布的内容。

#### 2. 官方原版没有的内存与 CPU 优化

1. **剪贴板大图零常驻**：官方持有上一张复制图片的原始 `Data`；Plus 只留 Hash 与 Size 元数据判重（`ClipboardWatcher.swift`），复制高清图不再产生数兆级隐式驻留。
2. **照片按需解码**：官方在启动恢复时把每张照片解码成缩略图并常驻（`Line.swift` 的 `restore()` 逐张 `makeThumbnail`）；Plus 只在拉线时解码屏幕内及相邻两侧的卡片。
3. **收线即释放像素**：线收起 0.3 秒后清空全部缩略图并调用 `malloc_zone_pressure_relief`（`Line.swift` 的 `unloadThumbnails()`）。
4. **卡片尺寸只读文件头**：新增 `thumbnailSize()` 只读 `CGImageSource` 属性，卡片无需像素即可成形（`Line.swift`）。
5. **面板视图按需挂载**：`NSHostingView` 只在拉线时挂载、收线后卸载，图层树不常驻（`AppDelegate.swift`）。
6. **自适应轮询降频**：隐藏态 30 → 10 FPS，展开态恢复 30 FPS（`AppDelegate.swift` 的 `updateMouseTimerRate()`）。
7. **屏幕对象持久缓存**：缓存屏幕信息，避免每次轮询调用 `NSScreen.screens` 的数组桥接拷贝。
8. **主动内存紧缩与系统压力响应**：面板收起、丢弃截图、空闲时调用 `malloc_zone_pressure_relief`，并注册 `DispatchSourceMemoryPressure`（`AppDelegate.swift`）。
9. **动画高清位图即时解绑**：飞落动画用的大图结束后立即置空 `CALayer.contents`（`CaptureFlight.swift`）。
10. **编译参数**：追加 `-Xswiftc -Osize -Xswiftc -wmo`（`scripts/build-app.sh`）。

#### 3. 命名、文案与打包（不影响功能）

| 项目 | 官方原版 | Tendedero Plus |
|:--|:--|:--|
| 应用名 | `Tendedero` | `Tendedero Plus` |
| 可执行文件 | `Tendedero` | `TendederoPlus` |
| 版本号 | `1.5.0` (build 6) | `1.5.2-plus` (build 8) |
| Bundle ID | `app.tendedero.Tendedero` | 未改，同左：可直接覆盖安装官方版，不会出现两个 App，设置不丢 |
| 菜单栏 | `Tendedero`、`Quit Tendedero` | tooltip 与菜单顶部品牌项 `Tendedero Plus (v1.5.2-plus)`、`Quit Tendedero Plus`，10 种语言同步 |
| 面板 | 无 | 右上 `TENDEDERO PLUS` 徽标；空线提示带 `PLUS` 胶囊 |
| 打包产物 | `build/Tendedero.app`、`Tendedero-<版本>.dmg` | `build/Tendedero Plus.app`、`Tendedero-Plus-<版本>.dmg`，卷名 `Tendedero Plus` |

#### 4. 与官方保持一致

- 功能、手势、快捷键、10 种语言与隐私设计（无账号、无网络、无分析）不变；本分支不新增也不移除功能，菜单只多一行品牌项。
- 授权不变：代码 MIT；`Tendedero` 名称与图标不在 MIT 授权内。
- 自行复核差异：`git remote add upstream https://github.com/alejandrobujan/tendedero.git`，再执行 `git log --oneline upstream/main..HEAD`（当前 7 个提交、33 个文件）。

---

<p align="center">
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/daily?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/weekly?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
</p>

<br>

## Out of sight. Within reach.

Every screenshot you take hangs on a line just above your screen.
Rest the pointer in the menu bar and it glides down. Move away and it's gone.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-dark.gif">
  <img src="docs/images/demo-light.gif" alt="The pointer rests against the top edge, the line slides down with three screenshots swinging gently, a click copies one, and the line tucks away when the pointer leaves.">
</picture>

<br>
<br>

## A gesture for everything.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/bento-dark.png">
  <img src="docs/images/bento-light.png" alt="Click to copy. Hold to mark up. Drag to share. Let it go.">
</picture>

<br>
<br>

| | |
|:--|:--|
| Click | Copy the image. |
| Press and hold | Open it in Markup. |
| Double click | Open it in Preview. |
| Force click | Take a quick look. |
| Drag into an app | Send a copy. It stays on the line. |
| Drag into a folder | Keep it there. It leaves the line. |
| Drag to the Trash, or click the cross | Let it go. |
| Rest the pointer in the menu bar | Bring the line down on that screen. |
| Click anything in the menu bar | Put it away. |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | Show or hide the line. Change it under Shortcut in the menu bar. |

<br>

## Your Desktop. Finally clear.

Hand Tendedero your screenshots<sup>1</sup> and they skip the Desktop
entirely. No floating thumbnail. No five-second wait. Each capture hangs
the instant you take it, and only what you drag out is kept.

Screen recordings hang there too, with a play button over them.
Press and hold one to trim it.

Same shortcuts. Same muscle memory. Just less mess.

<br>

## Copied images too.

Take a screenshot with <kbd>⌃</kbd> held, or copy an image in Preview, and it
hangs on the line like any other. Turn on Hang copied images in the menu bar
and the shirt fills in while it is on. Only images: anything copied along
with text or a file, and anything a password manager marks as private, is
left alone.

<br>

## Private by design.

No account. No network. No analytics.
Tendedero runs entirely on your Mac, and your screenshots never leave it.

<br>

## Tech Specs

| | |
|:--|:--|
| **Compatibility** | macOS 14 Sonoma or later, on Apple silicon and Intel. Designed for macOS 27. |
| **Size** | 1.7 MB |
| **Languages** | English, Spanish, Galician, French, Portuguese (Brazil), Japanese, Korean, Chinese (Simplified), Turkish, Azerbaijani |
| **Built with** | Swift, AppKit and SwiftUI |
| **Network access** | None |
| **Price** | Free |
| **License** | MIT for the code. The name and icon are not included. |

<br>

## Install

Download the disk image from the [latest release](../../releases/latest),
open it and drag Tendedero Plus to Applications. To get the memory numbers in
the table above, build from source instead: the released image predates the
on-demand decoding and `MallocSpaceEfficient` changes.

The Homebrew cask installs the **official** Tendedero, not this fork:

```sh
brew install --cask alejandrobujan/tap/tendedero
```

The official app is signed with a Developer ID and notarized by Apple, so it
opens like any other app. This fork is signed ad hoc, so the first time you
open it, right-click the app and choose Open. `scripts/build-app.sh` and
`scripts/make-dmg.sh` sign and notarize with your own Developer ID when
`SIGN_IDENTITY` and the `tendedero-notary` profile are set.

<br>

## Build from source

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

Requires the Swift toolchain. Xcode is optional. With the Command Line Tools for macOS 27, the script falls back to the macOS 26 SDK they install alongside, because the new SDK needs a SwiftUI macro plugin only Xcode includes. Local builds are signed ad hoc,
so macOS asks again for access to the Desktop after each rebuild.

<details>
<summary>Inside the app</summary>
<br>

| File | Role |
|:--|:--|
| `AppDelegate.swift` | Menu bar, shortcut, revealing and tucking away the line |
| `LinePanel.swift` | The transparent strip along the top of the screen |
| `LineView.swift` | The line and where each photo hangs |
| `PeggedView.swift` | One photo: glass frame, clip, swing and breeze |
| `GrabArea.swift` | Click, long press, drag and drop |
| `ScreenshotWatcher.swift` | Notices new screenshots |
| `ClipboardWatcher.swift` | Notices images copied to the clipboard |
| `Inbox.swift` | Takes over screenshot settings and puts them back |
| `Markup.swift` | Opens the system Markup editor and saves the result |
| `Trim.swift` | Trims a screen recording and saves the result |
| `FullScreen.swift` | Knows when to stay hidden |
| `Line.swift` | What is hanging, and what you can do with it |

Every image here, the icon included, is drawn in code by
`scripts/make-icon.swift` and `scripts/make-readme-art.swift`.
`scripts/make-dmg.sh` builds the disk image for releases.

Translations live in `Sources/TendederoPlus/Resources`, one `.lproj` folder per
language. `swift scripts/check-strings.swift` checks that none is missing.

</details>

<br>

---

<sub>
1. On first launch, Tendedero offers to handle your screenshots. If you accept, it turns off the floating thumbnail and saves new screenshots to its own folder, two settings also found under Options in Cmd+Shift+5. Your previous settings are saved and restored when Tendedero quits or the option is turned off from the menu bar. Tendedero hides automatically while an app is in full screen.
</sub>

<br>
<br>

<p align="center">
  <img src="docs/images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>The code is MIT licensed. The Tendedero name and icon are not, so forks need their own. See <a href="LICENSE">LICENSE</a>.</sub>
  <br>
  <sub>Designed and built by <a href="https://alejandrobujan.com">Alejandro Buján</a>.</sub>
</p>
