# sanskrit editing suite
workflow suggestion for encoding and rendering critical editions

## Prerequisites
- up-to-date [TeX Live installation](https://tug.org/texlive/acquire-netinstall.html)
- XSLT 2.0-processor like [Saxon-HE](http://saxon.sourceforge.net/#F9.9HE)
- (optional) [tidy](http://www.html-tidy.org/), for slightly more human-readable TEI-export

## Installation
- clone this repository to your editing directory with `git clone https://github.com/radardenker/sanskrit-editing-suite`

## Preliminary considerations: text encoding and presentation
- text encoding is not to be confounded with character encoding, cf. [this site](https://scripts.sil.org/IWS-Chapter02) for a short introduction;
- text encoding is mostly done with a particular form of presentation (a printed book, web page, poster) in mind, the content is structured and differentiated according to the necessities of the processor (e.g. LaTeX commands separate content from presentational processing instructions), often inside a user interface that displays the encoded information as formatted text in a similar way to the intended result (WYSIWYG, e.g. office suites); the text encoding has to be converted if another form of presentation is desired
- textual content can also be encoded according to its function regardless of presentation, which is especially useful if:
  - various presentations should be generated from the same source file,
  - a subsequent use of the content by yourself or others is foreseeable/desirable,
  - you don't want to deal with formatting details (yet).
- general drawbacks of functional markup:
  - functional markup is usually more intrusive and less intuitive to read,
  - presentation has to be styled separately.

## Acronyms
- XML = Extensible Markup Language
- XSLT = Extensible Stylesheet Language Transformations, 
- DTD = Document Type Definition, a validation scheme type
- TEI = Text Encoding Initiative
- NLP = Natural Language Processing

## Usage
- [general workflow](charts/editing-workflow-with-ekdosis.pdf) with [ekdosis](https://ctan.org/pkg/ekdosis), [LuaLaTeX](https://de.wikipedia.org/wiki/LuaTeX) and [XSLT 2.0](https://www.w3.org/TR/xslt20/)
  - text encoding: LaTeX, cf. [this file](example.tex)
  - outputs:
    - [PDF](https://rawcdn.githack.com/radardenker/sanskrit-editing-suite/master/example.pdf) for publication by compiling three times:
      ```
      lualatex example.tex
      ``` 
    - [HTML](https://rawcdn.githack.com/radardenker/sanskrit-editing-suite/master/html/example-tei.htm) for web rendering by applying the appropriate stylesheet to the xml file:
      ```
      saxon-xslt -s:example-tei.xml -xsl:xslt2-stylesheets/html.xsl -o:html/example-tei.htm
      ```
    - [plain text](example-tei.txt) for string search, text mining and NLP by applying the appropriate stylesheet to the xml file:
      ```
      saxon-xslt -s:example-tei.xml -xsl:xslt2-stylesheets/plain-text.xsl -o:example-tei.txt
      ```
- for selective html and plain text outputs custom stylesheets can be created, cf. [this repo](https://github.com/radardenker/xml-crashcourse) for a short introduction

## Known issues
- [ekdosis](https://ctan.org/pkg/ekdosis) is still in development, it might take some months until all features can be utilized to its full potential which should replace some of the workarounds used in the [example](example.tex).
