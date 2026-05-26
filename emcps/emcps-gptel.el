;;; emcps-gptel.el --- gptel bridge for EMCPS tools -*- lexical-binding: t; -*-

;;; Commentary:

;; Optional adapter for converting already-built gptel tools into EMCPS tools.
;; Core EMCPS does not depend on gptel.

;;; Code:

(require 'gptel)
(require 'emcps-tools)

(defun emcps-gptel-tool (tool)
  "Convert gptel TOOL into an `emcps-tool'."
  (unless (gptel-tool-p tool)
    (signal 'wrong-type-argument (list 'gptel-tool tool)))
  (emcps-make-tool
   :name (gptel-tool-name tool)
   :function (gptel-tool-function tool)
   :description (gptel-tool-description tool)
   :args (gptel-tool-args tool)
   :category (gptel-tool-category tool)
   :confirm (gptel-tool-confirm tool)
   :async (gptel-tool-async tool)
   :include (gptel-tool-include tool)))

(defun emcps-register-gptel-tool (tool)
  "Convert and register gptel TOOL."
  (emcps-register-tool (emcps-gptel-tool tool)))

(provide 'emcps-gptel)

;;; emcps-gptel.el ends here
