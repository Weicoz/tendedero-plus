<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/pt-BR/hero-dark.png">
  <img src="../images/pt-BR/hero-light.png" alt="Tendedero. Suas capturas, secando no varal. Três capturas em molduras de vidro penduradas num varal fino sob a barra de menus do macOS.">
</picture>

<h3 align="center"><a href="https://tendedero.app/?lang=pt-BR">Experimente no navegador em tendedero.app&nbsp;&rsaquo;</a></h3>

<p align="center">
  Gratuito e de código aberto. Para macOS 14 ou posterior.
  <br>
  <a href="../../../../releases/latest">Baixar&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;
  <a href="#compilar-a-partir-do-código-fonte">Compilar a partir do código-fonte&nbsp;&rsaquo;</a>
  <br><br>
  <a href="../../README.md">English</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.gl.md">Galego</a>&nbsp;·&nbsp;<a href="README.fr.md">Français</a>&nbsp;·&nbsp;Português (Brasil)&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.zh-Hans.md">简体中文</a>&nbsp;·&nbsp;<a href="README.tr.md">Türkçe</a>&nbsp;·&nbsp;<a href="README.az.md">Azərbaycanca</a>
  <br>
  <sub>Tradução do README em inglês. Em caso de divergência, vale a versão em inglês.</sub>
</p>

---

<a id="vs-upstream"></a>

### ✨ O que muda em relação à versão oficial (What is different from upstream)

> Este repositório é um fork do [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero) oficial (a seguir, a **versão oficial**), com base na v1.5.0.
> Os recursos e a interação são os mesmos. As mudanças se concentram em três pontos: **memória residente**, **nome e identidade** e **script de empacotamento**.

#### 1. Memória residente (a mudança principal)

| Com o varal recolhido | Versão oficial 1.5.0 | Plus lançado v1.5.0-plus | Plus código atual 1.5.2-plus |
|:--|--:|--:|--:|
| Varal vazio | 16 MB | 16 MB | **12 MB** |
| Oito capturas em tamanho real | 27 MB | 28 MB | **19 MB** |

Como foi medido: mesma máquina, compilações release arm64 nas duas; a oficial com os parâmetros do script oficial, a Plus com os parâmetros do script deste projeto. Valor de `64-bit Footprint` do `footprint` do sistema, com o ponteiro fora da barra de menus e o varal recolhido; 3 rodadas × 3 leituras por caso, mediana (oficial 16–17 / 24–28 MB, Plus lançado 16–17 / 26–30 MB, código atual 11–12 / 19 MB).

> **Aviso de versão**: em 21/10/2026, o DMG publicado no GitHub é o **v1.5.0-plus (build 6)**, sem `MallocSpaceEfficient` e sem decodificação de fotos sob demanda, então a memória dele fica parecida com a da versão oficial (2ª coluna da tabela acima). A 3ª coluna é o resultado da compilação do código atual em `scripts/build-app.sh`, ou seja, o que sai na próxima versão.

#### 2. Otimizações de memória e CPU que a versão oficial não tem

1. **Imagem grande copiada, zero residência**: a oficial guarda o `Data` original da última imagem copiada; a Plus guarda só metadados de hash e tamanho para deduplicar (`ClipboardWatcher.swift`), então copiar uma imagem em alta resolução não deixa mais vários megabytes residentes sem você ver.
2. **Fotos decodificadas sob demanda**: ao restaurar na inicialização, a oficial decodifica cada foto em miniatura e a mantém residente (`restore()` de `Line.swift`, um `makeThumbnail` por foto); a Plus só decodifica, ao puxar o varal, os cartões que estão na tela e nos dois vizinhos.
3. **Recolher o varal libera os pixels**: 0,3 segundo depois de recolher, todas as miniaturas são descartadas e o app chama `malloc_zone_pressure_relief` (`unloadThumbnails()` de `Line.swift`).
4. **O tamanho do cartão vem só do cabeçalho do arquivo**: o novo `thumbnailSize()` lê apenas as propriedades do `CGImageSource`, então o cartão se forma sem os pixels (`Line.swift`).
5. **A vista do painel é montada sob demanda**: a `NSHostingView` só é montada ao puxar o varal e desmontada ao recolher; a árvore de camadas não fica residente (`AppDelegate.swift`).
6. **Polling adaptativo mais lento**: 30 → 10 FPS com o varal escondido, e volta a 30 FPS com ele aberto (`updateMouseTimerRate()` de `AppDelegate.swift`).
7. **Cache permanente dos objetos de tela**: as informações das telas ficam em cache, sem a cópia por ponte de array que `NSScreen.screens` faz a cada polling.
8. **Compactação ativa e resposta à pressão do sistema**: chama `malloc_zone_pressure_relief` ao recolher o painel, ao descartar uma captura e quando fica ocioso, e registra um `DispatchSourceMemoryPressure` (`AppDelegate.swift`).
9. **Bitmaps nítidos da animação soltos na hora**: terminada a animação de queda, a imagem grande tem o `CALayer.contents` zerado imediatamente (`CaptureFlight.swift`).
10. **Parâmetros de compilação**: `-Xswiftc -Osize -Xswiftc -wmo` acrescentados (`scripts/build-app.sh`).

#### 3. Nome, textos e empacotamento (não afetam o funcionamento)

| Item | Versão oficial | Tendedero Plus |
|:--|:--|:--|
| Nome do app | `Tendedero` | `Tendedero Plus` |
| Executável | `Tendedero` | `TendederoPlus` |
| Versão | `1.5.0` (build 6) | `1.5.2-plus` (build 8) |
| Bundle ID | `app.tendedero.Tendedero` | Sem mudança, igual à esquerda: dá para instalar por cima da versão oficial, sem dois apps e sem perder os ajustes |
| Barra de menus | `Tendedero`, `Quit Tendedero` | Tooltip e item de marca no topo do menu `Tendedero Plus (v1.5.2-plus)`, `Quit Tendedero Plus`, nos 10 idiomas |
| Painel | Nenhum | Selo `TENDEDERO PLUS` no canto superior direito; a dica do varal vazio traz uma cápsula `PLUS` |
| Artefatos | `build/Tendedero.app`, `Tendedero-<版本>.dmg` | `build/Tendedero Plus.app`, `Tendedero-Plus-<版本>.dmg`, volume `Tendedero Plus` |

#### 4. Em sintonia com a versão oficial

- Recursos, gestos, atalhos, os 10 idiomas e a privacidade (sem conta, sem rede, sem estatísticas) continuam iguais; este fork não acrescenta nem remove recursos, o menu só ganha uma linha de marca.
- A licença não muda: código MIT; o nome e o ícone do `Tendedero` não entram no MIT.
- Para conferir as diferenças você mesmo: `git remote add upstream https://github.com/alejandrobujan/tendedero.git` e depois `git log --oneline upstream/main..HEAD` (hoje 7 commits e 33 arquivos).

---

<p align="center">
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/daily?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
  <a href="https://trendshift.io/repositories/287033?utm_source=trendshift-badge&amp;utm_medium=badge&amp;utm_campaign=badge-trendshift-287033" target="_blank" rel="noopener noreferrer"><img src="https://trendshift.io/api/badge/trendshift/repositories/287033/weekly?language=Swift" alt="alejandrobujan%2Ftendedero | Trendshift" width="250" height="55"/></a>
</p>

<br>

## Longe da vista. Ao alcance da mão.

Cada captura de tela que você faz fica pendurada num varal logo acima da tela.
Pare o ponteiro na barra de menus e o varal desce. Afaste-o e ele some.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/pt-BR/demo-dark.gif">
  <img src="../images/pt-BR/demo-light.gif" alt="O ponteiro encosta na borda superior, o varal desce com três capturas balançando de leve, um clique copia uma delas, e o varal se recolhe quando o ponteiro se afasta.">
</picture>

<br>
<br>

## Um gesto para cada coisa.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../images/pt-BR/bento-dark.png">
  <img src="../images/pt-BR/bento-light.png" alt="Clique para copiar. Segure para marcar. Arraste para compartilhar. Desapegue.">
</picture>

<br>
<br>

| | |
|:--|:--|
| Clicar | Copia a imagem. |
| Clicar e segurar | Abre na Marcação. |
| Clicar duas vezes | Abre no Pré-Visualização. |
| Clique forte | Abre na Visualização Rápida. |
| Arrastar para um app | Envia uma cópia. Ela continua no varal. |
| Arrastar para uma pasta | Guarda a imagem ali. Ela sai do varal. |
| Arrastar para o Lixo, ou clicar no X | Desapegue. |
| Parar o ponteiro na barra de menus | Baixa o varal naquela tela. |
| Clicar em qualquer lugar da barra de menus | Recolhe o varal. |
| <kbd>⌃</kbd>&thinsp;<kbd>⌥</kbd>&thinsp;<kbd>T</kbd> | Mostra ou oculta o varal. Altere em Atalho, na barra de menus. |

<br>

## Sua Mesa. Finalmente limpa.

Deixe o Tendedero cuidar das suas capturas<sup>1</sup> e elas nem passam pela
Mesa. Sem miniatura flutuante. Sem esperar cinco segundos. Cada captura vai
para o varal no instante em que você a faz, e só fica o que você arrastar para fora.

As gravações de tela também vão para o varal, com um botão de reprodução por cima.
Clique e segure numa delas para cortá-la.

Os mesmos atalhos. A mesma memória muscular. Só menos bagunça.

<br>

## Imagens copiadas também.

Faça uma captura segurando <kbd>⌃</kbd>, ou copie uma imagem no Pré-Visualização,
e ela vai para o varal como qualquer outra. Ative Pendurar imagens copiadas na
barra de menus; a camiseta fica preenchida enquanto a opção estiver ativa. Só
imagens: o que for copiado junto com texto ou um arquivo, e o que um gerenciador
de senhas marcar como privado, fica de fora.

<br>

## Privado por princípio.

Sem conta. Sem rede. Sem estatísticas.
O Tendedero roda inteiramente no seu Mac, e suas capturas nunca saem dele.

<br>

## Especificações técnicas

| | |
|:--|:--|
| **Compatibilidade** | macOS 14 Sonoma ou posterior, em Macs com Apple silicon e Intel. Projetado para o macOS 27. |
| **Tamanho** | 1,7 MB |
| **Idiomas** | Inglês, espanhol, galego, francês, português (Brasil), japonês, coreano, chinês simplificado, turco e azerbaijano |
| **Feito com** | Swift, AppKit e SwiftUI |
| **Acesso à rede** | Nenhum |
| **Preço** | Gratuito |
| **Licença** | MIT para o código. O nome e o ícone não estão incluídos. |

<br>

## Instalação

Baixe a imagem de disco da [versão mais recente](../../../../releases/latest),
abra-a e arraste o Tendedero para Aplicativos. Ou instale com o Homebrew:

```sh
brew install --cask alejandrobujan/tap/tendedero
```

O Tendedero é assinado com um Developer ID e notarizado pela Apple, então abre
como qualquer outro app.

<br>

## Compilar a partir do código-fonte

```sh
git clone https://github.com/Weicoz/tendedero-plus.git
cd tendedero-plus
scripts/build-app.sh
open "build/Tendedero Plus.app"
```

Basta ter as ferramentas do Swift; o Xcode é opcional. Com as Command Line Tools
do macOS 27, o script recorre ao SDK do macOS 26 que elas instalam junto, porque
o novo SDK precisa de um plug-in de macros do SwiftUI que só vem com o Xcode. As
compilações locais são assinadas ad hoc, então o macOS volta a pedir acesso à
Mesa a cada nova compilação.

<details>
<summary>Por dentro do app</summary>
<br>

| Arquivo | Função |
|:--|:--|
| `AppDelegate.swift` | Barra de menus, atalho, baixar e recolher o varal |
| `LinePanel.swift` | A faixa transparente ao longo do topo da tela |
| `LineView.swift` | O varal e onde cada foto fica pendurada |
| `PeggedView.swift` | Uma foto: moldura de vidro, prendedor, balanço e brisa |
| `GrabArea.swift` | Clique, clique longo, arrastar e soltar |
| `ScreenshotWatcher.swift` | Percebe novas capturas |
| `ClipboardWatcher.swift` | Percebe imagens copiadas para a área de transferência |
| `Inbox.swift` | Assume os ajustes de captura e depois os restaura |
| `Markup.swift` | Abre o editor de Marcação do sistema e salva o resultado |
| `Trim.swift` | Corta uma gravação de tela e salva o resultado |
| `FullScreen.swift` | Sabe quando ficar escondido |
| `Line.swift` | O que está pendurado, e o que você pode fazer com isso |

Todas as imagens desta página, incluindo o ícone, são desenhadas em código por
`scripts/make-icon.swift` e `scripts/make-readme-art.swift`.
`scripts/make-dmg.sh` cria a imagem de disco de cada versão.

As traduções ficam em `Sources/Tendedero/Resources`, uma pasta `.lproj` por
idioma. `swift scripts/check-strings.swift` verifica se não falta nenhuma.

</details>

<br>

---

<sub>
1. Na primeira vez que é aberto, o Tendedero se oferece para cuidar das suas capturas de tela. Se você aceitar, ele desativa a miniatura flutuante e salva as novas capturas na sua própria pasta, dois ajustes que também ficam em Opções no Cmd+Shift+5. Seus ajustes anteriores são guardados e restaurados quando o Tendedero é encerrado ou quando a opção é desativada na barra de menus. O Tendedero se oculta automaticamente quando um app está em tela cheia.
</sub>

<br>
<br>

<p align="center">
  <img src="../images/icon.png" width="64" height="64" alt="">
  <br>
  <sub>O código tem licença MIT. O nome e o ícone do Tendedero não, então cada fork precisa dos seus. Veja a <a href="../../LICENSE">LICENSE</a>.</sub>
  <br>
  <sub>Projetado e desenvolvido por <a href="https://alejandrobujan.com">Alejandro Buján</a>.</sub>
</p>
