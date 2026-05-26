;;; emcps-jsonrpc.el --- JSON-RPC adapter for HTTP MCP -*- lexical-binding: t; -*-

;;; Commentary:

;; Uses Emacs's built-in jsonrpc.el dispatcher, but captures replies into the
;; current HTTP request instead of using jsonrpc-process-connection framing.

;;; Code:

(require 'cl-lib)
(require 'eieio)
(require 'json)
(require 'jsonrpc)
(require 'emcps-protocol)

(defclass emcps-jsonrpc-http-connection (jsonrpc-connection)
  ((response
    :initform nil
    :accessor emcps-jsonrpc-response))
  "JSON-RPC connection whose replies are captured in memory.")

(cl-defmethod jsonrpc-connection-send ((connection emcps-jsonrpc-http-connection)
                                       &rest args
                                       &key id method _params
                                       (_result nil result-supplied-p)
                                       error _partial)
  "Capture a JSON-RPC reply for CONNECTION."
  (ignore method)
  (let* ((kind (cond ((or result-supplied-p error) 'reply)
                     (id 'request)
                     (t 'notification)))
         (message (jsonrpc-convert-to-endpoint connection args kind)))
    (setf (emcps-jsonrpc-response connection) message)
    message))

(defun emcps-jsonrpc-make-connection (&optional tools)
  "Create a JSON-RPC connection for one HTTP request."
  (emcps-jsonrpc-http-connection
   :name "emcps-http"
   :request-dispatcher (lambda (conn method params)
                         (emcps-protocol-dispatch-request
                          conn method params tools))
   :notification-dispatcher #'emcps-protocol-dispatch-notification
   :events-buffer-config '(:size 0 :format full)))

(defun emcps-jsonrpc-message-kind (message)
  "Return kind of decoded JSON-RPC MESSAGE."
  (let ((method (plist-get message :method))
        (id-present (plist-member message :id)))
    (cond
     ((and method id-present) 'request)
     (method 'notification)
     (id-present 'response)
     (t 'invalid))))

(defun emcps-jsonrpc-handle (message &optional tools)
  "Handle decoded JSON-RPC MESSAGE.
Return a plist (:kind KIND :response RESPONSE).  RESPONSE is nil for
accepted notifications and responses."
  (let ((kind (emcps-jsonrpc-message-kind message)))
    (pcase kind
      ('invalid
       (list :kind kind
             :response '(:jsonrpc "2.0"
                         :error (:code -32600 :message "Invalid Request")
                         :id nil)))
      ((or 'notification 'response)
       (let ((conn (emcps-jsonrpc-make-connection tools)))
         (jsonrpc-connection-receive conn message)
         (list :kind kind :response nil)))
      ('request
       (let ((conn (emcps-jsonrpc-make-connection tools)))
         (jsonrpc-connection-receive conn message)
         (list :kind kind :response (emcps-jsonrpc-response conn)))))))

(defun emcps-json-parse-string (string)
  "Parse JSON STRING into plist-oriented Elisp data."
  (json-parse-string string
                     :object-type 'plist
                     :array-type 'list
                     :null-object nil
                     :false-object :json-false))

(defun emcps-json-serialize (object)
  "Serialize OBJECT to JSON."
  (json-serialize object
                  :false-object :json-false
                  :null-object nil))

(provide 'emcps-jsonrpc)

;;; emcps-jsonrpc.el ends here
