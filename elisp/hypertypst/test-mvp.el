;;; test-mvp.el --- Smoke tests for hypertypst MVP -*- lexical-binding: t -*-

;; Run with: emacs --batch -L . -l test-mvp.el

(require 'cl-lib)
(add-to-list 'load-path (file-name-directory load-file-name))
(require 'hypertypst)

(defvar test-failures 0)

(defun test-msg (label ok detail)
  (princ (format "%s %s%s\n"
                 (if ok "PASS" "FAIL")
                 label
                 (if detail (format " -- %s" detail) "")))
  (unless ok (cl-incf test-failures)))

(defmacro with-typst-buffer (initial &rest body)
  "Set up a buffer with INITIAL contents (`|' marks point) in typst mode."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,initial)
     (goto-char (point-min))
     (when (search-forward "|" nil t) (delete-char -1))
     ;; Synthetic typst buffer: register the parser without invoking the
     ;; (heavy) major mode.
     (treesit-parser-create 'typst)
     (setq-local hypertypst-mode t)
     ,@body))

;;; ---- in-math? ----
(with-typst-buffer "Hello $x + |y$ world"
  (test-msg "in-math? inside $...$" (hypertypst-in-math-p) nil))

(with-typst-buffer "Hello |world"
  (test-msg "in-math? outside $...$" (not (hypertypst-in-math-p)) nil))

;;; ---- in-mat-row? ----
(with-typst-buffer "$ mat(1, 2|; 3, 4) $"
  (test-msg "in-mat-row? inside mat()" (hypertypst-in-mat-row-p) nil))

(with-typst-buffer "$ frac(a|, b) $"
  (test-msg "in-mat-row? inside frac() (no)"
            (not (hypertypst-in-mat-row-p)) nil))

;;; ---- previous-node ----
(with-typst-buffer "$ x|$"
  (let ((n (hypertypst-previous-node)))
    (test-msg "previous-node: x"
              (and n (equal (treesit-node-text n t) "x"))
              (and n (treesit-node-text n t)))))

(with-typst-buffer "$ bar(x)|$"
  (let ((n (hypertypst-previous-node)))
    (test-msg "previous-node: bar(x)"
              (and n (equal (treesit-node-text n t) "bar(x)"))
              (and n (treesit-node-text n t)))))

(with-typst-buffer "$ x + y|$"
  (let ((n (hypertypst-previous-node)))
    (test-msg "previous-node: y (smallest, not x+y)"
              (and n (equal (treesit-node-text n t) "y"))
              (and n (treesit-node-text n t)))))

;;; ---- stop collection ----
(with-typst-buffer "$ frac(a, b) $"
  (let ((stops (hypertypst--stops-in-block)))
    (test-msg "stops in frac(a,b): 2"
              (= (length stops) 2)
              (format "%S" stops))))

(with-typst-buffer "$ frac(, ) $"
  (let ((stops (hypertypst--stops-in-block)))
    (test-msg "stops in frac(, ): 2 (empty slots)"
              (= (length stops) 2)
              (format "%S" stops))))

(with-typst-buffer "$ mat(1, 2; 3, 4) $"
  (let ((stops (hypertypst--stops-in-block)))
    (test-msg "stops in mat(1,2;3,4): 4"
              (= (length stops) 4)
              (format "%S" stops))))

(with-typst-buffer "$ sum_()^() $"
  (let ((stops (hypertypst--stops-in-block)))
    (test-msg "stops in sum_()^(): 2 (sub + sup empty groups)"
              (= (length stops) 2)
              (format "%S" stops))))

(with-typst-buffer "$ sqrt() $"
  (let ((stops (hypertypst--stops-in-block)))
    (test-msg "stops in sqrt(): 1"
              (= (length stops) 1)
              (format "%S" stops))))

;;; ---- next-stop / prev-stop navigation ----
(with-typst-buffer "$ |frac(a, b) $"
  (hypertypst-next-stop)
  (test-msg "next-stop into frac slot 1 (lands on 'a')"
            (eq (char-after) ?a)
            (format "char-after=%c" (char-after))))

(with-typst-buffer "$ frac(|a, b) $"
  (hypertypst-next-stop)
  (test-msg "next-stop frac slot 1 -> slot 2 (lands on 'b')"
            (eq (char-after) ?b)
            (format "char-after=%c" (char-after))))

(with-typst-buffer "$ frac(a, |b) $"
  (test-msg "prev-stop frac slot 2 -> slot 1"
            (and (hypertypst-prev-stop)
                 (eq (char-after) ?a))
            (format "char-after=%c" (char-after))))

;;; ---- snippet expansion ----
(with-typst-buffer "$ fr|$"
  (hypertypst-try-expand-snippet)
  (let ((content (buffer-substring-no-properties (point-min) (point-max))))
    (test-msg "snippet 'fr' expands to 'frac(, )'"
              (string-match-p "frac(, )" content)
              content))
  (test-msg "snippet 'fr' lands point at first stop"
            (eq (char-after) ?,)
            (format "char-after=%c" (char-after))))

(with-typst-buffer "$ sm|$"
  (hypertypst-try-expand-snippet)
  (let ((content (buffer-substring-no-properties (point-min) (point-max))))
    (test-msg "snippet 'sm' expands to 'sum_()^()'"
              (string-match-p "sum_()\\^()" content)
              content)))

;;; ---- modifier wrapping ----
(with-typst-buffer "$ x|$"
  ;; Simulate ;b dispatch: bypass read-char by calling wrap directly.
  (let ((node (hypertypst-previous-node)))
    (hypertypst--wrap-region (treesit-node-start node)
                             (treesit-node-end node)
                             "bar"))
  (test-msg "wrap 'x' with bar -> 'bar(x)'"
            (string-match-p "bar(x)" (buffer-string))
            (buffer-string))
  (test-msg "wrap leaves point after closing paren"
            (eq (char-before) ?\))
            (format "char-before=%c" (char-before))))

(with-typst-buffer "$ frac(a, b)|$"
  (let ((node (hypertypst-previous-node)))
    (hypertypst--wrap-region (treesit-node-start node)
                             (treesit-node-end node)
                             "bar"))
  (test-msg "wrap 'frac(a,b)' with bar -> 'bar(frac(a, b))'"
            (string-match-p "bar(frac(a, b))" (buffer-string))
            (buffer-string)))

;;; ---- smart insertion ----
(with-typst-buffer "$ x|$"
  (hypertypst-smart-_)
  (test-msg "smart-_ in math inserts _() with point inside"
            (and (string-match-p "x_()" (buffer-string))
                 (eq (char-after) ?\)))
            (buffer-string)))

(with-typst-buffer "|"
  (hypertypst-smart-$)
  (test-msg "smart-$ outside math inserts $$ with point inside"
            (and (string= (buffer-string) "$$")
                 (= (point) 2))
            (format "buf=%S point=%d" (buffer-string) (point))))

(with-typst-buffer "$|$"
  (hypertypst-smart-SPC)
  (test-msg "smart-SPC between $|$ -> $ | $"
            (and (string= (buffer-string) "$  $")
                 (= (point) 3))
            (format "buf=%S point=%d" (buffer-string) (point))))

(with-typst-buffer "$ x|$"
  (hypertypst-smart-SPC)
  (test-msg "smart-SPC after non-$ inserts plain space"
            (string= (buffer-string) "$ x $")
            (buffer-string)))

;;; ---- summary ----
(princ (format "\n%d test(s) failed.\n" test-failures))
(kill-emacs (if (> test-failures 0) 1 0))

;;; test-mvp.el ends here
