;;; emcps-tools.el --- Tool registry for Emacs MCP servers -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: emcps
;; Keywords: tools, ai, mcp
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:

;; A tiny registry for one-shot MCP tools.  The public tool shape mirrors the
;; gptel/llm tool plist where practical: :name, :function, :description, :args,
;; :category, :confirm and :async.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'jsonrpc)

(cl-defstruct (emcps-tool
               (:constructor emcps-tools--make-tool
                             (&key name function description args category
                                   confirm async include)))
  name function description args category confirm async include)

(defun emcps-tools--preprocess-tool-args (spec)
  "Convert symbol :type values in tool argument SPEC to strings.
This follows gptel's tool argument normalization so callers can use the
same argument plists they would pass to `gptel-make-tool'."
  (when (or (listp spec) (vectorp spec))
    (cond
     ((vectorp spec)
      (cl-loop for element across spec
               for index from 0
               do (aset spec index (emcps-tools--preprocess-tool-args element))))
     ((keywordp (car spec))
      (let ((tail spec))
        (while tail
          (when (and (eq (car tail) :type) (symbolp (cadr tail)))
            (setcar (cdr tail) (symbol-name (cadr tail))))
          (when (or (listp (cadr tail)) (vectorp (cadr tail)))
            (emcps-tools--preprocess-tool-args (cadr tail)))
          (setq tail (cddr tail)))))
     ((listp spec)
      (dolist (element spec)
        (when (listp element)
          (emcps-tools--preprocess-tool-args element))))))
  spec)

(cl-defun emcps-make-tool (&key name function description args category
                                confirm async include &allow-other-keys)
  "Make an EMCPS tool.
The supported keyword arguments mirror `gptel-make-tool':

NAME is the MCP tool name, typically snake_case.
FUNCTION is the Elisp function to call.
DESCRIPTION describes the tool for the model.
ARGS is a list of argument plists.  Each arg uses :name, :type and
:description, with optional :optional, :enum, :items and :properties.
CATEGORY, CONFIRM, ASYNC and INCLUDE are accepted for compatibility.

This function only constructs the tool.  Use `emcps-register-tool' to
expose it from the server."
  (emcps-tools--preprocess-tool-args args)
  (emcps-tools--make-tool
   :name name
   :function function
   :description description
   :args args
   :category (or category "misc")
   :confirm confirm
   :async async
   :include include))

(defvar emcps-tools--registry (make-hash-table :test #'equal)
  "Registered MCP tools keyed by tool name.")

(defun emcps-tools-clear ()
  "Remove all registered tools."
  (clrhash emcps-tools--registry))

(defun emcps-tools--plist-tool-p (value)
  "Return non-nil when VALUE looks like a tool plist."
  (and (listp value)
       (keywordp (car value))
       (plist-get value :name)
       (plist-get value :function)))

(defun emcps-tools-coerce (tool)
  "Coerce TOOL into an `emcps-tool' object.
TOOL may already be an `emcps-tool' or a gptel-style plist accepted by
`emcps-make-tool'.  Optional integrations such as gptel object conversion
live outside core."
  (cond
   ((emcps-tool-p tool) tool)
   ((emcps-tools--plist-tool-p tool)
    (apply #'emcps-make-tool tool))
   (t
    (signal 'wrong-type-argument (list 'emcps-tool tool)))))

(defun emcps-register-tool (tool)
  "Register TOOL and return the coerced `emcps-tool'."
  (let ((coerced (emcps-tools-coerce tool)))
    (unless (stringp (emcps-tool-name coerced))
      (error "Tool name must be a string"))
    (unless (functionp (emcps-tool-function coerced))
      (error "Tool function for %s is not callable" (emcps-tool-name coerced)))
    (when (emcps-tool-async coerced)
      (error "Async tools are not supported in the MVP: %s"
             (emcps-tool-name coerced)))
    (puthash (emcps-tool-name coerced) coerced emcps-tools--registry)
    coerced))

(defun emcps-register-tools (tools)
  "Register each tool in TOOLS."
  (mapcar #'emcps-register-tool tools))

(defun emcps-get-tool (name)
  "Return registered tool named NAME, or nil."
  (gethash name emcps-tools--registry))

(defun emcps-list-tools ()
  "Return registered tools sorted by name."
  (let (tools)
    (maphash (lambda (_ tool) (push tool tools)) emcps-tools--registry)
    (sort tools (lambda (a b)
                  (string< (emcps-tool-name a)
                           (emcps-tool-name b))))))

(defun emcps-tools--json-type (type)
  "Convert gptel/llm TYPE into a JSON Schema type string."
  (cond
   ((symbolp type) (symbol-name type))
   ((stringp type) type)
   ((null type) "string")
   (t (format "%s" type))))

(defun emcps-tools--arg-schema (arg)
  "Return JSON Schema plist for ARG plist.
This mirrors gptel's own tool-schema conversion, adjusted to return MCP's
`inputSchema' instead of an OpenAI-style function wrapper."
  (let ((schema (copy-sequence arg)))
    (cl-remf schema :name)
    (cl-remf schema :optional)
    (when (plist-member schema :type)
      (plist-put schema :type (emcps-tools--json-type (plist-get schema :type))))
    (when (and (equal (plist-get schema :type) "object")
               (not (plist-member schema :required)))
      (plist-put schema :required []))
    (plist-put schema :additionalProperties :json-false)
    schema))

(defun emcps-tools--property-key (name)
  "Return JSON object key symbol for property NAME."
  (if (keywordp name)
      name
    (make-symbol (concat ":" name))))

(defun emcps-tool-input-schema (tool)
  "Return MCP inputSchema for TOOL."
  (if-let* ((args (emcps-tool-args tool)))
      (let (properties required)
        (dolist (arg args)
          (let ((name (plist-get arg :name)))
            (unless (or (stringp name) (keywordp name))
              (error "Tool argument name must be a string or keyword"))
            (setq properties
                  (append properties
                          (list (emcps-tools--property-key name)
                                (emcps-tools--arg-schema arg))))
            (unless (plist-get arg :optional)
              (push name required))))
        `(:type "object"
          :properties ,properties
          :required ,(vconcat (nreverse required))
          :additionalProperties :json-false))
    '(:type "object" :properties nil :additionalProperties :json-false)))

(defun emcps-tool-descriptor (tool)
  "Return MCP descriptor for TOOL."
  `(:name ,(emcps-tool-name tool)
    :description ,(or (emcps-tool-description tool) "")
    :inputSchema ,(emcps-tool-input-schema tool)))

(defun emcps-tool-descriptors ()
  "Return MCP descriptors for all registered tools as a vector."
  (vconcat (mapcar #'emcps-tool-descriptor (emcps-list-tools))))

(defun emcps-tools--keyword-for-name (name)
  "Return plist keyword for JSON object field NAME."
  (if (keywordp name)
      name
    (intern (concat ":" name))))

(defun emcps-tools--arg-value (arguments name)
  "Return value from ARGUMENTS object for argument NAME."
  (cond
   ((hash-table-p arguments) (gethash name arguments))
   ((listp arguments) (plist-get arguments (emcps-tools--keyword-for-name name)))
   (t nil)))

(defun emcps-tools--arg-present-p (arguments name)
  "Return non-nil if ARGUMENTS object contains argument NAME."
  (let ((missing (make-symbol "missing")))
    (cond
     ((hash-table-p arguments)
      (not (eq (gethash name arguments missing) missing)))
     ((listp arguments)
      (plist-member arguments (emcps-tools--keyword-for-name name)))
     (t nil))))

(defun emcps-call-tool (name arguments)
  "Call registered tool NAME with JSON object ARGUMENTS."
  (let ((tool (emcps-get-tool name)))
    (unless tool
      (jsonrpc-error :code -32602 :message (format "Unknown tool: %s" name)))
    (let ((values
           (mapcar
            (lambda (arg)
              (let* ((arg-name (plist-get arg :name))
                     (value (emcps-tools--arg-value arguments arg-name)))
                (when (and (not (emcps-tools--arg-present-p arguments arg-name))
                           (not (plist-get arg :optional)))
                  (jsonrpc-error
                   :code -32602
                   :message (format "Missing required tool argument: %s" arg-name)))
                value))
            (emcps-tool-args tool))))
      (apply (emcps-tool-function tool) values))))

(provide 'emcps-tools)

;;; emcps-tools.el ends here
