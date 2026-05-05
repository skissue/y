;;; hypertypst-modifiers.el --- Semicolon modifier entry -*- lexical-binding: t -*-

;; ; + char wraps the previous node (or active region) in a Typst function.
;; Outside math, or inside a `mat(...)' row (where `;' separates rows),
;; insert `;' literally.

;;; Code:

(require 'hypertypst-context)
(require 'hypertypst-data)

(defcustom hypertypst-modifier-alist
  hypertypst-data-modifier-alist
  "Alist mapping char (after `;') to Typst wrap function name."
  :type '(alist :key-type character :value-type string)
  :group 'hypertypst)

(defun hypertypst--wrap-region (beg end fn-name)
  "Wrap region [BEG, END) as `FN-NAME(...)' in place.
Point ends up after the closing paren."
  (save-excursion
    (goto-char end)
    (insert ")"))
  (save-excursion
    (goto-char beg)
    (insert fn-name "("))
  (goto-char (+ end (length fn-name) 2)))  ; "fn(" + ")"

(defun hypertypst-modifier-dispatch ()
  "Read next char; wrap previous node (or region) with the mapped function.
Falls through to literal `;' insertion outside math or inside `mat(...)'."
  (interactive)
  (cond
   ((not (hypertypst-in-math-p))
    (insert ?\;))
   ((hypertypst-in-mat-row-p)
    (insert ?\;))
   (t
    (let* ((ch (read-char "Modifier ;"))
           (fn (alist-get ch hypertypst-modifier-alist)))
      (cond
       ((null fn)
        (insert ?\; ch))
       ((use-region-p)
        (hypertypst--wrap-region (region-beginning) (region-end) fn)
        (deactivate-mark))
       (t
        (let ((node (hypertypst-previous-node)))
          (if node
              (hypertypst--wrap-region (treesit-node-start node)
                                       (treesit-node-end node)
                                       fn)
            ;; No previous node: insert `fn()' and place point inside.
            (insert fn "()")
            (backward-char 1)))))))))

(provide 'hypertypst-modifiers)
;;; hypertypst-modifiers.el ends here
