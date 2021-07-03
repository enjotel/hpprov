# hp-witness-extraction
Diplomatic transcription extraction routine for the Haṭhapradīpikā-editing project.

## Prerequisites
- xslt processor,
- grep, sed, uniq, sort.

## Usage
- browse [wit_texts](wit_texts/) directory for the transcriptions,
- run `x-wit-texts-all.sh` to recreate from the same input file.

## Normalisations performed
- Changed paragraph elements `<p>` to line group elements `<lg>`, added `<l>` elements and `xml:id` attributes,
- purged not yet collated witnesses from `<listWit>`,
- added collated witness "YC" to `<listWit>`,
- added `wit` attribute with value "ceteri" to `lem` elements without `wit` attribute.

## Encoding suggestions
- encode verses in custom environments with references mapped to xml:id attribute:

```latex
\usepackage{xparse}

%%% define environments and commands
\NewDocumentEnvironment{tlg}{O{}O{}}{\begin{verse}}{॥#1\hskip-4pt ॥\\ \end{verse}}
\NewDocumentCommand{\tl}{m}{#1}


%%% TEI mapping
\TeXtoTEIPat{\begin {tlg}[#1][#2]}{<lg xml:id="#1">}
\TeXtoTEIPat{\end {tlg}}{</lg>}

\TeXtoTEI{tl}{l}

```

- Create mappings for commands used in the apparatus, like `\om`:

```latex
%%% TEI mapping
\TeXtoTEIPat{\om }{}
```

- The reading with the most witnesses could be encoded with `ceteri` or a similar shorthand for better readability. This however is only unambiguous under two conditions:
1. `ceteri` can only be used once per `app`-command,
2. witnesses that omit the given verses all together must be excluded separately from the scope of `ceteri` (not applicable to the current sample?).

## Known issues
- [ekdosis](https://ctan.org/pkg/ekdosis) is still in development, it might take some time until all features can be utilized to its full potential which should replace some of the workarounds.
