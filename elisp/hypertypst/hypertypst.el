;;; hypertypst.el --- Fast Typst math input -*- lexical-binding: t -*-

;; Author: hypertypst contributors
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1") (typst-ts-mode "0.1"))
;; Keywords: typst, math, convenience
;; URL: https://github.com/skissue/gxy

;;; Commentary:

;; A cdlatex-inspired fast input system for Typst math, built on tree-sitter.
;;
;; Activate the minor mode in a typst-ts-mode buffer:
;;
;;   (add-hook 'typst-ts-mode-hook #'hypertypst-mode)
;;
;; Triggers (only active inside `$...$'):
;;
;;   ` <c>     symbol entry        e.g. `a -> alpha
;;   ; <c>     wrap previous node  e.g. ;b on x  -> bar(x)
;;   _ / ^    smart subscript     inserts `_()` / `^()' with point inside
;;   $        enter math          inserts `$$' with point inside
;;   SPC      between `$|$'       expands to `$ | $' (display math)
;;   TAB      next tab stop       jumps to next slot in current math block
;;   S-TAB    previous tab stop
;;   <word> + TAB  expand snippet (if word matches a trigger)

;;; Code:

(require 'hypertypst-context)
(require 'hypertypst-nav)
(require 'hypertypst-snippets)
(require 'hypertypst-symbols)
(require 'hypertypst-modifiers)
(require 'hypertypst-smart)

(defgroup hypertypst nil
  "Fast input system for Typst math."
  :group 'typst
  :prefix "hypertypst-")

(defun hypertypst-tab-or-expand ()
  "TAB: try snippet expansion in math; else jump to next stop; else indent."
  (interactive)
  (cond
   ((and (hypertypst-in-math-p) (hypertypst-try-expand-snippet)))
   ((and (hypertypst-in-math-p) (hypertypst-next-stop)))
   (t (call-interactively #'indent-for-tab-command))))

(defun hypertypst-shift-tab-fallthrough ()
  "S-TAB: jump to previous stop in math; else no-op."
  (interactive)
  (unless (and (hypertypst-in-math-p) (hypertypst-prev-stop))
    (ignore)))

(defvar hypertypst-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "`")          #'hypertypst-symbol-dispatch)
    (define-key m (kbd ";")          #'hypertypst-modifier-dispatch)
    (define-key m (kbd "_")          #'hypertypst-smart-_)
    (define-key m (kbd "^")          #'hypertypst-smart-^)
    (define-key m (kbd "$")          #'hypertypst-smart-$)
    (define-key m (kbd "SPC")        #'hypertypst-smart-SPC)
    (define-key m (kbd "TAB")        #'hypertypst-tab-or-expand)
    (define-key m (kbd "<tab>")      #'hypertypst-tab-or-expand)
    (define-key m (kbd "<backtab>")  #'hypertypst-shift-tab-fallthrough)
    (define-key m (kbd "S-TAB")      #'hypertypst-shift-tab-fallthrough)
    m)
  "Keymap for `hypertypst-mode'.")

;;;###autoload
(define-minor-mode hypertypst-mode
  "Toggle hypertypst fast math input in this buffer."
  :lighter " hyperT"
  :keymap hypertypst-mode-map
  :group 'hypertypst
  (when hypertypst-mode
    (unless (treesit-language-available-p 'typst)
      (hypertypst-mode -1)
      (user-error "hypertypst requires the typst tree-sitter grammar"))
    (unless (treesit-parser-list nil 'typst)
      (treesit-parser-create 'typst))))

(provide 'hypertypst)
;;; hypertypst.el ends here
