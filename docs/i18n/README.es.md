<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/es/hero-dark.png">
  <img src="../images/es/hero-light.png" alt="Tendedero. Tus capturas, tendidas. Tres capturas en marcos de cristal cuelgan de una cuerda fina bajo la barra de menús de macOS.">
</picture>

<h3 align="center"><a href="https://tendedero.app/?lang=es">Pruébala desde el navegador en tendedero.app&nbsp;&rsaquo;</a></h3>

<p align="center">
  Gratis y de código abierto. Para macOS 14 o posterior.
  <br>
  <a href="../../../../releases/latest">Descargar&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#compilar-desde-el-código">Compilar desde el código&nbsp;&rsaquo;</a>
  <br><br>
  <a href="../../README.md">English</a>&nbsp;·&nbsp;Español&nbsp;·&nbsp;<a href="README.gl.md">Galego</a>&nbsp;·&nbsp;<a href="README.fr.md">Français</a>&nbsp;·&nbsp;<a href="README.pt-BR.md">Português (Brasil)</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.zh-Hans.md">简体中文</a>&nbsp;·&nbsp;<a href="README.tr.md">Türkçe</a>&nbsp;·&nbsp;<a href="README.az.md">Azərbaycanca</a>
  <br>
  <sub>Traducción del README en inglés. Si algo no coincide, manda el inglés.</sub>
</p>

---

<a id="vs-upstream"></a>

### ✨ Qué cambia respecto a la versión oficial (What is different from upstream)

> Este repositorio es un fork del proyecto oficial [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero) (en adelante, la **versión oficial**), con la v1.5.0 como base.
> La funcionalidad y el comportamiento son los mismos que en la versión oficial; los cambios se concentran en tres puntos: **memoria residente**, **nombre e identificadores** y **script de empaquetado**.

#### 1. Memoria residente (el cambio principal)

| Con la cuerda recogida | Versión oficial 1.5.0 | Plus publicado v1.5.0-plus | Plus, código actual 1.5.2-plus |
|:--|--:|--:|--:|
| Cuerda vacía | 16 MB | 16 MB | **12 MB** |
| Ocho capturas a tamaño real colgadas | 27 MB | 28 MB | **19 MB** |

Cómo se mide: mismo equipo y compilaciones release para arm64 en todos los casos; la oficial con los argumentos de su script y Plus con los del script de este proyecto. Se toma el valor `64-bit Footprint` del `footprint` del sistema, con el puntero fuera de la barra de menús y la cuerda recogida; mediana de 3 rondas × 3 lecturas por caso (oficial 16–17 / 24–28 MB, Plus publicado 16–17 / 26–30 MB, código actual 11–12 / 19 MB).

> **Aviso de versión**: a 21 de octubre de 2026, la DMG publicada en GitHub es la **v1.5.0-plus (build 6)**, que no incluye `MallocSpaceEfficient` ni la decodificación de fotos bajo demanda, así que su memoria es similar a la de la versión oficial (segunda columna de la tabla). La tercera columna es el resultado de compilar el código actual con `scripts/build-app.sh`, es decir, lo que saldrá en la próxima versión.

#### 2. Optimizaciones de memoria y CPU que no tiene la versión oficial

1. **Imágenes grandes del portapapeles, cero residentes**: la versión oficial conserva el `Data` original de la última imagen copiada; Plus solo guarda un hash y el tamaño como metadatos para descartar duplicados (`ClipboardWatcher.swift`), así que copiar una imagen en alta resolución ya no deja varios megas residentes de forma implícita.
2. **Fotos decodificadas bajo demanda**: al restaurar en el arranque, la versión oficial decodifica cada foto a miniatura y la deja residente (`restore()` de `Line.swift` llama a `makeThumbnail` foto a foto); Plus solo decodifica, al bajar la cuerda, las tarjetas que están en pantalla y las de los dos lados.
3. **Al recoger la cuerda se liberan los píxeles**: 0,3 segundos después de recogerla se vacían todas las miniaturas y se llama a `malloc_zone_pressure_relief` (`unloadThumbnails()` de `Line.swift`).
4. **El tamaño de la tarjeta sale solo de la cabecera del archivo**: se añade `thumbnailSize()`, que solo lee las propiedades de `CGImageSource`, así la tarjeta se monta sin necesidad de píxeles (`Line.swift`).
5. **La vista del panel se monta solo cuando hace falta**: `NSHostingView` se monta al bajar la cuerda y se desmonta al recogerla; el árbol de capas no queda residente (`AppDelegate.swift`).
6. **Sondeo adaptativo, menos frecuencia**: 30 → 10 FPS cuando está oculto y de nuevo 30 FPS al desplegarse (`updateMouseTimerRate()` de `AppDelegate.swift`).
7. **Caché persistente de los objetos de pantalla**: se guarda en caché la información de las pantallas para no llamar a `NSScreen.screens` en cada sondeo ni copiar el array puente cada vez.
8. **Compresión de memoria activa y respuesta a la presión del sistema**: al recoger el panel, al descartar capturas y al quedarse inactivo se llama a `malloc_zone_pressure_relief`, y se registra `DispatchSourceMemoryPressure` (`AppDelegate.swift`).
9. **Los mapas de bits en alta resolución de la animación se sueltan al momento**: la imagen grande de la animación de caída se anula en `CALayer.contents` en cuanto termina (`CaptureFlight.swift`).
10. **Argumentos de compilación**: se añaden `-Xswiftc -Osize -Xswiftc -wmo` (`scripts/build-app.sh`).

#### 3. Nombre, textos y empaquetado (no afecta a la funcionalidad)

| Elemento | Versión oficial | Tendedero Plus |
|:--|:--|:--|
| Nombre de la app | `Tendedero` | `Tendedero Plus` |
| Ejecutable | `Tendedero` | `TendederoPlus` |
| Versión | `1.5.0` (build 6) | `1.5.2-plus` (build 8) |
| Bundle ID | `app.tendedero.Tendedero` | Sin cambios, igual que a la izquierda: se instala encima de la versión oficial sin más, no aparecen dos apps y no se pierden los ajustes |
| Barra de menús | `Tendedero`, `Quit Tendedero` | tooltip y elemento de marca al principio del menú: `Tendedero Plus (v1.5.2-plus)`, `Quit Tendedero Plus`; sincronizado en los 10 idiomas |
| Panel | Ninguno | Distintivo `TENDEDERO PLUS` arriba a la derecha; el aviso de cuerda vacía lleva una cápsula `PLUS` |
| Artefactos de empaquetado | `build/Tendedero.app`, `Tendedero-<版本>.dmg` | `build/Tendedero Plus.app`, `Tendedero-Plus-<版本>.dmg`; nombre del volumen: `Tendedero Plus` |

#### 4. Lo que se mantiene igual que en la versión oficial

- La funcionalidad, los gestos, los atajos, los 10 idiomas y el diseño de privacidad (sin cuentas, sin red, sin analíticas) no cambian; esta rama no añade ni quita funciones y el menú solo gana una línea de marca.
- La licencia no cambia: el código es MIT; el nombre y el icono de `Tendedero` quedan fuera de la licencia MIT.
- Para comprobar las diferencias por tu cuenta: `git remote add upstream https://github.com/alejandrobujan/tendedero.git` y luego `git log --oneline upstream/main..HEAD` (ahora mismo, 7 commits y 33 archivos).

---

<p align="center">
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/daily?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/weekly?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
</p>

<br>

## Fuera de la vista. Siempre a mano.

Cada captura que haces queda colgada en una cuerda justo encima de la pantalla.
Lleva el puntero a la barra de menús y la cuerda baja. Apártalo y desaparece.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/es/demo-dark.gif">
  <img src="../images/es/demo-light.gif" alt="El puntero toca el borde superior, la cuerda baja con tres capturas que se balancean, un clic copia una y la cuerda se recoge cuando el puntero se aparta.">
</picture>

<br>
<br>

## Un gesto para cada cosa.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/es/bento-dark.png">
  <img src="../images/es/bento-light.png" alt="Clic para copiar. Mantén para anotar. Arrastra para compartir. Y olvídate.">
</picture>

<br>
<br>

| | |
|:--|:--|
| Clic | Copia la imagen. |
| Mantener pulsado | La abre en Marcación. |
| Doble clic | La abre en Vista Previa. |
| Clic fuerte | Le echa un vistazo con Vista Rápida. |
| Arrastrar a una app | Envía una copia, y la captura sigue colgada. |
| Arrastrar a una carpeta | Se queda ahí y sale de la cuerda. |
| Arrastrar a la Papelera o hacer clic en la cruz | Te deshaces de ella. |
| Dejar el puntero en la barra de menús | Baja la cuerda en esa pantalla. |
| Hacer clic en cualquier sitio de la barra de menús | Recoge la cuerda. |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | Muestra u oculta la cuerda. Se cambia en Atajo, en la barra de menús. |

<br>

## Tu Escritorio, por fin despejado.

Deja que Tendedero se encargue de tus capturas<sup>1</sup> y dejarán de pasar
por el Escritorio. Sin miniatura flotante ni cinco segundos de espera: cada
captura se cuelga al momento, y solo se queda lo que tú saques de la cuerda.

Las grabaciones de pantalla también se cuelgan, con un botón de play encima.
Mantén pulsada una para recortarla.

Los mismos atajos y las mismas costumbres. Pero sin desorden.

<br>

## También las imágenes que copias.

Haz una captura con <kbd>⌃</kbd> pulsado, o copia una imagen en Vista Previa,
y se cuelga como cualquier otra. Activa Colgar imágenes copiadas en la barra
de menús; mientras está activo, la camiseta se rellena. Solo imágenes: lo que
se copia junto con texto o un archivo, y lo que un gestor de contraseñas marca
como privado, se deja tal cual.

<br>

## Privacidad de serie.

Sin cuentas, sin conexión a internet, sin analíticas.
Tendedero funciona solo en tu Mac, y tus capturas nunca salen de él.

<br>

## Especificaciones técnicas

| | |
|:--|:--|
| **Compatibilidad** | macOS 14 Sonoma o posterior, en Mac con Apple silicon o Intel. Pensado para macOS 27. |
| **Tamaño** | 1,7 MB |
| **Idiomas** | Inglés, español, gallego, francés, portugués de Brasil, japonés, coreano, chino simplificado, turco y azerbaiyano |
| **Hecho con** | Swift, AppKit y SwiftUI |
| **Conexión a internet** | No la usa |
| **Precio** | Gratis |
| **Licencia** | MIT para el código. El nombre y el icono quedan fuera. |

<br>

## Instalación

Descarga la imagen de disco desde la [última versión](../../../../releases/latest),
ábrela y arrastra Tendedero a Aplicaciones. También puedes instalarlo con Homebrew:

```sh
brew install --cask alejandrobujan/tap/tendedero
```

Tendedero está firmado con un Developer ID y notarizado por Apple, así que se
abre como cualquier otra app.

<br>

## Compilar desde el código

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

Solo necesitas las herramientas de Swift; Xcode es opcional. Si usas las
Command Line Tools de macOS 27, el script tira del SDK de macOS 26 que se
instala con ellas, porque el nuevo necesita un plugin de macros de SwiftUI que
solo viene con Xcode. Las compilaciones locales se firman ad hoc, así que macOS
vuelve a pedir acceso al Escritorio cada vez que recompilas.

<details>
<summary>Por dentro</summary>
<br>

| Archivo | Qué hace |
|:--|:--|
| `AppDelegate.swift` | La barra de menús, el atajo, y bajar y recoger la cuerda |
| `LinePanel.swift` | La franja transparente del borde superior de la pantalla |
| `LineView.swift` | La cuerda y dónde cuelga cada foto |
| `PeggedView.swift` | Cada foto: marco de cristal, pinza, balanceo y brisa |
| `GrabArea.swift` | Clic, pulsación larga, y arrastrar y soltar |
| `ScreenshotWatcher.swift` | Se da cuenta de las capturas nuevas |
| `ClipboardWatcher.swift` | Se da cuenta de las imágenes copiadas |
| `Inbox.swift` | Toma el control de los ajustes de captura y luego los devuelve |
| `Markup.swift` | Abre el editor de Marcación del sistema y guarda el resultado |
| `Trim.swift` | Recorta una grabación de pantalla y guarda el resultado |
| `FullScreen.swift` | Sabe cuándo tiene que quedarse oculto |
| `Line.swift` | Qué hay colgado y qué puedes hacer con ello |

Todas las imágenes de esta página, icono incluido, se dibujan con código en
`scripts/make-icon.swift` y `scripts/make-readme-art.swift`.
`scripts/make-dmg.sh` genera la imagen de disco de cada versión.

Las traducciones están en `Sources/Tendedero/Resources`, con una carpeta
`.lproj` por idioma. `swift scripts/check-strings.swift` avisa si falta alguna.

</details>

<br>

---

<sub>
1. La primera vez que lo abres, Tendedero te ofrece encargarse de tus capturas. Si aceptas, desactiva la miniatura flotante y guarda las capturas nuevas en su propia carpeta; son dos ajustes que también encontrarás en Opciones de Cmd+Mayús+5. Tus ajustes anteriores se guardan y vuelven a su sitio al cerrar Tendedero o al desactivar la opción desde la barra de menús. Mientras una app está a pantalla completa, Tendedero se oculta solo.
</sub>

<br>
<br>

<p align="center">
  <img src="../images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>El código tiene licencia MIT, pero el nombre y el icono de Tendedero no, así que cada fork necesita los suyos. Más detalles en <a href="../../LICENSE">LICENSE</a>.</sub>
  <br>
  <sub>Diseñado y desarrollado por <a href="https://alejandrobujan.com">Alejandro Buján</a>.</sub>
</p>
