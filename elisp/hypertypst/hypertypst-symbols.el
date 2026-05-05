;;; hypertypst-symbols.el --- Backtick symbol entry -*- lexical-binding: t -*-

;; ` + char inserts a Typst symbol identifier in math mode.
;; Outside math, ` is inserted literally.  Unknown chars insert ` + char.

;;; Code:

(require 'hypertypst-context)
(require 'hypertypst-data)

(defcustom hypertypst-symbol-alist
  hypertypst-data-symbol-alist
  "Alist mapping char (after `) to Typst symbol identifier."
  :type '(alist :key-type character :value-type string)
  :group 'hypertypst)

(defun hypertypst-symbol-dispatch ()
  "Read the next character; if it maps to a symbol in math, insert it."
  (interactive)
  (if (not (hypertypst-in-math-p))
      (insert ?`)
    (let* ((ch (read-char "Symbol `"))
           (sym (alist-get ch hypertypst-symbol-alist)))
      (if sym
          (insert sym)
        (insert ?` ch)))))

(provide 'hypertypst-symbols)
;;; hypertypst-symbols.el ends here
