;;; dump-tree.el --- Dump treesit tree for scratch.typ -*- lexical-binding: t -*-

;; Run with: emacs --batch -l dump-tree.el

(require 'treesit)

(defvar dump-file (expand-file-name "scratch.typ" (file-name-directory load-file-name)))

(defun dump-tree--node (node depth)
  (let ((type (treesit-node-type node))
        (text (treesit-node-text node t))
        (start (treesit-node-start node))
        (end (treesit-node-end node))
        (named (treesit-node-check node 'named))
        (field (treesit-node-field-name node)))
    (princ (format "%s[%d-%d] %s%s%s%s\n"
                   (make-string (* depth 2) ?\s)
                   start end
                   (if named "" "(anon) ")
                   (if field (format "%s: " field) "")
                   type
                   (if (and (< (- end start) 40)
                            (not (string-match-p "\n" text)))
                       (format "  %S" text)
                     "")))
    (dolist (child (treesit-node-children node))
      (dump-tree--node child (1+ depth)))))

(with-temp-buffer
  (insert-file-contents dump-file)
  (treesit-parser-create 'typst)
  (let ((root (treesit-buffer-root-node 'typst)))
    (princ "=== FULL TREE ===\n")
    (dump-tree--node root 0)))

;;; dump-tree.el ends here
