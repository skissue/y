;;; hypertypst-tests.el --- ERT suite for hypertypst -*- lexical-binding: t -*-

;; Run with:
;;   emacs --batch -L . -l hypertypst-tests.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'cl-lib)
(add-to-list 'load-path (file-name-directory (or load-file-name
                                                 buffer-file-name)))
(require 'hypertypst)

;;;; Fixture ------------------------------------------------------------------

(defmacro hypertypst-tests--with-buffer (initial &rest body)
  "Set up a synthetic typst buffer with INITIAL contents.
A literal `|' in INITIAL marks where point should be placed (and is
removed).  Registers a typst tree-sitter parser and pretends the minor
mode is active without invoking the major mode."
  (declare (indent 1) (debug (stringp body)))
  `(with-temp-buffer
     (insert ,initial)
     (goto-char (point-min))
     (when (search-forward "|" nil t) (delete-char -1))
     (treesit-parser-create 'typst)
     (setq-local hypertypst-mode t)
     ,@body))

(defun hypertypst-tests--char-after-string ()
  (and (char-after) (string (char-after))))

;;;; Context ------------------------------------------------------------------

(ert-deftest hypertypst-test-in-math-inside ()
  (hypertypst-tests--with-buffer "Hello $x + |y$ world"
    (should (hypertypst-in-math-p))))

(ert-deftest hypertypst-test-in-math-outside ()
  (hypertypst-tests--with-buffer "Hello |world"
    (should-not (hypertypst-in-math-p))))

(ert-deftest hypertypst-test-in-math-at-opening-dollar ()
  (hypertypst-tests--with-buffer "before |$x$ after"
    (should-not (hypertypst-in-math-p))))

(ert-deftest hypertypst-test-in-mat-row-inside ()
  (hypertypst-tests--with-buffer "$ mat(1, 2|; 3, 4) $"
    (should (hypertypst-in-mat-row-p))))

(ert-deftest hypertypst-test-in-mat-row-not-in-frac ()
  (hypertypst-tests--with-buffer "$ frac(a|, b) $"
    (should-not (hypertypst-in-mat-row-p))))

(ert-deftest hypertypst-test-in-mat-row-outside-math ()
  (hypertypst-tests--with-buffer "plain |text"
    (should-not (hypertypst-in-mat-row-p))))

;;;; previous-node ------------------------------------------------------------

(ert-deftest hypertypst-test-prev-node-letter ()
  (hypertypst-tests--with-buffer "$ x|$"
    (let ((n (hypertypst-previous-node)))
      (should n)
      (should (equal (treesit-node-text n t) "x")))))

(ert-deftest hypertypst-test-prev-node-call ()
  (hypertypst-tests--with-buffer "$ bar(x)|$"
    (let ((n (hypertypst-previous-node)))
      (should n)
      (should (equal (treesit-node-text n t) "bar(x)")))))

(ert-deftest hypertypst-test-prev-node-smallest-after-binop ()
  (hypertypst-tests--with-buffer "$ x + y|$"
    (let ((n (hypertypst-previous-node)))
      (should n)
      (should (equal (treesit-node-text n t) "y")))))

(ert-deftest hypertypst-test-prev-node-nested-call ()
  (hypertypst-tests--with-buffer "$ frac(a, b)|$"
    (let ((n (hypertypst-previous-node)))
      (should n)
      (should (equal (treesit-node-text n t) "frac(a, b)")))))

;;;; Stop collection ----------------------------------------------------------

(ert-deftest hypertypst-test-stops-frac-filled ()
  (hypertypst-tests--with-buffer "$ frac(a|, b) $"
    (should (= 2 (length (hypertypst--stops-in-block))))))

(ert-deftest hypertypst-test-stops-frac-empty ()
  (hypertypst-tests--with-buffer "$ frac(|, ) $"
    (should (= 2 (length (hypertypst--stops-in-block))))))

(ert-deftest hypertypst-test-stops-mat-four-cells ()
  (hypertypst-tests--with-buffer "$ mat(1|, 2; 3, 4) $"
    (should (= 4 (length (hypertypst--stops-in-block))))))

(ert-deftest hypertypst-test-stops-mat-empty ()
  (hypertypst-tests--with-buffer "$ mat(|, ; , ) $"
    (should (= 4 (length (hypertypst--stops-in-block))))))

(ert-deftest hypertypst-test-stops-sum-empty-groups ()
  (hypertypst-tests--with-buffer "$ sum|_()^() $"
    (should (= 2 (length (hypertypst--stops-in-block))))))

(ert-deftest hypertypst-test-stops-sqrt-single ()
  (hypertypst-tests--with-buffer "$ sqrt(|) $"
    (should (= 1 (length (hypertypst--stops-in-block))))))

(ert-deftest hypertypst-test-stops-no-math ()
  (hypertypst-tests--with-buffer "no math |here"
    (should-not (hypertypst--stops-in-block))))

(ert-deftest hypertypst-test-stops-bare-attach-no-stop ()
  ;; `x^n' is a plain attach with `sup: letter' -- no group, no stop.
  (hypertypst-tests--with-buffer "$ x|^n $"
    (should-not (hypertypst--stops-in-block))))

;;;; Navigation ---------------------------------------------------------------

(ert-deftest hypertypst-test-next-stop-into-frac-first-slot ()
  (hypertypst-tests--with-buffer "$ |frac(a, b) $"
    (should (hypertypst-next-stop))
    (should (eq (char-after) ?a))))

(ert-deftest hypertypst-test-next-stop-frac-first-to-second ()
  (hypertypst-tests--with-buffer "$ frac(|a, b) $"
    (should (hypertypst-next-stop))
    (should (eq (char-after) ?b))))

(ert-deftest hypertypst-test-next-stop-no-more ()
  (hypertypst-tests--with-buffer "$ frac(a, |b) $"
    (should-not (hypertypst-next-stop))))

(ert-deftest hypertypst-test-prev-stop-frac ()
  (hypertypst-tests--with-buffer "$ frac(a, |b) $"
    (should (hypertypst-prev-stop))
    (should (eq (char-after) ?a))))

(ert-deftest hypertypst-test-prev-stop-none ()
  (hypertypst-tests--with-buffer "$ |frac(a, b) $"
    (should-not (hypertypst-prev-stop))))

(ert-deftest hypertypst-test-next-stop-empty-slots ()
  (hypertypst-tests--with-buffer "$ |frac(, ) $"
    (should (hypertypst-next-stop))
    ;; First empty slot: cursor lands between '(' and ',' -> char-after is ','.
    (should (eq (char-after) ?,))
    (should (hypertypst-next-stop))
    ;; Second empty slot: cursor lands between ',' and ' )' -> char-after is space.
    (should (eq (char-after) ?\s))))

;;;; Snippet expansion --------------------------------------------------------

(ert-deftest hypertypst-test-snippet-fr-expands-to-frac ()
  (hypertypst-tests--with-buffer "$ fr|$"
    (should (hypertypst-try-expand-snippet))
    (should (string-match-p "frac(, )" (buffer-string)))))

(ert-deftest hypertypst-test-snippet-fr-lands-on-first-stop ()
  (hypertypst-tests--with-buffer "$ fr|$"
    (hypertypst-try-expand-snippet)
    ;; First empty slot is between '(' and ',' -- char-after is ','.
    (should (eq (char-after) ?,))))

(ert-deftest hypertypst-test-snippet-sm-expands-to-sum ()
  (hypertypst-tests--with-buffer "$ sm|$"
    (should (hypertypst-try-expand-snippet))
    (should (string-match-p "sum_()\\^()" (buffer-string)))))

(ert-deftest hypertypst-test-snippet-unknown-trigger ()
  (hypertypst-tests--with-buffer "$ xyz|$"
    (should-not (hypertypst-try-expand-snippet))
    (should (string= "$ xyz$" (buffer-string)))))

(ert-deftest hypertypst-test-snippet-no-word ()
  (hypertypst-tests--with-buffer "$ |$"
    (should-not (hypertypst-try-expand-snippet))))

;;;; Modifier wrapping --------------------------------------------------------

(ert-deftest hypertypst-test-wrap-letter-bar ()
  (hypertypst-tests--with-buffer "$ x|$"
    (let ((n (hypertypst-previous-node)))
      (hypertypst--wrap-region (treesit-node-start n)
                               (treesit-node-end n)
                               "bar"))
    (should (string= "$ bar(x)$" (buffer-string)))
    (should (eq (char-before) ?\)))))

(ert-deftest hypertypst-test-wrap-call-bar ()
  (hypertypst-tests--with-buffer "$ frac(a, b)|$"
    (let ((n (hypertypst-previous-node)))
      (hypertypst--wrap-region (treesit-node-start n)
                               (treesit-node-end n)
                               "bar"))
    (should (string= "$ bar(frac(a, b))$" (buffer-string)))))

(ert-deftest hypertypst-test-wrap-region-overrides-prev-node ()
  (hypertypst-tests--with-buffer "$ x + y|$"
    ;; Manually mark `x + y' (positions 3..8 in this buffer).
    (let ((beg 3) (end 8))
      (hypertypst--wrap-region beg end "bar")
      (should (string= "$ bar(x + y)$" (buffer-string))))))

;;;; Smart insertions ---------------------------------------------------------

(ert-deftest hypertypst-test-smart-_-in-math ()
  (hypertypst-tests--with-buffer "$ x|$"
    (hypertypst-smart-_)
    (should (string= "$ x_()$" (buffer-string)))
    (should (eq (char-after) ?\)))))

(ert-deftest hypertypst-test-smart-_-outside-math ()
  (hypertypst-tests--with-buffer "plain |text"
    (hypertypst-smart-_)
    (should (string= "plain _text" (buffer-string)))))

(ert-deftest hypertypst-test-smart-^-in-math ()
  (hypertypst-tests--with-buffer "$ x|$"
    (hypertypst-smart-^)
    (should (string= "$ x^()$" (buffer-string)))
    (should (eq (char-after) ?\)))))

(ert-deftest hypertypst-test-smart-dollar-outside-math ()
  (hypertypst-tests--with-buffer "|"
    (hypertypst-smart-$)
    (should (string= "$$" (buffer-string)))
    (should (= (point) 2))))

(ert-deftest hypertypst-test-smart-dollar-in-math-closes ()
  (hypertypst-tests--with-buffer "$x|$"
    (hypertypst-smart-$)
    (should (string= "$x$$" (buffer-string)))))

(ert-deftest hypertypst-test-smart-spc-between-dollars ()
  (hypertypst-tests--with-buffer "$|$"
    (hypertypst-smart-SPC)
    (should (string= "$  $" (buffer-string)))
    (should (= (point) 3))))

(ert-deftest hypertypst-test-smart-spc-not-between-dollars ()
  (hypertypst-tests--with-buffer "$ x|$"
    (hypertypst-smart-SPC)
    (should (string= "$ x $" (buffer-string)))))

(ert-deftest hypertypst-test-smart-spc-outside-anything ()
  (hypertypst-tests--with-buffer "hello|world"
    (hypertypst-smart-SPC)
    (should (string= "hello world" (buffer-string)))))

;;;; Symbol dispatch (verified via table, not read-char) ----------------------

(ert-deftest hypertypst-test-symbol-table-greek ()
  (should (equal "alpha" (alist-get ?a hypertypst-symbol-alist)))
  (should (equal "beta"  (alist-get ?b hypertypst-symbol-alist)))
  (should (equal "infinity" (alist-get ?8 hypertypst-symbol-alist))))

(ert-deftest hypertypst-test-modifier-table ()
  (should (equal "bar"   (alist-get ?b hypertypst-modifier-alist)))
  (should (equal "arrow" (alist-get ?v hypertypst-modifier-alist)))
  (should (equal "bold"  (alist-get ?B hypertypst-modifier-alist))))

;;;; End-to-end: snippet + nested smart-_ + tab navigation --------------------

(ert-deftest hypertypst-test-e2e-snippet-then-nested-script ()
  "Expand fr -> frac(, ); type x in slot 1; smart-_; type n; TAB -> slot 2."
  (hypertypst-tests--with-buffer "$ fr|$"
    ;; Expand snippet -- lands at first empty slot.
    (hypertypst-try-expand-snippet)
    (should (string-match-p "frac(, )" (buffer-string)))
    ;; Type `x' in the first slot.
    (insert "x")
    (should (string-match-p "frac(x, )" (buffer-string)))
    ;; Smart subscript -- inserts _() at point.
    (hypertypst-smart-_)
    (should (string-match-p "frac(x_(), )" (buffer-string)))
    ;; Type `n' inside the empty subscript group.
    (insert "n")
    (should (string-match-p "frac(x_(n), )" (buffer-string)))
    ;; TAB now: next stop forward is the second frac slot (after the comma).
    (should (hypertypst-next-stop))
    ;; Cursor should land at the second slot of frac.  It's empty -> char-after
    ;; is the trailing space before `)'.
    (should (eq (char-after) ?\s))))

(provide 'hypertypst-tests)
;;; hypertypst-tests.el ends here
