;; -*- coding: utf-8 -*-
;;
;; sa-iast.el
;;
;; Emacs Unicode input method for Sanskrit transliteration and Western
;; European characters
;;
;;

(require 'quail)

(quail-define-package "sa-iast" "Sanskrit IAST" "sa-iast" t
"Input as in the Heidlberg input solution."
nil nil nil nil nil nil nil nil nil nil t)

(quail-define-rules
("aa" ?ā)
("AA" ?Ā)
("ii" ?ī)
("II" ?Ī)
("uu" ?ū)
("UU" ?Ū)
(".r" ?ṛ)
(".rr" ?ṝ)
(".R" ?Ṛ)
(".RR" ?Ṝ)
(".l" ?ḷ)
(".L" ?Ḷ)
(".ll" ?ḹ)
(".LL" ?Ḹ)
(".m" ?ṃ)
(".M" ?Ṃ)
(".h" ?ḥ)
(".H" ?Ḥ)
("'m" ?ṁ)
("'M" ?Ṁ)
("'n" ?ṅ)
("'N" ?Ṅ)
("~n" ?ñ)
("~N" ?Ñ)
(".t" ?ṭ)
(".T" ?Ṭ)
(".d" ?ḍ)
(".D" ?Ḍ)
(".n" ?ṇ)
(".N" ?Ṇ)
("'s" ?ś)
("'S" ?Ś)
(".s" ?ṣ)
(".S" ?Ṣ)
)
