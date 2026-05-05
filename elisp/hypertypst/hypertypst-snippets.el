;;; hypertypst-snippets.el --- Word-trigger templates -*- lexical-binding: t -*-

;; A snippet is just a string that we insert at point.  After insertion,
;; the parser re-parses and the navigator finds the new stops via
;; `hypertypst-next-stop'.  No marker tracking, no engine.

;;; Code:

(require 'hypertypst-context)
(require 'hypertypst-nav)

(defcustom hypertypst-snippet-alist
  '(("fr"  . "frac(, )")
    ("sq"  . "sqrt()")
    ("rt"  . "root(, )")
    ("sm"  . "sum_()^()")
    ("pr"  . "product_()^()")
    ("in"  . "integral_()^()")
    ("lm"  . "lim_()")
    ("mt"  . "mat(, ; , )")
    ("vc"  . "vec(, )")
    ("cs"  . "cases(, )")
    ("bn"  . "binom(, )")
    ("ab"  . "abs()")
    ("nm"  . "norm()"))
  "Alist mapping trigger words to template strings.
Triggered by typing the word and pressing TAB while in math context."
  :type '(alist :key-type string :value-type string)
  :group 'hypertypst)

(defun hypertypst--word-before-point ()
  "Return (BEG END WORD) for the alpha word ending at point, or nil."
  (save-excursion
    (let ((end (point)))
      (skip-chars-backward "a-zA-Z")
      (let ((beg (point)))
        (when (< beg end)
          (list beg end (buffer-substring-no-properties beg end)))))))

(defun hypertypst-try-expand-snippet ()
  "If the word before point is a snippet trigger, expand it.
Returns t on success, nil otherwise."
  (when-let* ((info (hypertypst--word-before-point))
              (template (cdr (assoc (nth 2 info) hypertypst-snippet-alist))))
    (delete-region (nth 0 info) (nth 1 info))
    (insert template)
    ;; Move point back to the start so the navigator finds the FIRST stop
    ;; on the next call rather than a later one.
    (goto-char (nth 0 info))
    ;; Force parser refresh, then jump to first stop inside template.
    (treesit-parser-root-node (car (treesit-parser-list)))
    (hypertypst-next-stop)
    t))

(provide 'hypertypst-snippets)
;;; hypertypst-snippets.el ends here
