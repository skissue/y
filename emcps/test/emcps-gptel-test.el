;;; emcps-gptel-test.el --- Tests for optional gptel bridge -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name ".." (file-name-directory load-file-name)))

(require 'ert)
(require 'gptel)
(require 'emcps-gptel)

(ert-deftest emcps-gptel-converts-real-gptel-tool ()
  (let* ((gptel-tool
          (gptel-make-tool
           :name "choose_editor"
           :function #'identity
           :description "Choose an editor."
           :args '((:name "editor"
                    :type string
                    :enum ["emacs" "vi"]
                    :description "Editor name."))))
         (tool (emcps-gptel-tool gptel-tool))
         (schema (emcps-tool-input-schema tool))
         (editor (cl-loop for (key value) on (plist-get schema :properties) by #'cddr
                          when (equal (symbol-name key) ":editor")
                          return value)))
    (should (equal (emcps-tool-name tool) "choose_editor"))
    (should (equal (plist-get editor :type) "string"))
    (should (equal (plist-get editor :enum) ["emacs" "vi"]))))

(provide 'emcps-gptel-test)

;;; emcps-gptel-test.el ends here
