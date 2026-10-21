<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/tr/hero-dark.png">
  <img src="../images/tr/hero-light.png" alt="Tendedero. Ekran görüntüleri, ipin üzerinde. macOS menü çubuğunun altında ince bir ipten sallanan cam çerçeveli üç ekran görüntüsü.">
</picture>

<h3 align="center"><a href="https://tendedero.app">tendedero.app adresinde tarayıcıdan deneyin&nbsp;&rsaquo;</a></h3>

<p align="center">
  Ücretsiz ve açık kaynak. macOS 14 ve sonrası için.
  <br>
  <a href="../../../../releases/latest">İndir&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#kaynaktan-derle">Kaynaktan derle&nbsp;&rsaquo;</a>
  <br><br>
  <a href="../../README.md">English</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.gl.md">Galego</a>&nbsp;·&nbsp;<a href="README.fr.md">Français</a>&nbsp;·&nbsp;<a href="README.pt-BR.md">Português (Brasil)</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.zh-Hans.md">简体中文</a>&nbsp;·&nbsp;Türkçe&nbsp;·&nbsp;<a href="README.az.md">Azərbaycanca</a>
  <br>
  <sub>Bu dosya İngilizce README'nin çevirisidir. Bir tutarsızlık varsa İngilizce sürümü esas alın.</sub>
</p>

---

<a id="vs-upstream"></a>

### ✨ Resmi sürüme göre iyileştirmeler (What is different from upstream)

> Bu depo, resmi [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero) deposunun (bundan sonra **resmi sürüm**) bir fork'udur; temel aldığı sürüm resmi v1.5.0'dır.
> İşlevler ve etkileşim resmi sürümle aynıdır; eklenen tek hareket: **işaretçiyi fotoğrafın üzerinde tutup Boşluk** ile önizleme. Kalan değişiklikler üç noktada toplanır: **kalıcı bellek kullanımı**, **adlandırma**, **paketleme betiği**.

#### 1. Kalıcı bellek kullanımı (ana değişiklik)

| İp kapalıyken kararlı durum | Resmi sürüm 1.5.0 | Tendedero Plus v1.5.2-plus |
|:--|--:|--:|
| Boş ip | 16 MB | **12 MB** |
| 8 tam boy ekran görüntüsü asılıyken | 27 MB | **19 MB** |

Ölçüm yöntemi: aynı makine, tümü arm64 release derlemesi; resmi sürüm kendi betik parametreleriyle, Plus bu projenin betik parametreleriyle derlendi. Sistemin `footprint` çıktısındaki `64-bit Footprint` değeri esas alındı; işaretçi menü çubuğundan ayrılmış, ip toplu ve kararlı durumda. Her düzey için 3 tur × 3 okumanın medyanı alındı (resmi sürüm 16–17 / 24–28 MB, güncel kaynak 11–12 / 19 MB).

> **Sürüm notu**: GitHub'da yayımlanan DMG **v1.5.2-plus (build 8)** sürümüdür; bu sayfadaki değerler bu sürüme aittir. Önceki v1.5.0-plus (build 6) `MallocSpaceEfficient` ve fotoğrafları isteğe bağlı çözme özelliğini içermiyordu, belleği resmi sürümle aynı düzeydeydi.

#### 2. Resmi sürümde bulunmayan bellek ve CPU iyileştirmeleri

1. **Panodaki büyük görseller bellekte tutulmaz**: Resmi sürüm, en son kopyalanan görselin ham `Data` değerini saklar; Plus yinelenen görseli ayırt etmek için yalnızca Hash ve Size üst verisini tutar (`ClipboardWatcher.swift`); yüksek çözünürlüklü bir görsel kopyalamak artık megabayt mertebesinde örtük bellek tutulmasına yol açmaz.
2. **Fotoğraflar isteğe bağlı çözülür**: Resmi sürüm açılışta geri yükleme sırasında her fotoğrafı küçük resme çözüp bellekte tutar (`Line.swift` içindeki `restore()` her biri için `makeThumbnail` çağırır); Plus kartları yalnızca ip indirildiğinde, ekranda görünenler ve iki yanındakiler için çözer.
3. **İp toplanınca pikseller serbest bırakılır**: İp toplandıktan 0,3 saniye sonra tüm küçük resimler boşaltılır ve `malloc_zone_pressure_relief` çağrılır (`Line.swift` içindeki `unloadThumbnails()`).
4. **Kart boyutu yalnızca dosya başlığından okunur**: Eklenen `thumbnailSize()` yalnızca `CGImageSource` özelliklerini okur; kart piksellere gerek kalmadan oluşur (`Line.swift`).
5. **Panel görünümü isteğe bağlı bağlanır**: `NSHostingView` yalnızca ip indirilirken bağlanır, ip toplandıktan sonra kaldırılır; katman ağacı bellekte kalmaz (`AppDelegate.swift`).
6. **Uyarlanabilir yoklama hızı**: Gizli durumda 30 → 10 FPS, açık durumda yeniden 30 FPS (`AppDelegate.swift` içindeki `updateMouseTimerRate()`).
7. **Ekran nesneleri kalıcı önbellekte**: Ekran bilgileri önbelleğe alınır; her yoklamada `NSScreen.screens` çağrısının dizi köprüleme kopyasından kaçınılır.
8. **Proaktif bellek sıkıştırma ve sistem baskısına yanıt**: Panel toplandığında, ekran görüntüsü atıldığında ve boşta kalındığında `malloc_zone_pressure_relief` çağrılır; ayrıca `DispatchSourceMemoryPressure` kaydedilir (`AppDelegate.swift`).
9. **Animasyondaki yüksek çözünürlüklü bitmap hemen bırakılır**: Uçuş animasyonunda kullanılan büyük görsel bitince `CALayer.contents` hemen boşaltılır (`CaptureFlight.swift`).
10. **Derleme parametreleri**: `-Xswiftc -Osize -Xswiftc -wmo` eklendi (`scripts/build-app.sh`).

#### 3. Adlandırma, metinler ve paketleme (işlevleri etkilemez)

| Öğe | Resmi sürüm | Tendedero Plus |
|:--|:--|:--|
| Uygulama adı | `Tendedero` | `Tendedero Plus` |
| Yürütülebilir dosya | `Tendedero` | `TendederoPlus` |
| Sürüm numarası | `1.5.0` (build 6) | `1.5.2-plus` (build 8) |
| Bundle ID | `app.tendedero.Tendedero` | Değişmedi, soldakiyle aynı: resmi sürümün üzerine doğrudan kurulabilir, iki ayrı uygulama oluşmaz, ayarlar korunur |
| Menü çubuğu | `Tendedero`, `Quit Tendedero` | İpucu ve menünün üst kısmındaki marka öğesi `Tendedero Plus (v1.5.2-plus)`, `Quit Tendedero Plus`; 10 dilde aynı |
| Panel | Yok | Sağ üstte `TENDEDERO PLUS` rozeti; boş ip ipucunda `PLUS` kapsülü |
| Paket çıktıları | `build/Tendedero.app`, `Tendedero-<版本>.dmg` | `build/Tendedero Plus.app`, `Tendedero-Plus-<版本>.dmg`; birim adı `Tendedero Plus` |

#### 4. Resmi sürümle aynı kalanlar

- Kısayollar, 10 dil ve gizlilik tasarımı (hesap yok, ağ erişimi yok, analitik yok) değişmedi; eklenen tek hareket **işaretçiyi fotoğrafın üzerinde tutup Boşluk** ile önizlemedir, geri kalanı resmi sürümle aynıdır ve menüye yalnızca bir marka satırı eklenir.
- Lisans değişmedi: kod MIT; `Tendedero` adı ve simgesi MIT lisansına dahil değildir.
- Farkları kendiniz doğrulayın: `git remote add upstream https://github.com/alejandrobujan/tendedero.git` komutunu çalıştırın, ardından `git log --oneline upstream/main..HEAD` (şu anda 11 commit, 42 dosya).

---

<p align="center">
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/daily?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/weekly?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
</p>

<br>

## Gözden uzak. Her an erişilebilir.

Aldığınız her ekran görüntüsü, ekranınızın hemen üstündeki bir ipe asılır.
İşaretçiyi menü çubuğuna götürün, ip aşağı süzülür. Uzaklaşın, kaybolur.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/tr/demo-dark.gif">
  <img src="../images/tr/demo-light.gif" alt="İşaretçi üst kenara değiyor, ip üç ekran görüntüsüyle sallanarak aşağı iniyor, bir tıklamayla biri kopyalanıyor ve işaretçi ayrılınca ip geri çekiliyor.">
</picture>

<br>
<br>

## Her şey için bir hareket.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/tr/bento-dark.png">
  <img src="../images/tr/bento-light.png" alt="Tıkla ve kopyala. Basılı tut ve işaretle. Sürükle ve paylaş. Bırak gitsin.">
</picture>

<br>
<br>

| | |
|:--|:--|
| Tıkla | Görüntüyü kopyalar. |
| Basılı tut | İşaretle'de açar. |
| Çift tıkla | Önizleme'de açar. |
| Kuvvetli tıkla | Hızlı Bakış ile önizler. |
| İşaretçiyi fotoğrafın üzerinde tutup <kbd>Boşluk</kbd> tuşuna bas | O fotoğrafı Hızlı Bakış ile büyütür. |
| Uygulamaya sürükle | Bir kopya gönderir. İpte kalmaya devam eder. |
| Klasöre sürükle | Orada saklar. İpten ayrılır. |
| Çöp Kutusu'na sürükle ya da çarpıya tıkla | Siler. |
| İşaretçiyi menü çubuğunda bırak | O ekranda ipi aşağı indirir. |
| Menü çubuğunda herhangi bir yere tıkla | İpi geri kaldırır. |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | İpi gösterir ya da gizler. Menü çubuğundaki Kısayol bölümünden değiştirilebilir. |

<br>

## Masaüstünüz. Sonunda temiz.

Ekran görüntülerinizi Tendedero'ya bırakın<sup>1</sup>; Masaüstünü hiç görmeden geçsinler.
Kayan küçük resim yok. Beş saniyelik bekleme yok. Her görüntü çekildiği an ipe asılır;
yalnızca sürükleyip çıkardıklarınız saklanır.

Ekran kayıtları da üzerlerinde bir oynatma düğmesiyle ipe asılır.
Kırpmak için bir tanesine basılı tutun.

Aynı kısayollar. Aynı kas belleği. Sadece daha az dağınıklık.

<br>

## Kopyalanan görseller de dahil.

<kbd>⌃</kbd> tuşunu basılı tutarak ekran görüntüsü alın ya da Önizleme'de bir görsel kopyalayın;
herhangi bir görüntü gibi ipe asılır. Menü çubuğundan Kopyalanan görselleri as seçeneğini açın;
bu açıkken simgedeki gömlek dolar. Yalnızca görseller: metin veya bir dosyayla birlikte kopyalanan
içerik ve bir şifre yöneticisinin özel olarak işaretlediği her şey olduğu gibi bırakılır.

<br>

## Tasarımdan gelen gizlilik.

Hesap yok. Ağ erişimi yok. Analitik yok.
Tendedero tamamen Mac'inizde çalışır ve ekran görüntüleriniz hiçbir zaman oradan ayrılmaz.

<br>

## Teknik Özellikler

| | |
|:--|:--|
| **Uyumluluk** | macOS 14 Sonoma veya sonrası, Apple silicon ve Intel. macOS 27 için tasarlandı. |
| **Boyut** | 1,7 MB |
| **Diller** | İngilizce, İspanyolca, Galiçyaca, Fransızca, Portekizce (Brezilya), Japonca, Korece, Basitleştirilmiş Çince, Türkçe, Azerice |
| **Yapıldığı teknolojiler** | Swift, AppKit ve SwiftUI |
| **Ağ erişimi** | Yok |
| **Fiyat** | Ücretsiz |
| **Lisans** | Kod için MIT. Ad ve simge dahil değil. |

<br>

## Kur

[Son sürümden](../../../../releases/latest) disk imajını indirin, açın ve Tendedero'yu
Uygulamalar'a sürükleyin. Ya da Homebrew ile yükleyin:

```sh
brew install --cask alejandrobujan/tap/tendedero
```

Tendedero, Developer ID ile imzalı ve Apple tarafından onaylıdır; diğer uygulamalar gibi açılır.

<br>

## Kaynaktan derle

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

Swift araç zinciri gereklidir; Xcode isteğe bağlıdır. macOS 27 Komut Satırı Araçları ile script,
yanlarında yüklenen macOS 26 SDK'ya geri döner; çünkü yeni SDK, yalnızca Xcode'un sunduğu bir
SwiftUI makro eklentisi gerektirir. Yerel derlemeler ad-hoc imzalanır, bu yüzden her yeniden
derlemeden sonra macOS Masaüstü erişimi için tekrar izin ister.

<details>
<summary>Uygulamanın içinde</summary>
<br>

| Dosya | Görevi |
|:--|:--|
| `AppDelegate.swift` | Menü çubuğu, kısayol, ipi indirme ve kaldırma |
| `LinePanel.swift` | Ekranın üst kenarındaki şeffaf şerit |
| `LineView.swift` | İp ve her fotoğrafın asıldığı yer |
| `PeggedView.swift` | Bir fotoğraf: cam çerçeve, mandal, sallantı ve esinti |
| `GrabArea.swift` | Tıklama, uzun basış, sürükle ve bırak |
| `ScreenshotWatcher.swift` | Yeni ekran görüntülerini fark eder |
| `ClipboardWatcher.swift` | Panoya kopyalanan görselleri fark eder |
| `Inbox.swift` | Ekran görüntüsü ayarlarını devralır ve geri verir |
| `Markup.swift` | Sistem İşaretle düzenleyicisini açar ve sonucu kaydeder |
| `Trim.swift` | Ekran kaydını kırpar ve sonucu kaydeder |
| `FullScreen.swift` | Ne zaman gizli kalınacağını bilir |
| `Line.swift` | Asılı olanlar ve bunlarla neler yapılabileceği |

Buradaki her görsel, simge dahil, `scripts/make-icon.swift` ve
`scripts/make-readme-art.swift` tarafından kod ile çizilir.
`scripts/make-dmg.sh` sürümler için disk imajı oluşturur.

Çeviriler `Sources/Tendedero/Resources` altında, her dil için bir `.lproj` klasöründe yer alır.
`swift scripts/check-strings.swift` eksik çevirileri kontrol eder.

</details>

<br>

---

<sub>
1. İlk açılışta Tendedero, ekran görüntülerinizi yönetmek isteyip istemediğinizi sorar. Kabul ederseniz kayan küçük resmi kapatır ve yeni görüntüleri kendi klasörüne kaydeder; bunlar Cmd+Shift+5 Seçenekler menüsünde de bulunan iki ayardır. Önceki ayarlarınız kaydedilir ve Tendedero kapandığında ya da seçenek menü çubuğundan kapatıldığında geri yüklenir. Bir uygulama tam ekranda çalışırken Tendedero otomatik olarak gizlenir.
</sub>

<br>
<br>

<p align="center">
  <img src="../images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>Kod MIT lisansı ile sunulmaktadır. Tendedero adı ve simgesi lisansa dahil değildir; bu nedenle fork'ların kendi adına ve simgesine ihtiyacı vardır. Ayrıntılar için <a href="../../LICENSE">LICENSE</a>'a bakın.</sub>
  <br>
  <sub><a href="https://alejandrobujan.com">Alejandro Buján</a> tarafından tasarlanıp geliştirilmiştir.</sub>
</p>
