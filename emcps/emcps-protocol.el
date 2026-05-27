;;; emcps-protocol.el --- MCP protocol handlers -*- lexical-binding: t; -*-

;;; Commentary:

;; Minimal server-side MCP protocol support for initialize, ping and tools.

;;; Code:

(require 'cl-lib)
(require 'jsonrpc)
(require 'emcps-deferred)
(require 'emcps-tools)

(defconst emcps-protocol-version "2025-11-25")

(defconst emcps-supported-protocol-versions
  '("2025-03-26" "2025-06-18" "2025-11-25"))

(defvar emcps-server-name "emcps"
  "Name reported in MCP initialize responses.")

(defvar emcps-server-version "0.1.0"
  "Version reported in MCP initialize responses.")

(defvar emcps-tool-timeout 60
  "Seconds to wait for an async tool callback before returning an error.")

(defun emcps-protocol-valid-version-p (version)
  "Return non-nil if VERSION is supported."
  (member version emcps-supported-protocol-versions))

(defun emcps-protocol--text-content (text)
  "Return a MCP text content block for TEXT."
  `(:type "text" :text ,text))

(defun emcps-protocol--tool-result (value is-error)
  "Return MCP CallToolResult for VALUE.
When IS-ERROR is non-nil, mark the tool result as failed while still
returning a normal JSON-RPC response."
  `(:content ,(vector (emcps-protocol--text-content
                       (emcps-protocol--result-string value)))
    :isError ,(if is-error t :json-false)))

(defun emcps-protocol--result-string (value)
  "Convert Elisp tool return VALUE to a text result."
  (cond
   ((stringp value) value)
   ((null value) "")
   (t (prin1-to-string value))))

(defun emcps-protocol-initialize (params)
  "Return MCP InitializeResult."
  (let* ((requested-version (plist-get params :protocolVersion))
         (version (if (emcps-protocol-valid-version-p requested-version)
                      requested-version
                    emcps-protocol-version)))
    `(:protocolVersion ,version
      :capabilities (:tools (:listChanged :json-false))
      :serverInfo (:name ,emcps-server-name
                   :version ,emcps-server-version))))

(defun emcps-protocol-tools-list (_params tools)
  "Return MCP tools/list result."
  `(:tools ,(emcps-tool-descriptors tools)))

(defun emcps-protocol-tools-call (params tools)
  "Return MCP tools/call result for PARAMS."
  (let* ((name (plist-get params :name))
         (arguments (or (plist-get params :arguments) '())))
    (condition-case err
        (emcps-call-tool-deferred
         tools
         name
         arguments
         (lambda (value) (emcps-protocol--tool-result value nil))
         (lambda (value) (emcps-protocol--tool-result value t))
         (emcps-protocol--tool-result
          (format "Tool timed out after %s seconds" emcps-tool-timeout)
          t)
         emcps-tool-timeout)
      (jsonrpc-error
       (signal (car err) (cdr err)))
      (error
       (emcps-protocol--tool-result
        (error-message-string err)
        t)))))

(defun emcps-protocol-dispatch-request (_conn method params &optional tools)
  "Dispatch MCP request METHOD with PARAMS."
  (pcase (symbol-name method)
    ("initialize" (emcps-protocol-initialize params))
    ("ping" '())
    ("tools/list" (emcps-protocol-tools-list params tools))
    ("tools/call" (emcps-protocol-tools-call params tools))
    (_ (jsonrpc-error :code -32601
                      :message (format "Method not found: %s" method)))))

(defun emcps-protocol-dispatch-notification (_conn method _params)
  "Dispatch MCP notification METHOD."
  (ignore method)
  nil)

(provide 'emcps-protocol)

;;; emcps-protocol.el ends here
