;;; emcps-deferred.el --- Deferred values for EMCPS -*- lexical-binding: t; -*-

;;; Commentary:

;; Small one-shot deferred primitive used for async tool calls.  The first
;; result wins; later callbacks are ignored.

;;; Code:

(require 'cl-lib)

(cl-defstruct (emcps-deferred
               (:constructor emcps-deferred--create))
  done value handlers timeout-timer)

(defun emcps-deferred-create (&optional timeout timeout-value)
  "Return a new deferred.
When TIMEOUT is a positive number, resolve with TIMEOUT-VALUE after that
many seconds unless the deferred has already resolved."
  (let (deferred)
    (setq deferred (emcps-deferred--create))
    (when (and (numberp timeout) (> timeout 0))
      (setf (emcps-deferred-timeout-timer deferred)
            (run-at-time timeout nil
                         (lambda ()
                           (emcps-deferred-resolve deferred timeout-value)))))
    deferred))

(defun emcps-deferred-resolve (deferred value)
  "Resolve DEFERRED with VALUE.
Return non-nil if this call resolved the deferred.  Return nil when the
deferred was already resolved."
  (unless (emcps-deferred-done deferred)
    (setf (emcps-deferred-done deferred) t)
    (setf (emcps-deferred-value deferred) value)
    (when-let* ((timer (emcps-deferred-timeout-timer deferred)))
      (cancel-timer timer)
      (setf (emcps-deferred-timeout-timer deferred) nil))
    (let ((handlers (nreverse (emcps-deferred-handlers deferred))))
      (setf (emcps-deferred-handlers deferred) nil)
      (dolist (handler handlers)
        (funcall handler value)))
    t))

(defun emcps-deferred-on-resolve (deferred handler)
  "Run HANDLER with DEFERRED's value once it resolves."
  (if (emcps-deferred-done deferred)
      (funcall handler (emcps-deferred-value deferred))
    (push handler (emcps-deferred-handlers deferred))))

(provide 'emcps-deferred)

;;; emcps-deferred.el ends here
