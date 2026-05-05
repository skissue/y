;;; hypertypst-nav.el --- Tab-stop navigation via tree-sitter -*- lexical-binding: t -*-

;; Stops are positions inside the argument slots of `call', `apply', and
;; `group' nodes -- one stop per slot, regardless of whether the slot is
;; empty.  Stops are derived fresh on every TAB; no buffer-local state.

;;; Code:

(require 'treesit)
(require 'hypertypst-context)

(defun hypertypst--slot-stops (node has-callee)
  "Enumerate stop positions for slots inside NODE.
HAS-CALLEE means the first child is the callee (skip it)."
  (let ((children (treesit-node-children node))
        stops
        prev-delim-end
        slot-formula)
    (when has-callee (pop children))
    (dolist (child children)
      (let ((type (treesit-node-type child)))
        (cond
         ((and (null prev-delim-end) (member type '("(" "[")))
          (setq prev-delim-end (treesit-node-end child)
                slot-formula nil))
         ((member type '("," ";"))
          (push (or (and slot-formula (treesit-node-start slot-formula))
                    prev-delim-end)
                stops)
          (setq prev-delim-end (treesit-node-end child)
                slot-formula nil))
         ((member type '(")" "]"))
          (push (or (and slot-formula (treesit-node-start slot-formula))
                    prev-delim-end)
                stops)
          (setq prev-delim-end nil))
         ((equal type "formula")
          (setq slot-formula child)))))
    (nreverse stops)))

(defun hypertypst--node-stops (node)
  "Return list of stop positions contributed by NODE itself."
  (pcase (treesit-node-type node)
    ((or "call" "apply") (hypertypst--slot-stops node t))
    ("group"             (hypertypst--slot-stops node nil))))

(defun hypertypst--collect-stops (node)
  "Recursively collect all stops in subtree rooted at NODE, sorted ascending."
  (let (stops)
    (cl-labels ((walk (n)
                  (let ((own (hypertypst--node-stops n)))
                    (when own (setq stops (nconc own stops))))
                  (dolist (c (treesit-node-children n))
                    (walk c))))
      (walk node))
    (sort stops #'<)))

(defun hypertypst--stops-in-block ()
  "Return sorted list of stop positions in the math block at point, or nil."
  (when-let* ((block (hypertypst-math-block)))
    (hypertypst--collect-stops block)))

(defun hypertypst-next-stop ()
  "Move point to the next tab stop in the current math block.
Returns t if a stop was found, nil otherwise (caller should fall through)."
  (interactive)
  (let* ((stops (hypertypst--stops-in-block))
         (next (seq-find (lambda (p) (> p (point))) stops)))
    (when next (goto-char next) t)))

(defun hypertypst-prev-stop ()
  "Move point to the previous tab stop in the current math block."
  (interactive)
  (let* ((stops (hypertypst--stops-in-block))
         (prev (car (last (seq-filter (lambda (p) (< p (point))) stops)))))
    (when prev (goto-char prev) t)))

(provide 'hypertypst-nav)
;;; hypertypst-nav.el ends here
