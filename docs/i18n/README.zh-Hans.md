<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/zh-Hans/hero-dark.png">
  <img src="../images/zh-Hans/hero-light.png" alt="Tendedero。截图挂起来晾着。三张截图装在玻璃相框里，挂在 macOS 菜单栏下方的一根细绳上。">
</picture>

<h3 align="center"><a href="https://tendedero.app/?lang=zh-Hans">在 tendedero.app 上直接用浏览器试用&nbsp;&rsaquo;</a></h3>

<p align="center">
  <b>Tendedero Plus — 极致内存优化版</b>
  <br>
  常驻内存：空绳 12 MB、挂 8 张截图 19 MB（官方原版 16 MB / 27 MB）。
  <br>
  <a href="#vs-upstream">相对官方原版优化了哪些内容&nbsp;&rsaquo;</a>
  <br>
  免费开源。适用于 macOS 14 及以上。
  <br>
  <a href="../../../../releases/latest">下载&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#从源码构建">从源码构建&nbsp;&rsaquo;</a>
  <br><br>
  <a href="../../README.md">English</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.gl.md">Galego</a>&nbsp;·&nbsp;<a href="README.fr.md">Français</a>&nbsp;·&nbsp;<a href="README.pt-BR.md">Português (Brasil)</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;简体中文&nbsp;·&nbsp;<a href="README.tr.md">Türkçe</a>&nbsp;·&nbsp;<a href="README.az.md">Azərbaycanca</a>
  <br>
  <sub>本文译自英文 README。如有出入，以英文版为准。</sub>
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

## 看不见，却够得着

你每截一张图，它都会挂到屏幕顶上的一根绳上。
把指针停在菜单栏，绳子就滑下来；移开，它就收起。

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/zh-Hans/demo-dark.gif">
  <img src="../images/zh-Hans/demo-light.gif" alt="指针停在上边缘，绳子带着三张截图轻轻摇晃着滑下来，单击复制其中一张，指针离开后绳子收起。">
</picture>

<br>
<br>

## 每个动作都有手势

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/zh-Hans/bento-dark.png">
  <img src="../images/zh-Hans/bento-light.png" alt="单击复制。长按标记。拖拽分享。松手放下。">
</picture>

<br>
<br>

| | |
|:--|:--|
| 单击 | 复制这张图。 |
| 长按 | 用「标记」打开。 |
| 双击 | 用「预览」打开。 |
| 用力点按 | 用「快速查看」看一眼。 |
| 指针停在照片上，按 <kbd>空格</kbd> | 用「快速查看」放大这张图。 |
| 拖进 App | 送一份副本过去。原图仍挂在绳上。 |
| 拖进文件夹 | 存在那儿。原图从绳上取下。 |
| 拖到废纸篓，或点叉 | 松手丢弃。 |
| 指针停在菜单栏 | 在那一块屏幕上放下绳子。 |
| 点击菜单栏任意处 | 把绳子收起来。 |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | 显示或隐藏绳子。可在菜单栏的「快捷键」中更改。 |

<br>

## 桌面，终于清爽了

把截图交给 Tendedero<sup>1</sup>，它们就完全跳过桌面。
没有浮动缩略图。不用等五秒。拍下的瞬间即挂上绳，只有你拖出去的才会留下。

屏幕录制也会挂上绳，上面带一个播放按钮。按住即可剪辑。

同样的快捷键。同样的肌肉记忆。只是少了乱。

<br>

## 复制的图片也一样

按住 <kbd>⌃</kbd> 截图，或在「预览」中复制图片，它就会像其他截图一样挂上绳。
在菜单栏中打开「挂上复制的图片」，开启期间图标里的衬衫会被填满。只挂图片：
与文字或文件一起复制的内容，以及密码管理器标为私密的内容，都不会被挂上。

<br>

## 隐私是设计前提

没有账号。不联网。无统计。
Tendedero 完全在你的 Mac 上运行，截图不会离开这台电脑。

<br>

## 技术规格

| | |
|:--|:--|
| **兼容性** | macOS 14 Sonoma 及以上，Apple 芯片与 Intel 均支持。已针对 macOS 27 设计。 |
| **体积** | 1.7 MB |
| **语言** | 英语、西班牙语、加利西亚语、法语、巴西葡萄牙语、日语、韩语、简体中文、土耳其语、阿塞拜疆语 |
| **技术栈** | Swift、AppKit 与 SwiftUI |
| **网络访问** | 无 |
| **价格** | 免费 |
| **许可** | 代码为 MIT。名称与图标不在授权范围内。 |

<br>

## 安装

从[最新发布](../../../../releases/latest)下载磁盘映像，打开后把 Tendedero Plus 拖进「应用程序」。要得到上表中的内存数字，请改为从源码构建：已发布的映像早于按需解码与 `MallocSpaceEfficient` 改动。

Homebrew 安装的是**官方原版** Tendedero，不是本 fork：

```sh
brew install --cask alejandrobujan/tap/tendedero
```

官方原版已使用 Developer ID 签名并通过 Apple 公证，打开方式和其他 App 一样。本 fork 的构建是 ad hoc 签名，首次打开需右键点按 App 再选「打开」。设置 `SIGN_IDENTITY` 与 `tendedero-notary` 凭据后，`scripts/build-app.sh` 与 `scripts/make-dmg.sh` 会用你自己的 Developer ID 签名并公证。

<br>

## 从源码构建

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

需要 Swift 工具链，Xcode 可选。若使用 macOS 27 的命令行工具，脚本会回退到随其一同安装的 macOS 26 SDK，因为新版 SDK 需要只有 Xcode 才带的 SwiftUI 宏插件。本地构建采用 ad-hoc 签名，所以每次重新构建后 macOS 都会再次询问桌面访问权限。

<details>
<summary>应用内部</summary>
<br>

| 文件 | 作用 |
|:--|:--|
| `AppDelegate.swift` | 菜单栏、快捷键、放下与收起绳子 |
| `LinePanel.swift` | 屏幕顶部那条透明的窄条 |
| `LineView.swift` | 绳子本身，以及每张照片挂在哪里 |
| `PeggedView.swift` | 一张照片：玻璃相框、夹子、摇摆与微风 |
| `GrabArea.swift` | 单击、长按、拖放 |
| `ScreenshotWatcher.swift` | 发现新的截图 |
| `Inbox.swift` | 接管截图设置，之后再把它们放回去 |
| `ClipboardWatcher.swift` | 发现复制到剪贴板的图片 |
| `Markup.swift` | 打开系统「标记」编辑器并保存结果 |
| `Trim.swift` | 剪辑屏幕录制并保存结果 |
| `FullScreen.swift` | 判断何时该保持隐藏 |
| `Line.swift` | 绳上挂着什么，以及你能对它做什么 |

这里出现的每一张图——包括图标——都是由代码绘制的：
`scripts/make-icon.swift` 与 `scripts/make-readme-art.swift`。
`scripts/make-dmg.sh` 负责构建发布用的磁盘映像。

翻译文件位于 `Sources/Tendedero/Resources`，每种语言一个 `.lproj` 文件夹。
`swift scripts/check-strings.swift` 会检查是否有遗漏。

</details>

<br>

---

<sub>
1. 首次启动时，Tendedero 会询问是否接管你的截图。如果同意，它会关闭浮动缩略图，并把新截图保存到它自己的文件夹，这两项设置也可以在 Cmd+Shift+5 的「选项」中找到。你原来的设置会被保存，并在退出 Tendedero 或从菜单栏关闭该选项时恢复。当有 App 处于全屏时，Tendedero 会自动隐藏。
</sub>

<br>
<br>

<p align="center">
  <img src="../images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>代码采用 MIT 许可。Tendedero 这一名称与图标不在许可范围内，因此 fork 需要自备名称与图标。详见 <a href="../../LICENSE">LICENSE</a>。</sub>
  <br>
  <sub>由 <a href="https://alejandrobujan.com">Alejandro Buján</a> 设计与开发。</sub>
</p>
