;;; hypertypst-data.el --- Vendored Typst symbol/modifier tables (STUB) -*- lexical-binding: t -*-

;; STUB: hand-curated minimal tables for the MVP.
;; Eventually this file will be machine-generated from the Typst symbol catalog
;; (see scripts/gen-symbols.* -- not yet written).  See the architecture doc
;; for the planned source-of-truth investigation.

;;; Code:

(defconst hypertypst-data-symbol-alist
  ;; ` + key  ->  Typst symbol/identifier (inserted verbatim in math mode).
  '((?a . "alpha")    (?A . "Alpha")
    (?b . "beta")     (?B . "Beta")
    (?g . "gamma")    (?G . "Gamma")
    (?d . "delta")    (?D . "Delta")
    (?e . "epsilon")  (?E . "Epsilon")
    (?z . "zeta")     (?Z . "Zeta")
    (?h . "eta")      (?H . "Eta")
    (?t . "theta")    (?T . "Theta")
    (?k . "kappa")    (?K . "Kappa")
    (?l . "lambda")   (?L . "Lambda")
    (?m . "mu")       (?M . "Mu")
    (?n . "nu")       (?N . "Nu")
    (?x . "xi")       (?X . "Xi")
    (?p . "pi")       (?P . "Pi")
    (?r . "rho")      (?R . "Rho")
    (?s . "sigma")    (?S . "Sigma")
    (?u . "upsilon")  (?U . "Upsilon")
    (?f . "phi")      (?F . "Phi")
    (?c . "chi")      (?C . "Chi")
    (?y . "psi")      (?Y . "Psi")
    (?o . "omega")    (?O . "Omega")
    (?i . "in")
    (?8 . "infinity")
    (?0 . "emptyset")
    (?N . "NN") (?Z . "ZZ") (?Q . "QQ") (?R . "RR") (?C . "CC"))
  "STUB symbol table; replaced by generated catalog later.")

(defconst hypertypst-data-modifier-alist
  ;; ; + key  ->  Typst function name to wrap previous node with.
  '((?b . "bar")
    (?h . "hat")
    (?v . "arrow")
    (?t . "tilde")
    (?d . "dot")
    (?D . "dot.double")
    (?B . "bold")
    (?I . "italic")
    (?c . "cal")
    (?f . "frak")
    (?s . "sans")
    (?m . "mono")
    (?u . "underline")
    (?o . "overline"))
  "STUB modifier table; replaced by generated catalog later.")

(provide 'hypertypst-data)
;;; hypertypst-data.el ends here
