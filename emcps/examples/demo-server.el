;;; demo-server.el --- Example EMCPS server -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name ".." (file-name-directory load-file-name)))

(require 'emcps)

(emcps-tools-clear)

(defvar emcps-demo-state nil
  "Mutable state exposed by demo MCP tools.")

(emcps-register-tools
 (list
  (emcps-make-tool
   :name "echo"
   :function (lambda (text) text)
   :description "Return the provided text."
   :args '((:name "text" :type string :description "Text to echo.")))
  (emcps-make-tool
   :name "add"
   :function (lambda (a b) (number-to-string (+ a b)))
   :description "Add two numbers."
   :args '((:name "a" :type number :description "First number.")
           (:name "b" :type number :description "Second number.")))
  (emcps-make-tool
   :name "set_demo_state"
   :function (lambda (value)
               (setq emcps-demo-state value)
               (format "demo state set to %s" value))
   :description "Set mutable state inside the long-running Emacs process."
   :args '((:name "value" :type string :description "State value to store.")))
  (emcps-make-tool
   :name "get_demo_state"
   :function (lambda () (or emcps-demo-state ""))
   :description "Return mutable state stored inside the long-running Emacs process."
   :args nil)))

(let ((server (emcps-start-server :host "127.0.0.1" :port 7072 :path "/mcp")))
  (message "EMCPS demo server listening on http://%s:%s%s"
           (emcps-server-host server)
           (emcps-server-port server)
           (emcps-server-path server))
  (while t
    (accept-process-output nil 1)))

;;; demo-server.el ends here
