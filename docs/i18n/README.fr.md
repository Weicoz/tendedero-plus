<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/fr/hero-dark.png">
  <img src="../images/fr/hero-light.png" alt="Tendedero. Vos captures, mises à sécher. Trois captures dans des cadres en verre pendent à une fine corde sous la barre des menus de macOS.">
</picture>

<h3 align="center"><a href="https://tendedero.app/?lang=fr">Essayez-le dans votre navigateur sur tendedero.app&nbsp;&rsaquo;</a></h3>

<p align="center">
  Gratuit et open source. Pour macOS 14 et versions ultérieures.
  <br>
  <a href="../../../../releases/latest">Télécharger&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#compiler-depuis-le-code-source">Compiler depuis le code source&nbsp;&rsaquo;</a>
  <br><br>
  <a href="../../README.md">English</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.gl.md">Galego</a>&nbsp;·&nbsp;Français&nbsp;·&nbsp;<a href="README.pt-BR.md">Português (Brasil)</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.zh-Hans.md">简体中文</a>&nbsp;·&nbsp;<a href="README.tr.md">Türkçe</a>&nbsp;·&nbsp;<a href="README.az.md">Azərbaycanca</a>
  <br>
  <sub>Traduction du README anglais. En cas de différence, l’anglais fait foi.</sub>
</p>

---

<a id="vs-upstream"></a>

### ✨ Optimisations par rapport à l’original officiel (What is different from upstream)

> Ce dépôt est un fork de l’original officiel [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero) (ci-après **l’original officiel**), sur la base de la version officielle v1.5.0.
> Fonctionnalités et interactions identiques à celles de l’officiel ; les changements portent sur trois points : **mémoire résidente**, **nommage**, **script d’empaquetage**.

#### 1. Mémoire résidente (le changement principal)

| Corde rangée, régime stable | Original officiel 1.5.0 | Plus publié v1.5.0-plus | Plus, source actuelle 1.5.2-plus |
|:--|--:|--:|--:|
| Corde vide | 16 MB | 16 MB | **12 MB** |
| 8 captures en taille réelle accrochées | 27 MB | 28 MB | **19 MB** |

Protocole de mesure : même machine, builds arm64 release dans les deux cas ; l’officiel avec les paramètres de son script, Plus avec ceux du script de ce projet. On relève la valeur `64-bit Footprint` de l’outil système `footprint`, pointeur hors de la barre des menus, corde rangée et régime stable ; médiane de 3 séries × 3 relevés par palier (officiel 16–17 / 24–28 MB, Plus publié 16–17 / 26–30 MB, source actuelle 11–12 / 19 MB).

> **Note de version** : au 2026-10-21, le DMG publié sur GitHub est **v1.5.0-plus (build 6)** ; il n’inclut ni `MallocSpaceEfficient` ni le décodage des photos à la demande, sa mémoire est donc du même ordre que celle de l’original officiel (2e colonne du tableau ci-dessus). La 3e colonne donne le résultat de la compilation de la source actuelle par `scripts/build-app.sh`, c’est-à-dire le contenu de la prochaine version.

#### 2. Optimisations mémoire et CPU absentes de l’original officiel

1. **Aucune image de presse-papiers volumineuse en mémoire** : l’officiel conserve les `Data` brutes de la dernière image copiée ; Plus ne garde qu’un hachage et une taille comme métadonnées de déduplication (`ClipboardWatcher.swift`), et copier une image haute définition n’entraîne plus plusieurs mégaoctets de résidence implicite.
2. **Décodage des photos à la demande** : l’officiel décode chaque photo en vignette au moment de la restauration au lancement et la garde en mémoire (`restore()` dans `Line.swift`, un `makeThumbnail` par photo) ; Plus ne décode, quand la corde descend, que les cartes visibles à l’écran et leurs voisines immédiates.
3. **Pixels libérés dès que la corde est rangée** : 0,3 s après le rangement, toutes les vignettes sont vidées et `malloc_zone_pressure_relief` est appelé (`unloadThumbnails()` dans `Line.swift`).
4. **Taille des cartes lue dans l’en-tête du fichier** : une nouvelle fonction `thumbnailSize()` ne lit que les propriétés de `CGImageSource`, ce qui suffit à mettre les cartes en place sans charger un seul pixel (`Line.swift`).
5. **Vue du panneau montée à la demande** : la `NSHostingView` n’est montée que lorsque la corde descend et démontée une fois qu’elle est rangée ; l’arbre de calques ne reste pas en mémoire (`AppDelegate.swift`).
6. **Fréquence de scrutation adaptative** : 30 → 10 FPS à l’état masqué, retour à 30 FPS une fois déployé (`updateMouseTimerRate()` dans `AppDelegate.swift`).
7. **Cache persistant des écrans** : les informations d’écran sont mises en cache, ce qui évite la copie de tableau provoquée par `NSScreen.screens` à chaque scrutation.
8. **Resserrement mémoire actif et réaction à la pression système** : `malloc_zone_pressure_relief` est appelé quand le panneau se range, quand une capture est abandonnée et au repos, et une source `DispatchSourceMemoryPressure` est enregistrée (`AppDelegate.swift`).
9. **Bitmaps haute définition de l’animation détachés aussitôt** : la propriété `CALayer.contents` est vidée dès la fin de l’animation de chute qui utilisait la grande image (`CaptureFlight.swift`).
10. **Paramètres de compilation** : ajout de `-Xswiftc -Osize -Xswiftc -wmo` (`scripts/build-app.sh`).

#### 3. Nommage, libellés et empaquetage (sans effet sur les fonctionnalités)

| Élément | Original officiel | Tendedero Plus |
|:--|:--|:--|
| Nom de l’app | `Tendedero` | `Tendedero Plus` |
| Exécutable | `Tendedero` | `TendederoPlus` |
| Version | `1.5.0` (build 6) | `1.5.2-plus` (build 8) |
| Bundle ID | `app.tendedero.Tendedero` | Inchangé, identique : on installe directement par-dessus la version officielle, sans seconde app et sans perdre ses réglages |
| Barre des menus | `Tendedero`, `Quit Tendedero` | Infobulle et entrée de marque en tête de menu `Tendedero Plus (v1.5.2-plus)`, `Quit Tendedero Plus`, synchronisées dans les 10 langues |
| Panneau | Aucun | Badge `TENDEDERO PLUS` en haut à droite ; l’invite de corde vide porte une pastille `PLUS` |
| Artefacts | `build/Tendedero.app`, `Tendedero-<版本>.dmg` | `build/Tendedero Plus.app`, `Tendedero-Plus-<版本>.dmg`, volume `Tendedero Plus` |

#### 4. Alignement avec l’original officiel

- Fonctionnalités, gestes, raccourcis, 10 langues et conception de la confidentialité (pas de compte, pas de réseau, pas de statistiques) inchangés ; cette branche n’ajoute ni ne retire de fonctionnalité, le menu ne compte qu’une entrée de marque en plus.
- Licence inchangée : le code est sous MIT ; le nom et l’icône `Tendedero` n’en font pas partie.
- Pour vérifier les différences vous-même : `git remote add upstream https://github.com/alejandrobujan/tendedero.git`, puis `git log --oneline upstream/main..HEAD` (7 commits et 33 fichiers à ce jour).

---

<p align="center">
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/daily?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/weekly?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
</p>

<br>

## Hors de vue. À portée de main.

Chaque capture d’écran que vous prenez s’accroche à une corde juste au-dessus de l’écran.
Posez le pointeur dans la barre des menus et la corde descend. Éloignez-le et elle disparaît.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/fr/demo-dark.gif">
  <img src="../images/fr/demo-light.gif" alt="Le pointeur touche le bord supérieur, la corde descend avec trois captures qui se balancent, un clic en copie une, et la corde remonte quand le pointeur s’éloigne.">
</picture>

<br>
<br>

## Un geste pour chaque chose.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/fr/bento-dark.png">
  <img src="../images/fr/bento-light.png" alt="Cliquez pour copier. Maintenez pour annoter. Glissez pour partager. Laissez filer.">
</picture>

<br>
<br>

| | |
|:--|:--|
| Clic | Copie l’image. |
| Clic maintenu | L’ouvre dans Annotation. |
| Double-clic | L’ouvre dans Aperçu. |
| Clic forcé | Un Coup d’œil rapide. |
| Glisser dans une app | Envoie une copie. Elle reste sur la corde. |
| Glisser dans un dossier | Elle y reste. Elle quitte la corde. |
| Glisser dans la corbeille, ou cliquer sur la croix | Laissez-la filer. |
| Poser le pointeur dans la barre des menus | Fait descendre la corde sur cet écran. |
| Cliquer n’importe où dans la barre des menus | La range. |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | Affiche ou masque la corde. Modifiable dans Raccourci, dans la barre des menus. |

<br>

## Votre bureau, enfin dégagé.

Confiez vos captures à Tendedero<sup>1</sup> et elles ne passent plus par le
bureau. Pas de vignette flottante. Pas cinq secondes d’attente. Chaque capture
s’accroche à l’instant où vous la prenez, et seul ce que vous en sortez est gardé.

Les enregistrements d’écran s’accrochent aussi, avec un bouton de lecture
par-dessus. Maintenez le clic sur l’un d’eux pour le raccourcir.

Les mêmes raccourcis. Les mêmes réflexes. Juste moins de désordre.

<br>

## Les images copiées aussi.

Prenez une capture en maintenant <kbd>⌃</kbd>, ou copiez une image dans Aperçu,
et elle s’accroche à la corde comme les autres. Activez Accrocher les images
copiées dans la barre des menus ; le t-shirt se remplit tant que l’option est
active. Uniquement des images : ce qui est copié avec du texte ou un fichier, et
ce qu’un gestionnaire de mots de passe marque comme privé, est laissé de côté.

<br>

## Privé par nature.

Pas de compte. Pas de réseau. Pas de statistiques.
Tendedero fonctionne entièrement sur votre Mac, et vos captures ne le quittent jamais.

<br>

## Caractéristiques techniques

| | |
|:--|:--|
| **Compatibilité** | macOS 14 Sonoma ou version ultérieure, sur Mac Apple silicon et Intel. Conçu pour macOS 27. |
| **Taille** | 1,7 Mo |
| **Langues** | Anglais, espagnol, galicien, français, portugais du Brésil, japonais, coréen, chinois simplifié, turc et azerbaïdjanais |
| **Conçu avec** | Swift, AppKit et SwiftUI |
| **Accès au réseau** | Aucun |
| **Prix** | Gratuit |
| **Licence** | MIT pour le code. Le nom et l’icône ne sont pas inclus. |

<br>

## Installation

Téléchargez l’image disque depuis la [dernière version](../../../../releases/latest),
ouvrez-la et glissez Tendedero dans Applications. Ou installez-le avec Homebrew :

```sh
brew install --cask alejandrobujan/tap/tendedero
```

Tendedero est signé avec un Developer ID et notarié par Apple : il s’ouvre
comme n’importe quelle autre app.

<br>

## Compiler depuis le code source

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

Il suffit des outils Swift ; Xcode est facultatif. Avec les Command Line Tools
de macOS 27, le script se rabat sur le SDK de macOS 26 installé avec elles, car
le nouveau SDK a besoin d’un plug-in de macros SwiftUI fourni uniquement avec
Xcode. Les compilations locales sont signées ad hoc : macOS redemande donc
l’accès au bureau après chaque recompilation.

<details>
<summary>Sous le capot</summary>
<br>

| Fichier | Rôle |
|:--|:--|
| `AppDelegate.swift` | La barre des menus, le raccourci, faire descendre et ranger la corde |
| `LinePanel.swift` | La bande transparente le long du haut de l’écran |
| `LineView.swift` | La corde et l’endroit où pend chaque photo |
| `PeggedView.swift` | Une photo : cadre en verre, pince, balancement et brise |
| `GrabArea.swift` | Clic, clic maintenu, glisser-déposer |
| `ScreenshotWatcher.swift` | Repère les nouvelles captures |
| `ClipboardWatcher.swift` | Repère les images copiées dans le presse-papiers |
| `Inbox.swift` | Prend en charge les réglages de capture et les rétablit |
| `Markup.swift` | Ouvre l’éditeur Annotation du système et enregistre le résultat |
| `Trim.swift` | Raccourcit un enregistrement d’écran et enregistre le résultat |
| `FullScreen.swift` | Sait quand rester caché |
| `Line.swift` | Ce qui est accroché, et ce que vous pouvez en faire |

Toutes les images de cette page, icône comprise, sont dessinées en code par
`scripts/make-icon.swift` et `scripts/make-readme-art.swift`.
`scripts/make-dmg.sh` crée l’image disque de chaque version.

Les traductions se trouvent dans `Sources/Tendedero/Resources`, un dossier
`.lproj` par langue. `swift scripts/check-strings.swift` vérifie qu’aucune ne manque.

</details>

<br>

---

<sub>
1. Au premier lancement, Tendedero propose de gérer vos captures d’écran. Si vous acceptez, il désactive la vignette flottante et enregistre les nouvelles captures dans son propre dossier, deux réglages que l’on trouve aussi dans Options de Cmd+Maj+5. Vos réglages précédents sont conservés et rétablis quand vous quittez Tendedero ou désactivez l’option depuis la barre des menus. Tendedero se masque automatiquement quand une app est en plein écran.
</sub>

<br>
<br>

<p align="center">
  <img src="../images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>Le code est sous licence MIT. Le nom et l’icône de Tendedero ne le sont pas : chaque fork a besoin des siens. Voir <a href="../../LICENSE">LICENSE</a>.</sub>
  <br>
  <sub>Conçu et développé par <a href="https://alejandrobujan.com">Alejandro Buján</a>.</sub>
</p>
