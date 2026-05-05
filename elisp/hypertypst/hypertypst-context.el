;;; hypertypst-context.el --- Tree-sitter context helpers -*- lexical-binding: t -*-

;; Predicates and node lookups used by every other subsystem.
;; All operations are AST-based via `treesit'.

;;; Code:

(require 'treesit)

(defun hypertypst--node-ancestor (node type)
  "Return nearest ancestor (or NODE itself) whose type is TYPE, else nil."
  (let ((n node))
    (while (and n (not (equal (treesit-node-type n) type)))
      (setq n (treesit-node-parent n)))
    n))

(defun hypertypst--strictly-inside-p (node pos)
  "Return non-nil if POS is strictly inside NODE (excludes both endpoints).
This matters at delimiter boundaries: point exactly at an opening `$'
is at the start of the math node but typing there would insert outside it."
  (and node
       (< (treesit-node-start node) pos)
       (< pos (treesit-node-end node))))

(defun hypertypst-math-block (&optional pos)
  "Return the enclosing `math' node at POS (or point), or nil.
Returns nil at the exact opening or closing `$' boundary."
  (let* ((p (or pos (point)))
         (node (treesit-node-at p))
         (math (hypertypst--node-ancestor node "math")))
    (and (hypertypst--strictly-inside-p math p) math)))

(defun hypertypst-in-math-p (&optional pos)
  "Return non-nil if POS (or point) is inside a `math' node (strictly)."
  (hypertypst-math-block pos))

(defun hypertypst--call-callee-text (call-node)
  "Return text of CALL-NODE's callee child, or nil."
  (when-let* ((first (car (treesit-node-children call-node))))
    (treesit-node-text first t)))

(defun hypertypst-in-mat-row-p (&optional pos)
  "Return non-nil if POS (or point) is inside a `mat(...)' argument list."
  (let ((node (treesit-node-at (or pos (point))))
        (found nil))
    (while (and node (not found))
      (when (and (member (treesit-node-type node) '("call" "apply"))
                 (equal (hypertypst--call-callee-text node) "mat"))
        (setq found t))
      (setq node (treesit-node-parent node)))
    found))

(defun hypertypst-previous-node (&optional pos)
  "Return the smallest node ending exactly at POS (or point).
Walks up from leaf so that anonymous tokens like `)' resolve to their parent.
Returns nil if no such node exists."
  (let ((p (or pos (point))))
    (when (> p (point-min))
      (let* ((leaf (treesit-node-at (1- p)))
             (node leaf))
        ;; If leaf is anonymous (e.g. ')'), prefer parent.
        (while (and node
                    (not (treesit-node-check node 'named))
                    (treesit-node-parent node))
          (setq node (treesit-node-parent node)))
        ;; Require the chosen node to actually end at p.
        (when (and node (= (treesit-node-end node) p))
          node)))))

(provide 'hypertypst-context)
;;; hypertypst-context.el ends here
