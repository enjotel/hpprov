# hp-witness-extraction
Diplomatic transcription extraction routine for the Haṭhapradīpikā-editing project.

## Prerequisites
- xslt 1.0 processor,
- grep, sed, uniq, sort, date

## Compatibility
- the `teiHeader` of the [witness transcriptions](wit_texts/) is optimized for direct upload to [saktumiva](http://saktumiva.org/)
- the [csv-database of stemmatically relevant readings](hp_1.1-20_stemmapoint-readings.csv) can be exported with the [matrix editor](https://chchch.github.io/sanskrit-alignment/matrix-editor/) to recreate the corresponding [nexus file](hp_1.1-20_stemmapoint-readings.nex), which in turn can be examined with [SplitsTree 5.3.0](https://software-ab.informatik.uni-tuebingen.de/download/splitstree5/welcome.html), cf. [splitsnetwork](stemmapoint_splitsnetwork.png)

## Usage
1. diplomatic text extraction:
- browse [wit_texts](wit_texts/) directory for the transcriptions,
- run `x-wit-texts-all.sh hp_1.1-20.xml` to recreate from the same input file.
2. readings extraction into csv-database:
- check out [hp_1.1-20_stemmapoint-readings.csv](hp_1.1-20_stemmapoint-readings.csv) for the database,
- run `x-wit-readings-csv.sh hp_1.1-20.xml` to recreate from the same input file.

## Normalisation performed on initial release (realized)
- Changed paragraph elements `<p>` to line group elements `<lg>`, added `<l>` elements and `xml:id` attributes,
- purged not yet collated witnesses from `<listWit>`,
- added collated witness "YC" to `<listWit>`,
- added `wit` attribute with value "ceteri" to `lem` elements without `wit` attribute.

## Encoding suggestions on initial release (realized)
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
- Make sure all witnesses, including -ac and -pc siglas are declared in the preamble of the .tex-file.

## Known issues
- [ekdosis](https://ctan.org/pkg/ekdosis) is still in development, it might take some time until all features can be utilized to its full potential which should replace some of the workarounds.
