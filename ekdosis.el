;;; ekdosis.el --- AUCTeX style for `ekdosis.sty'
;; This file is part of the `ekdosis' package

;; ekdosis -- TEI xml compliant critical editions
;; Copyright (C) 2020--2021  Robert Alessi

;; Please send error reports and suggestions for improvements to Robert
;; Alessi <alessi@robertalessi.net>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

(defvar LaTeX-ekdosis-preamble-options
  '(("parnotes" ("true" "false" "roman"))
    ("teiexport" ("true" "false" "tidy"))
    ("layout" ("float" "footins")))
  "Package options for the ekdosis package.")

(defun LaTeX-ekdosis-package-options ()
  "Prompt for package options for ekdosis package."
  (TeX-read-key-val t LaTeX-ekdosis-preamble-options))

(defun LaTeX-ekdosis-long-key-val (optional arg)
  (let ((crm-local-completion-map
	 (remove (assoc 32 crm-local-completion-map)
		 crm-local-completion-map))
	(minibuffer-local-completion-map
	 (remove (assoc 32 minibuffer-local-completion-map)
		 minibuffer-local-completion-map)))
    (TeX-argument-insert
     (TeX-read-key-val optional arg)
     optional)))

(defvar LaTeX-ekdosis-declarewitness-options
  '(("settlement")
    ("repository")
    ("msName")
    ("origDate")
    ("idno"))
  "List of local options for DeclareWitness macro.")

(defvar LaTeX-ekdosis-app-options
  '(("type"))
  "Local option for app|note macro.")

(defvar LaTeX-ekdosis-lem-options
  '(("wit")
    ("alt")
    ("pre")
    ("post")
    ("prewit")
    ("postwit")
    ("sep")
    ("nolem" ("true" "false"))
    ("nosep" ("true" "false")))
  "Local options for lem macro")

(defvar LaTeX-ekdosis-rdg-options
  '(("wit")
    ("alt")
    ("pre")
    ("post")
    ("prewit")
    ("postwit")
    ("nordg" ("true" "false")))
  "Local options for rdg macro.")

(defvar LaTeX-ekdosis-note-options
  '(("type")
    ("lem")
    ("labelb")
    ("labele")
    ("sep")
    ("pre")
    ("post"))
  "Local options for note macro.")

(defvar LaTeX-ekdosis-note-star-options
  '(("pre")
    ("post"))
  "Local options for note* macro.")

(defvar LaTeX-ekdosis-alignment-key-val-options
  '(("tcols")
    ("lcols")
    ("texts")
    ("apparatus")
    ("flush" ("true" "false"))
    ("paired" ("true" "false"))
    ("pagelineation" ("true" "false")))
  "Local options for alignment env.")

(TeX-add-style-hook
 "ekdosis"
 (lambda ()
   ;; Folding features:
   (add-to-list (make-local-variable 'LaTeX-fold-macro-spec-list)
   		'("{1}" ("app"))
   		t)
   (add-to-list (make-local-variable 'LaTeX-fold-macro-spec-list)
   		'("{7}||{6}||{5}||{4}||{3}||{2}||{1}" ("lem"))
   		t)
   (add-to-list (make-local-variable 'LaTeX-fold-macro-spec-list)
   		'("[r]" ("rdg"))
   		t)
   (add-to-list (make-local-variable 'LaTeX-fold-macro-spec-list)
   		'("[n]" ("note"))
   		t)
   (add-to-list (make-local-variable 'LaTeX-fold-macro-spec-list)
   		'("[l]" ("linelabel"))
   		t)
   ;; This package relies on lualatex, so check for it:
   (TeX-check-engine-add-engines 'luatex)
   (TeX-add-symbols
    '("DeclareWitness" "xml:id" "rendition" "description"
      [ LaTeX-ekdosis-long-key-val LaTeX-ekdosis-declarewitness-options ]
      0)
    '("app" [ TeX-arg-key-val LaTeX-ekdosis-app-options ]
      t)
    '("lem" [ LaTeX-ekdosis-long-key-val LaTeX-ekdosis-lem-options ]
      t)
    '("rdg" [ LaTeX-ekdosis-long-key-val LaTeX-ekdosis-rdg-options ]
      t)
    '("note" [ LaTeX-ekdosis-long-key-val LaTeX-ekdosis-note-options ]
      t)
    '("note*" [ LaTeX-ekdosis-long-key-val LaTeX-ekdosis-note-star-options ]
      t)
    '("SetEkdosisAlignment"
      (TeX-arg-key-val LaTeX-ekdosis-alignment-key-val-options))
    )
 (LaTeX-add-environments
  "ekdosis"
  '("alignment" LaTeX-env-args
    [ TeX-arg-key-val LaTeX-ekdosis-alignment-key-val-options ]
    ))
 )
 LaTeX-dialect)

;;; ekdosis.el ends here
