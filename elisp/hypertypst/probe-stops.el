;;; probe-stops.el --- Validate stop-finding strategy -*- lexical-binding: t -*-

;; Run with: emacs --batch -l probe-stops.el

(require 'treesit)

(defvar probe-file (expand-file-name "scratch.typ" (file-name-directory load-file-name)))

(defun probe--node-stops (node)
  "Return list of stop positions contributed by NODE (this node only, not children)."
  (let ((type (treesit-node-type node)))
    (cond
     ;; Call/apply: one stop per slot, between delimiters.
     ((member type '("call" "apply"))
      (probe--slot-stops node t))
     ;; Group (bare parens used for grouping or as sub/sup): one slot.
     ((equal type "group")
      (probe--slot-stops node nil)))))

(defun probe--slot-stops (node has-callee)
  "Enumerate stop positions for slots inside NODE.
HAS-CALLEE means the first child is the callee ident/letter (skip it)."
  (let ((children (treesit-node-children node))
        stops
        (prev-delim-end nil)  ; position right after the most recent delimiter
        (slot-formula nil))   ; formula node currently occupying the slot
    (when has-callee (pop children))  ; drop callee
    (dolist (child children)
      (let ((type (treesit-node-type child))
            (start (treesit-node-start child))
            (end (treesit-node-end child)))
        (cond
         ;; Opening delimiter — start the first slot.
         ((and (null prev-delim-end) (member type '("(" "[")))
          (setq prev-delim-end end
                slot-formula nil))
         ;; Separator — close current slot, start next.
         ((member type '("," ";"))
          (push (or (and slot-formula (treesit-node-start slot-formula))
                    prev-delim-end)
                stops)
          (setq prev-delim-end end
                slot-formula nil))
         ;; Closing delimiter — close last slot.
         ((member type '(")" "]"))
          (push (or (and slot-formula (treesit-node-start slot-formula))
                    prev-delim-end)
                stops)
          (setq prev-delim-end nil))
         ;; Formula content occupies the current slot.
         ((equal type "formula")
          (setq slot-formula child)))))
    (nreverse stops)))

(defun probe--collect (node acc)
  "Recursively collect stops from NODE into ACC (list)."
  (let ((own (probe--node-stops node)))
    (when own
      (setq acc (append own acc))))
  (dolist (child (treesit-node-children node))
    (setq acc (probe--collect child acc)))
  acc)

(with-temp-buffer
  (insert-file-contents probe-file)
  (treesit-parser-create 'typst)
  (let* ((root (treesit-buffer-root-node 'typst))
         (stops (sort (probe--collect root nil) #'<)))
    (princ (format "Total stops found: %d\n\n" (length stops)))
    (dolist (pos stops)
      (goto-char pos)
      (let ((line (line-number-at-pos pos))
            (col (current-column))
            (ctx-start (max (point-min) (- pos 15)))
            (ctx-end (min (point-max) (+ pos 15))))
        (princ (format "pos=%d  L%d:C%d  ctx=%S  (cursor between '%s' and '%s')\n"
                       pos line col
                       (replace-regexp-in-string
                        "\n" "\\\\n"
                        (buffer-substring-no-properties ctx-start ctx-end))
                       (if (> pos (point-min))
                           (string (char-before pos)) "")
                       (if (< pos (point-max))
                           (string (char-after pos)) "")))))))

;;; probe-stops.el ends here
