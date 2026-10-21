<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/ja/hero-dark.png">
  <img src="../images/ja/hero-light.png" alt="Tendedero。スクリーンショットを、物干しに。ガラスのフレームに入った3枚のスクリーンショットが、macOSのメニューバーの下の細いロープに吊るされている。">
</picture>

<h3 align="center"><a href="https://tendedero.app/?lang=ja">tendedero.appでブラウザから試す&nbsp;&rsaquo;</a></h3>

<p align="center">
  無料のオープンソース。macOS 14以降に対応。
  <br>
  <a href="../../../../releases/latest">ダウンロード&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#ソースからビルド">ソースからビルド&nbsp;&rsaquo;</a>
  <br><br>
  <a href="../../README.md">English</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.gl.md">Galego</a>&nbsp;·&nbsp;<a href="README.fr.md">Français</a>&nbsp;·&nbsp;<a href="README.pt-BR.md">Português (Brasil)</a>&nbsp;·&nbsp;日本語&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.zh-Hans.md">简体中文</a>&nbsp;·&nbsp;<a href="README.tr.md">Türkçe</a>&nbsp;·&nbsp;<a href="README.az.md">Azərbaycanca</a>
  <br>
  <sub>このページは英語版READMEの翻訳です。内容に相違がある場合は英語版が優先されます。</sub>
</p>

---

<a id="vs-upstream"></a>

### ✨ 公式オリジナルとの違い (What is different from upstream)

> このリポジトリは、公式の [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero)（以下**公式オリジナル**）のフォークで、ベースは公式 v1.5.0 です。
> 機能と操作感は公式と同じで、変更は 3 か所に集中しています：**常駐メモリ**、**名前と識別子**、**ビルドスクリプト**。

#### 1. 常駐メモリ（主な変更）

| ロープをしまった定常状態 | 公式オリジナル 1.5.0 | Plus リリース版 v1.5.0-plus | Plus 現在のソース 1.5.2-plus |
|:--|--:|--:|--:|
| 空のロープ | 16 MB | 16 MB | **12 MB** |
| 実寸のスクリーンショットを 8 枚吊るした状態 | 27 MB | 28 MB | **19 MB** |

測定条件：同一マシン、いずれも arm64 の release ビルド。公式は公式スクリプトの引数、Plus は本プロジェクトのスクリプト引数でビルドしています。システムの `footprint` の `64-bit Footprint` 値を取得し、ポインタがメニューバーから離れてロープをしまった定常状態で測定。各条件 3 回 × 3 回の読み取りの中央値（公式 16–17 / 24–28 MB、リリース済み Plus 16–17 / 26–30 MB、現在のソース 11–12 / 19 MB）。

> **バージョンに関する注意**：2026-10-21 時点で GitHub で公開されている DMG は **v1.5.0-plus (build 6)** で、`MallocSpaceEfficient` と写真のオンデマンドデコードを含んでいません。そのためメモリは公式オリジナルと同程度です（上の表の 2 列目）。3 列目は現在のソース `scripts/build-app.sh` でのビルド結果で、次のリリースで公開される内容です。

#### 2. 公式オリジナルにはないメモリと CPU の最適化

1. **クリップボードの大きな画像を常駐させない**：公式は直前にコピーした画像の元の `Data` を保持します。Plus はハッシュとサイズのメタデータだけで重複を判定します（`ClipboardWatcher.swift`）。高解像度画像をコピーしても、数メガバイトの暗黙の常駐は発生しません。
2. **写真のオンデマンドデコード**：公式は起動時の復元で各写真をサムネールにデコードして常駐させます（`Line.swift` の `restore()` が 1 枚ずつ `makeThumbnail`）。Plus はロープを降ろしたときに、画面内とその両隣のカードだけをデコードします。
3. **ロープをしまったら即座にピクセルを解放**：ロープをしまって 0.3 秒後にすべてのサムネールを破棄し、`malloc_zone_pressure_relief` を呼びます（`Line.swift` の `unloadThumbnails()`）。
4. **カードのサイズはファイルヘッダーだけを読む**：`thumbnailSize()` を追加し、`CGImageSource` の属性だけを読みます。ピクセルがなくてもカードを組み立てられます（`Line.swift`）。
5. **パネルビューを必要なときだけ載せる**：`NSHostingView` はロープを降ろしたときだけ載せ、しまったら外します。レイヤーツリーは常駐しません（`AppDelegate.swift`）。
6. **ポーリングを適応的に間引く**：非表示時は 30 → 10 FPS、展開時は 30 FPS に戻します（`AppDelegate.swift` の `updateMouseTimerRate()`）。
7. **スクリーンオブジェクトを永続キャッシュ**：スクリーン情報をキャッシュし、ポーリングのたびに `NSScreen.screens` を呼んで配列をブリッジコピーするのを避けます。
8. **能動的なメモリ縮小とシステムプレッシャーへの応答**：パネルをしまったとき、スクリーンショットを破棄したとき、アイドル時に `malloc_zone_pressure_relief` を呼び、`DispatchSourceMemoryPressure` を登録します（`AppDelegate.swift`）。
9. **アニメーションの高解像度ビットマップを即座に切り離す**：舞い落ちるアニメーションで使う大きな画像は、終わった直後に `CALayer.contents` を空にします（`CaptureFlight.swift`）。
10. **コンパイル引数**：`-Xswiftc -Osize -Xswiftc -wmo` を追加します（`scripts/build-app.sh`）。

#### 3. 名前、表記、パッケージング（機能には影響しません）

| 項目 | 公式オリジナル | Tendedero Plus |
|:--|:--|:--|
| アプリ名 | `Tendedero` | `Tendedero Plus` |
| 実行ファイル | `Tendedero` | `TendederoPlus` |
| バージョン | `1.5.0` (build 6) | `1.5.2-plus` (build 8) |
| Bundle ID | `app.tendedero.Tendedero` | 変更なし。左と同じ：公式版にそのまま上書きインストールでき、アプリが 2 つになることも設定が失われることもありません |
| メニューバー | `Tendedero`、`Quit Tendedero` | tooltip とメニュー先頭のブランド項目 `Tendedero Plus (v1.5.2-plus)`、`Quit Tendedero Plus`。10 言語で同期 |
| パネル | なし | 右上に `TENDEDERO PLUS` バッジ。空のロープのヒントには `PLUS` カプセル |
| パッケージ成果物 | `build/Tendedero.app`、`Tendedero-<版本>.dmg` | `build/Tendedero Plus.app`、`Tendedero-Plus-<版本>.dmg`、ボリューム名は `Tendedero Plus` |

#### 4. 公式と同じところ

- 機能、ジェスチャ、ショートカット、10 言語、プライバシー設計（アカウントなし、ネットワークなし、解析なし）は変わりません。このブランチは機能を追加も削除もせず、メニューに 1 行ブランド項目が増えるだけです。
- ライセンスも変更なし：コードは MIT。`Tendedero` の名前とアイコンは MIT ライセンスの対象外です。
- 差分は自分で確認できます：`git remote add upstream https://github.com/alejandrobujan/tendedero.git` を実行し、`git log --oneline upstream/main..HEAD`（現在 7 コミット、33 ファイル）。

---

<p align="center">
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/daily?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/weekly?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
</p>

<br>

## 目には入らず、手は届く。

撮ったスクリーンショットはすべて、画面のすぐ上のロープに吊るされます。
メニューバーにポインタを置くと、するりと降りてきます。離れると消えます。

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/ja/demo-dark.gif">
  <img src="../images/ja/demo-light.gif" alt="ポインタが画面の上端に触れると、3枚のスクリーンショットをゆらゆら揺らしながらロープが降りてくる。1枚をクリックしてコピーし、ポインタが離れるとロープはしまわれる。">
</picture>

<br>
<br>

## どんな操作も、ジェスチャひとつで。

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/ja/bento-dark.png">
  <img src="../images/ja/bento-light.png" alt="クリックでコピー。長押しでマークアップ。ドラッグで共有。あとは手放すだけ。">
</picture>

<br>
<br>

| | |
|:--|:--|
| クリック | 画像をコピー。 |
| 長押し | 「マークアップ」で開く。 |
| ダブルクリック | 「プレビュー」で開く。 |
| 強めのクリック | クイックルックでさっと確認。 |
| アプリにドラッグ | コピーを送る。ロープには残ります。 |
| フォルダにドラッグ | そこに保存。ロープからは外れます。 |
| ゴミ箱にドラッグ、または×をクリック | 手放す。 |
| メニューバーにポインタを置く | その画面にロープを降ろす。 |
| メニューバーのどこかをクリック | ロープをしまう。 |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | ロープを表示または非表示。メニューバーの「ショートカット」で変更できます。 |

<br>

## デスクトップが、やっとすっきり。

スクリーンショットをTendederoに任せれば<sup>1</sup>、デスクトップを一切経由しません。
フローティングサムネールも、5秒の待ち時間もなし。撮った瞬間にロープに吊るされ、残るのはドラッグして取り出したものだけです。

画面収録もロープに吊るされ、再生ボタンが付きます。
長押しすればトリミングできます。

ショートカットはそのまま。手が覚えた操作もそのまま。散らからなくなるだけです。

<br>

## コピーした画像も。

<kbd>⌃</kbd>を押しながらスクリーンショットを撮るか、「プレビュー」で画像をコピーすると、ほかのスクリーンショットと同じようにロープに吊るされます。
メニューバーで「コピーした画像を吊るす」をオンにすると、オンの間はシャツのアイコンが塗りつぶされます。
対象は画像だけです。テキストやファイルと一緒にコピーしたものや、パスワードマネージャが非公開に指定したものには手を触れません。

<br>

## 最初からプライベート。

アカウント不要。ネットワーク接続なし。解析なし。
Tendederoは完全にMac上で動作し、スクリーンショットがMacの外に出ることはありません。

<br>

## 技術仕様

| | |
|:--|:--|
| **互換性** | macOS 14 Sonoma以降、Appleシリコン搭載MacとIntel搭載Macに対応。macOS 27向けにデザイン。 |
| **サイズ** | 1.7MB |
| **言語** | 英語、スペイン語、ガリシア語、フランス語、ポルトガル語（ブラジル）、日本語、韓国語、中国語（簡体字）、トルコ語、アゼルバイジャン語 |
| **開発環境** | Swift、AppKit、SwiftUI |
| **ネットワークアクセス** | なし |
| **価格** | 無料 |
| **ライセンス** | コードはMIT。名前とアイコンは含まれません。 |

<br>

## インストール

[最新リリース](../../../../releases/latest)からディスクイメージをダウンロードして開き、Tendederoを「アプリケーション」フォルダにドラッグします。Homebrewでもインストールできます：

```sh
brew install --cask alejandrobujan/tap/tendedero
```

TendederoはDeveloper IDで署名され、Appleによる公証を受けているため、ほかのアプリと同じように開けます。

<br>

## ソースからビルド

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

Swiftツールチェーンが必要です。Xcodeは任意です。macOS 27のCommand Line Toolsを使う場合、新しいSDKにはXcodeにしか含まれないSwiftUIのマクロプラグインが必要なため、スクリプトは一緒にインストールされるmacOS 26 SDKに切り替えます。ローカルビルドはアドホック署名のため、再ビルドのたびにmacOSがデスクトップへのアクセスを改めて確認します。

<details>
<summary>アプリの中身</summary>
<br>

| ファイル | 役割 |
|:--|:--|
| `AppDelegate.swift` | メニューバー、ショートカット、ロープを降ろす・しまう動き |
| `LinePanel.swift` | 画面上端に沿った透明な帯 |
| `LineView.swift` | ロープと、各写真を吊るす位置 |
| `PeggedView.swift` | 写真1枚：ガラスのフレーム、洗濯バサミ、揺れとそよ風 |
| `GrabArea.swift` | クリック、長押し、ドラッグ＆ドロップ |
| `ScreenshotWatcher.swift` | 新しいスクリーンショットを検知 |
| `ClipboardWatcher.swift` | クリップボードにコピーされた画像を検知 |
| `Inbox.swift` | スクリーンショットの設定を引き継ぎ、元に戻す |
| `Markup.swift` | システムのマークアップエディタを開き、結果を保存 |
| `Trim.swift` | 画面収録をトリミングし、結果を保存 |
| `FullScreen.swift` | 隠れているべきときを判断 |
| `Line.swift` | 吊るされているものと、それに対してできること |

このページの画像は、アイコンも含めすべて`scripts/make-icon.swift`と`scripts/make-readme-art.swift`がコードで描いています。
`scripts/make-dmg.sh`はリリース用のディスクイメージを作成します。

翻訳は`Sources/Tendedero/Resources`にあり、言語ごとに`.lproj`フォルダが1つずつあります。
`swift scripts/check-strings.swift`で抜けがないか確認できます。

</details>

<br>

---

<sub>
1. 初回起動時、Tendederoはスクリーンショットを任せるかどうかを尋ねます。承諾すると、フローティングサムネールをオフにし、新しいスクリーンショットを専用のフォルダに保存します。この2つの設定はCmd+Shift+5の「オプション」にもあります。それまでの設定は保存され、Tendederoを終了したとき、またはメニューバーからこのオプションをオフにしたときに元に戻ります。アプリがフルスクリーン表示の間、Tendederoは自動的に隠れます。
</sub>

<br>
<br>

<p align="center">
  <img src="../images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>コードはMITライセンスです。Tendederoの名前とアイコンは対象外のため、フォークには独自の名前とアイコンが必要です。<a href="../../LICENSE">LICENSE</a>をご覧ください。</sub>
  <br>
  <sub>デザインと開発：<a href="https://alejandrobujan.com">Alejandro Buján</a></sub>
</p>
