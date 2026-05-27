;;; emcps-http.el --- Minimal HTTP transport for MCP -*- lexical-binding: t; -*-

;;; Commentary:

;; A deliberately small HTTP/1.1 server built on `make-network-process'.
;; It implements the JSON-response subset of MCP Streamable HTTP.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'emcps-deferred)
(require 'emcps-jsonrpc)
(require 'emcps-protocol)

(cl-defstruct (emcps-server
               (:constructor emcps-server--create))
  process host port path tools allowed-origins max-body-size)

(defvar emcps-http-current-server nil
  "Most recently started EMCPS server, if any.")

(defconst emcps-http--reason-phrases
  '((200 . "OK")
    (202 . "Accepted")
    (400 . "Bad Request")
    (403 . "Forbidden")
    (404 . "Not Found")
    (405 . "Method Not Allowed")
    (413 . "Payload Too Large")
    (500 . "Internal Server Error")))

(defun emcps-http--reason (status)
  "Return HTTP reason phrase for STATUS."
  (or (alist-get status emcps-http--reason-phrases) "Unknown"))

(defun emcps-http--header-value (headers name)
  "Return case-insensitive header NAME from HEADERS."
  (cdr (assoc-string (downcase name) headers t)))

(defun emcps-http--header-values (headers name)
  "Return all case-insensitive header NAME values from HEADERS."
  (let ((name (downcase name))
        values)
    (dolist (header headers (nreverse values))
      (when (string= (car header) name)
        (push (cdr header) values)))))

(defun emcps-http--parse-headers (header-text)
  "Parse HTTP HEADER-TEXT.
Return plist with :method, :target, :version and :headers."
  (let* ((lines (split-string header-text "\r\n"))
         (request-line (car lines))
         (parts (split-string request-line " " t))
         headers)
    (unless (= (length parts) 3)
      (error "Malformed request line"))
    (dolist (line (cdr lines))
      (when (string-match "\\`\\([^:]+\\):[ \t]*\\(.*\\)\\'" line)
        (push (cons (downcase (match-string 1 line))
                    (match-string 2 line))
              headers)))
    (list :method (nth 0 parts)
          :target (nth 1 parts)
          :version (nth 2 parts)
          :headers (nreverse headers))))

(defun emcps-http--split-request (data)
  "Return parsed request from DATA when complete, otherwise nil."
  (when-let* ((header-end (string-search "\r\n\r\n" data)))
    (let* ((header-text (substring data 0 header-end))
           (parsed (emcps-http--parse-headers header-text))
           (headers (plist-get parsed :headers))
           (content-length-text (or (emcps-http--header-value headers "content-length")
                                    "0"))
           (content-length (string-to-number content-length-text))
           (body-start (+ header-end 4))
           (request-end (+ body-start content-length)))
      (when (<= request-end (length data))
        (append parsed
                (list :body (substring data body-start request-end)
                      :remaining (substring data request-end)))))))

(defun emcps-http--localhost-origin-p (origin)
  "Return non-nil when ORIGIN is safe for the local default policy."
  (or (null origin)
      (string-empty-p origin)
      (string-match-p "\\`https?://\\(localhost\\|127\\.0\\.0\\.1\\|\\[::1\\]\\)\\(?::[0-9]+\\)?\\'" origin)))

(defun emcps-http--origin-allowed-p (server origin)
  "Return non-nil if ORIGIN is allowed for SERVER."
  (let ((allowed (emcps-server-allowed-origins server)))
    (cond
     ((null origin) t)
     ((eq allowed t) t)
     (allowed (member origin allowed))
     (t (emcps-http--localhost-origin-p origin)))))

(defun emcps-http--accept-post-p (headers)
  "Return non-nil if HEADERS satisfy MCP POST Accept requirements."
  (let ((accept (downcase (string-join
                           (emcps-http--header-values headers "accept")
                           ", "))))
    (and accept
         (string-search "application/json" accept)
         (string-search "text/event-stream" accept))))

(defun emcps-http--content-type-post-p (headers)
  "Return non-nil if HEADERS describe a JSON POST body."
  (when-let* ((content-type (emcps-http--header-value headers "content-type")))
    (string-search "application/json" (downcase content-type))))

(defun emcps-http--valid-protocol-version-p (headers)
  "Return non-nil if MCP protocol header in HEADERS is acceptable."
  (let ((version (emcps-http--header-value headers "mcp-protocol-version")))
    (or (null version)
        (emcps-protocol-valid-version-p version))))

(defun emcps-http--send (proc status headers body)
  "Send HTTP response on PROC with STATUS, HEADERS and BODY."
  (let* ((body (or body ""))
         (base-headers
          `(("Content-Length" . ,(number-to-string (string-bytes body)))
            ("Connection" . "close")))
         (header-text
          (mapconcat (lambda (header)
                       (format "%s: %s" (car header) (cdr header)))
                     (append headers base-headers)
                     "\r\n")))
    (process-send-string
     proc
     (format "HTTP/1.1 %d %s\r\n%s\r\n\r\n%s"
             status (emcps-http--reason status) header-text body))
    (delete-process proc)))

(defun emcps-http--send-json (proc status object)
  "Send JSON OBJECT response on PROC."
  (emcps-http--send proc status
                    '(("Content-Type" . "application/json; charset=utf-8"))
                    (emcps-json-serialize object)))

(defun emcps-http--send-empty (proc status)
  "Send empty HTTP response on PROC."
  (emcps-http--send proc status nil ""))

(defun emcps-http--send-json-error (proc status code message)
  "Send JSON-RPC error response on PROC."
  (emcps-http--send-json
   proc status
   `(:jsonrpc "2.0" :error (:code ,code :message ,message) :id nil)))

(defun emcps-http--handle-post (server proc request)
  "Handle POST REQUEST for SERVER on PROC."
  (let* ((headers (plist-get request :headers))
         (body (plist-get request :body)))
    (cond
     ((not (emcps-http--accept-post-p headers))
      (emcps-http--send-json-error proc 400 -32600 "Accept must include application/json and text/event-stream"))
     ((not (emcps-http--content-type-post-p headers))
      (emcps-http--send-json-error proc 400 -32600 "Content-Type must be application/json"))
     ((not (emcps-http--valid-protocol-version-p headers))
      (emcps-http--send-json-error proc 400 -32600 "Unsupported MCP protocol version"))
     (t
      (condition-case err
          (let* ((message (emcps-json-parse-string body))
                 (handled (emcps-jsonrpc-handle
                           message
                           (emcps-server-tools server)))
                 (response (plist-get handled :response))
                 (deferred (plist-get handled :deferred))
                 (response-getter (plist-get handled :response-getter)))
            (cond
             (response
              (emcps-http--send-json proc 200 response))
             (deferred
              (emcps-deferred-on-resolve
               deferred
               (lambda (_value)
                 (when (process-live-p proc)
                   (emcps-http--send-json proc 200
                                          (funcall response-getter))))))
             (t
              (emcps-http--send-empty proc 202))))
        (json-parse-error
         (emcps-http--send-json-error proc 400 -32700 "Parse error"))
        (error
         (emcps-http--send-json-error proc 500 -32603 (error-message-string err))))))))

(defun emcps-http--handle-request (server proc request)
  "Handle parsed HTTP REQUEST for SERVER on PROC."
  (let* ((method (plist-get request :method))
         (target (plist-get request :target))
         (headers (plist-get request :headers))
         (origin (emcps-http--header-value headers "origin")))
    (cond
     ((not (emcps-http--origin-allowed-p server origin))
      (emcps-http--send-json-error proc 403 -32600 "Forbidden origin"))
     ((not (string= target (emcps-server-path server)))
      (emcps-http--send-json-error proc 404 -32600 "Not found"))
     ((string= method "POST")
      (emcps-http--handle-post server proc request))
     ((or (string= method "GET") (string= method "DELETE"))
      (emcps-http--send-empty proc 405))
     (t
      (emcps-http--send-empty proc 405)))))

(defun emcps-http--filter (server proc chunk)
  "Accumulate CHUNK from PROC and handle complete requests for SERVER."
  (let* ((data (concat (or (process-get proc 'emcps-http-data) "") chunk))
         (max-body-size (emcps-server-max-body-size server)))
    (if (> (string-bytes data) max-body-size)
        (emcps-http--send-json-error proc 413 -32600 "Request body too large")
      (process-put proc 'emcps-http-data data)
      (when-let* ((request (emcps-http--split-request data)))
        (process-put proc 'emcps-http-data (plist-get request :remaining))
        (emcps-http--handle-request server proc request)))))

(cl-defun emcps-start-server (&key (host "127.0.0.1") (port 7072) (path "/mcp")
                                   tools allowed-origins
                                   (max-body-size (* 1024 1024)))
  "Start an MCP HTTP server.
HOST, PORT and PATH define the listening endpoint.  TOOLS is an
list of `emcps-tool' values, or nil for no tools.  ALLOWED-ORIGINS is
nil for localhost-only Origin validation, t for any origin, or a list of
exact Origin strings.  MAX-BODY-SIZE is the request limit in bytes."
  (let (server listener)
    (setq listener
          (make-network-process
           :name "emcps"
           :server t
           :host host
           :service port
           :noquery t
           :filter (lambda (proc chunk)
                     (emcps-http--filter server proc chunk))
           :sentinel (lambda (proc _event)
                       (unless (process-live-p proc)
                         (process-put proc 'emcps-http-data nil)))))
    (setq server
          (emcps-server--create
           :process listener
           :host host
           :port (process-contact listener :service)
           :path path
           :tools (emcps-tools-ensure tools)
           :allowed-origins allowed-origins
           :max-body-size max-body-size))
    (setq emcps-http-current-server server)
    server))

(defun emcps-stop-server (&optional server)
  "Stop SERVER or the current MCP HTTP server."
  (let ((server (or server emcps-http-current-server)))
    (when (and server (process-live-p (emcps-server-process server)))
      (delete-process (emcps-server-process server)))
    (when (eq server emcps-http-current-server)
      (setq emcps-http-current-server nil))))

(provide 'emcps-http)

;;; emcps-http.el ends here
