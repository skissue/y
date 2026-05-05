;;; hypertypst-smart.el --- Smart insertions: _ ^ $ SPC -*- lexical-binding: t -*-

;; - `_' / `^' in math insert `_()' / `^()' with point inside.
;; - `$' anywhere inserts `$$' with point in the middle (entering math).
;; - `SPC' immediately between `$|$' expands to `$ | $' (display math).

;;; Code:

(require 'hypertypst-context)

(defun hypertypst-smart-_ ()
  "Insert `_()' in math with point inside; bare `_' otherwise."
  (interactive)
  (if (hypertypst-in-math-p)
      (progn (insert "_()") (backward-char 1))
    (insert ?_)))

(defun hypertypst-smart-^ ()
  "Insert `^()' in math with point inside; bare `^' otherwise."
  (interactive)
  (if (hypertypst-in-math-p)
      (progn (insert "^()") (backward-char 1))
    (insert ?^)))

(defun hypertypst-smart-$ ()
  "Insert `$$' and place point in the middle, entering math.
If already in math, insert a single `$' (closing the block)."
  (interactive)
  (if (hypertypst-in-math-p)
      (insert ?$)
    (insert "$$")
    (backward-char 1)))

(defun hypertypst-smart-SPC ()
  "If point is exactly between two `$', expand to `$ | $' (display math).
Otherwise insert a normal space."
  (interactive)
  (if (and (> (point) (point-min))
           (< (point) (point-max))
           (eq (char-before) ?$)
           (eq (char-after)  ?$))
      (progn (insert "  ") (backward-char 1))
    (insert ?\s)))

(provide 'hypertypst-smart)
;;; hypertypst-smart.el ends here
