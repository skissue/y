;;; emcps-test.el --- Tests for emcps -*- lexical-binding: t; -*-

(add-to-list 'load-path (expand-file-name ".." (file-name-directory load-file-name)))

(require 'ert)
(require 'url)
(require 'emcps)

(defun emcps-test--plist-get-by-name (plist name)
  "Return value from PLIST whose key has symbol NAME."
  (cl-loop for (key value) on plist by #'cddr
           when (and (symbolp key) (equal (symbol-name key) name))
           return value))

(ert-deftest emcps-tool-schema-from-gptel-like-plist ()
  (let* ((tool (emcps-tools-coerce
                '(:name "read_buffer"
                  :function ignore
                  :description "Read a buffer."
                  :args ((:name "buffer" :type string :description "Buffer name.")
                         (:name "limit" :type integer :description "Limit." :optional t)))))
         (schema (emcps-tool-input-schema tool))
         (properties (plist-get schema :properties)))
    (should (equal (plist-get schema :type) "object"))
    (should (equal (plist-get (emcps-test--plist-get-by-name properties ":buffer")
                              :type)
                   "string"))
    (should (eq (plist-get schema :additionalProperties) :json-false))
    (should (equal (plist-get schema :required) ["buffer"]))))

(ert-deftest emcps-make-tool-preprocesses-gptel-style-args ()
  (let* ((tool (emcps-make-tool
                :name "collect"
                :function #'identity
                :description "Collect values."
                :args '((:name "items"
                         :type array
                         :items (:type string)
                         :description "Items.")
                        (:name "metadata"
                         :type object
                         :properties (:enabled (:type boolean))
                         :description "Metadata."))))
         (items (car (emcps-tool-args tool)))
         (metadata (cadr (emcps-tool-args tool))))
    (should (equal (plist-get items :type) "array"))
    (should (equal (plist-get (plist-get items :items) :type) "string"))
    (should (equal (plist-get metadata :type) "object"))
    (should (equal (plist-get (plist-get (plist-get metadata :properties)
                                         :enabled)
                              :type)
                   "boolean"))))

(ert-deftest emcps-jsonrpc-tools-call ()
  (let ((tools
         (list
          (emcps-make-tool
           :name "echo"
           :function #'identity
           :description "Echo text."
           :args '((:name "text" :type string :description "Text."))))))
    (let* ((handled (emcps-jsonrpc-handle
                     '(:jsonrpc "2.0"
                       :id 1
                       :method "tools/call"
                       :params (:name "echo" :arguments (:text "hello")))
                     tools))
           (response (plist-get handled :response))
           (result (plist-get response :result))
           (content (plist-get result :content)))
      (should (equal (plist-get response :id) 1))
      (should (equal (plist-get (aref content 0) :text) "hello")))))

(ert-deftest emcps-tools-ensure-accepts-async-tools ()
  (let ((tools
         (emcps-tools-ensure
          (list
           (emcps-make-tool
            :name "later"
            :function (lambda (_callback) nil)
            :description "Async tool."
            :args nil
            :async t)))))
    (should (emcps-tool-async (emcps-get-tool tools "later")))))

(ert-deftest emcps-jsonrpc-async-tool-immediate-callback ()
  (let ((tools
         (list
          (emcps-make-tool
           :name "now"
           :function (lambda (callback)
                       (funcall callback "immediate"))
           :description "Immediate async tool."
           :args nil
           :async t))))
    (let* ((handled (emcps-jsonrpc-handle
                     '(:jsonrpc "2.0"
                       :id 1
                       :method "tools/call"
                       :params (:name "now" :arguments ()))
                     tools))
           (response (plist-get handled :response))
           (content (plist-get (plist-get response :result) :content)))
      (should (equal (plist-get (aref content 0) :text) "immediate"))
      (should (eq (plist-get (plist-get response :result) :isError)
                  :json-false)))))

(ert-deftest emcps-jsonrpc-async-tool-delayed-callback ()
  (let ((tools
         (list
          (emcps-make-tool
           :name "later"
           :function (lambda (callback)
                       (run-at-time 0.01 nil
                                    (lambda ()
                                      (funcall callback "delayed"))))
           :description "Delayed async tool."
           :args nil
           :async t))))
    (let* ((handled (emcps-jsonrpc-handle
                     '(:jsonrpc "2.0"
                       :id 1
                       :method "tools/call"
                       :params (:name "later" :arguments ()))
                     tools))
           (deferred (plist-get handled :deferred))
           (response-getter (plist-get handled :response-getter)))
      (should deferred)
      (while (not (emcps-deferred-done deferred))
        (accept-process-output nil 0.02))
      (let* ((response (funcall response-getter))
             (content (plist-get (plist-get response :result) :content)))
        (should (equal (plist-get (aref content 0) :text) "delayed"))
        (should (eq (plist-get (plist-get response :result) :isError)
                    :json-false))))))

(ert-deftest emcps-jsonrpc-async-tool-double-callback-ignored ()
  (let ((tools
         (list
          (emcps-make-tool
           :name "twice"
           :function (lambda (callback)
                       (funcall callback "first")
                       (funcall callback "second"))
           :description "Double callback async tool."
           :args nil
           :async t))))
    (let* ((handled (emcps-jsonrpc-handle
                     '(:jsonrpc "2.0"
                       :id 1
                       :method "tools/call"
                       :params (:name "twice" :arguments ()))
                     tools))
           (response (plist-get handled :response))
           (content (plist-get (plist-get response :result) :content)))
      (should (equal (plist-get (aref content 0) :text) "first")))))

(ert-deftest emcps-jsonrpc-async-tool-timeout-ignores-late-callback ()
  (let (saved-callback)
    (let ((tools
           (list
            (emcps-make-tool
             :name "timeout"
             :function (lambda (callback)
                         (setq saved-callback callback))
             :description "Timeout async tool."
             :args nil
             :async t)))
          (emcps-tool-timeout 0.01))
      (let* ((handled (emcps-jsonrpc-handle
                       '(:jsonrpc "2.0"
                         :id 1
                         :method "tools/call"
                         :params (:name "timeout" :arguments ()))
                       tools))
             (deferred (plist-get handled :deferred))
             (response-getter (plist-get handled :response-getter)))
        (while (not (emcps-deferred-done deferred))
          (accept-process-output nil 0.02))
        (let* ((timeout-response (funcall response-getter))
               (timeout-result (plist-get timeout-response :result))
               (timeout-content (plist-get timeout-result :content)))
          (should (eq (plist-get timeout-result :isError) t))
          (should (string-match-p "timed out"
                                  (plist-get (aref timeout-content 0) :text)))
          (funcall saved-callback "too late")
          (let* ((late-response (funcall response-getter))
                 (late-content (plist-get (plist-get late-response :result)
                                          :content)))
            (should (equal (plist-get (aref late-content 0) :text)
                           (plist-get (aref timeout-content 0) :text)))))))))

(ert-deftest emcps-jsonrpc-tool-errors-return-call-tool-error-result ()
  (let ((tools
         (list
          (emcps-make-tool
           :name "fail"
           :function (lambda ()
                       (error "boom from tool"))
           :description "Fail."
           :args nil))))
    (let* ((handled (emcps-jsonrpc-handle
                     '(:jsonrpc "2.0"
                       :id 1
                       :method "tools/call"
                       :params (:name "fail" :arguments ()))
                     tools))
           (response (plist-get handled :response))
           (result (plist-get response :result))
           (content (plist-get result :content)))
      (should (equal (plist-get response :id) 1))
      (should-not (plist-member response :error))
      (should (eq (plist-get result :isError) t))
      (should (string-match-p "boom from tool"
                              (plist-get (aref content 0) :text))))))

(defvar emcps-test-state nil
  "State mutated by test tools.")

(ert-deftest emcps-jsonrpc-tool-can-modify-emacs-state ()
  (let ((emcps-test-state nil))
    (let ((tools
           (list
            (emcps-make-tool
             :name "set_state"
             :function (lambda (value)
                         (setq emcps-test-state value)
                         (format "state set to %s" value))
             :description "Set test state."
             :args '((:name "value" :type string :description "Value.")))
            (emcps-make-tool
             :name "get_state"
             :function (lambda () emcps-test-state)
             :description "Get test state."
             :args nil))))
      (emcps-jsonrpc-handle
       '(:jsonrpc "2.0"
         :id 1
         :method "tools/call"
         :params (:name "set_state" :arguments (:value "persisted")))
       tools)
      (should (equal emcps-test-state "persisted"))
      (let* ((handled (emcps-jsonrpc-handle
                       '(:jsonrpc "2.0"
                         :id 2
                         :method "tools/call"
                         :params (:name "get_state" :arguments ()))
                       tools))
             (content (plist-get (plist-get (plist-get handled :response)
                                            :result)
                                 :content)))
        (should (equal (plist-get (aref content 0) :text) "persisted"))))))

(ert-deftest emcps-jsonrpc-notification-has-no-response ()
  (let* ((handled (emcps-jsonrpc-handle
                   '(:jsonrpc "2.0"
                     :method "notifications/initialized")))
         (response (plist-get handled :response)))
    (should-not response)))

(ert-deftest emcps-jsonrpc-initialize-negotiates-requested-version ()
  (let* ((handled (emcps-jsonrpc-handle
                   '(:jsonrpc "2.0"
                     :id 1
                     :method "initialize"
                     :params (:protocolVersion "2025-06-18"
                              :capabilities ()
                              :clientInfo (:name "test" :version "0")))))
         (response (plist-get handled :response))
         (result (plist-get response :result)))
    (should (equal (plist-get result :protocolVersion) "2025-06-18"))))

(defun emcps-test--http-post (port body)
  "POST BODY to test server PORT and return decoded JSON response."
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/json")
            ("Accept" . "application/json, text/event-stream")
            ("MCP-Protocol-Version" . "2025-11-25")))
         (url-request-data body)
         (buffer (url-retrieve-synchronously
                  (format "http://127.0.0.1:%s/mcp" port)
                  t t 5)))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (re-search-forward "\r?\n\r?\n")
          (emcps-json-parse-string
           (buffer-substring-no-properties (point) (point-max))))
      (when (buffer-live-p buffer)
        (kill-buffer buffer)))))

(ert-deftest emcps-http-integration-tools-list ()
  (let (server)
    (unwind-protect
        (let ((tools
               (list
                (emcps-make-tool
                 :name "echo"
                 :function #'identity
                 :description "Echo text."
                 :args '((:name "text" :type string :description "Text."))))))
          (setq server (emcps-start-server :port t :tools tools))
          (let* ((response (emcps-test--http-post
                            (emcps-server-port server)
                            "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}"))
                 (listed-tools (plist-get (plist-get response :result) :tools)))
            (should (equal (plist-get response :id) 1))
            (should (= (length listed-tools) 1))
            (should (equal (plist-get (car listed-tools) :name) "echo"))))
      (when server (emcps-stop-server server)))))

(ert-deftest emcps-http-integration-async-tool-waits-for-callback ()
  (let (server)
    (unwind-protect
        (let ((tools
               (list
                (emcps-make-tool
                 :name "async_echo"
                 :function (lambda (callback text)
                             (run-at-time 0.01 nil
                                          (lambda ()
                                            (funcall callback text))))
                 :description "Async echo."
                 :args '((:name "text" :type string :description "Text."))
                 :async t))))
          (setq server (emcps-start-server :port t :tools tools))
          (let* ((response (emcps-test--http-post
                            (emcps-server-port server)
                            "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"async_echo\",\"arguments\":{\"text\":\"over http\"}}}"))
                 (result (plist-get response :result))
                 (content (plist-get result :content)))
            (should (equal (plist-get response :id) 1))
            (should (eq (plist-get result :isError) :json-false))
            (should (equal (plist-get (car content) :text)
                           "over http"))))
      (when server (emcps-stop-server server)))))

(ert-deftest emcps-http-servers-own-independent-tool-lists ()
  (let (server-a server-b)
    (unwind-protect
        (let ((tools-a
               (list
                (emcps-make-tool
                 :name "only_a"
                 :function (lambda () "a")
                 :description "Server A only."
                 :args nil)))
              (tools-b
               (list
                (emcps-make-tool
                 :name "only_b"
                 :function (lambda () "b")
                 :description "Server B only."
                 :args nil))))
          (setq server-a (emcps-start-server :port t :tools tools-a))
          (setq server-b (emcps-start-server :port t :tools tools-b))
          (let* ((response-a (emcps-test--http-post
                              (emcps-server-port server-a)
                              "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}"))
                 (response-b (emcps-test--http-post
                              (emcps-server-port server-b)
                              "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}"))
                 (listed-a (plist-get (plist-get response-a :result) :tools))
                 (listed-b (plist-get (plist-get response-b :result) :tools)))
            (should (= (length listed-a) 1))
            (should (= (length listed-b) 1))
            (should (equal (plist-get (car listed-a) :name) "only_a"))
            (should (equal (plist-get (car listed-b) :name) "only_b"))
            (let* ((call-a (emcps-test--http-post
                            (emcps-server-port server-a)
                            "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"only_b\",\"arguments\":{}}}"))
                   (error-a (plist-get call-a :error)))
              (should (equal (plist-get error-a :code) -32602)))))
      (when server-a (emcps-stop-server server-a))
      (when server-b (emcps-stop-server server-b)))))

(ert-deftest emcps-http-rejects-get ()
  (let (server)
    (unwind-protect
        (progn
          (setq server (emcps-start-server :port t))
          (let ((buffer (url-retrieve-synchronously
                         (format "http://127.0.0.1:%s/mcp"
                                 (emcps-server-port server))
                         t t 5)))
            (unwind-protect
                (with-current-buffer buffer
                  (goto-char (point-min))
                  (should (looking-at "HTTP/[0-9.]+ 405")))
              (when (buffer-live-p buffer)
                (kill-buffer buffer)))))
      (when server (emcps-stop-server server)))))

(ert-deftest emcps-http-rejects-non-json-content-type ()
  (let (server)
    (unwind-protect
        (progn
          (setq server (emcps-start-server :port t))
          (let* ((url-request-method "POST")
                 (url-request-extra-headers
                  '(("Content-Type" . "text/plain")
                    ("Accept" . "application/json, text/event-stream")
                    ("MCP-Protocol-Version" . "2025-11-25")))
                 (url-request-data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}")
                 (buffer (url-retrieve-synchronously
                          (format "http://127.0.0.1:%s/mcp"
                                  (emcps-server-port server))
                          t t 5)))
            (unwind-protect
                (with-current-buffer buffer
                  (goto-char (point-min))
                  (should (looking-at "HTTP/[0-9.]+ 400"))
                  (re-search-forward "\r?\n\r?\n")
                  (let ((response (emcps-json-parse-string
                                   (buffer-substring-no-properties
                                    (point) (point-max)))))
                    (should (string-match-p
                             "Content-Type"
                             (plist-get (plist-get response :error)
                                        :message)))))
              (when (buffer-live-p buffer)
                (kill-buffer buffer)))))
      (when server (emcps-stop-server server)))))

(provide 'emcps-test)

;;; emcps-test.el ends here
