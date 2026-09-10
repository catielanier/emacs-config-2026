;;; catie-backends.el --- Go, Python and PHP support -*- lexical-binding: t; -*-

(require 'lsp-mode)
(require 'subr-x)


;; ---------------------------------------------------------------------------
;; Helpers
;; ---------------------------------------------------------------------------

(defun catie/backend-lsp-servers ()
  "Return the LSP server IDs attached to the current buffer."

  (when (bound-and-true-p lsp-mode)

    (mapcar
     (lambda (workspace)

       (lsp--client-server-id
        (lsp--workspace-client workspace)))

     (lsp-workspaces))))


(defun catie/backend-status ()
  "Show backend language/editor status for the current buffer."

  (interactive)

  (message
   "Mode: %s | LSP: %S | Tree-sitter: %S"
   major-mode
   (catie/backend-lsp-servers)

   (when (fboundp 'treesit-parser-list)
     (mapcar
      #'treesit-parser-language
      (treesit-parser-list)))))


;; ===========================================================================
;; Go
;; ===========================================================================

(require 'go-ts-mode)
(require 'lsp-go)


(defun catie/go-env (name)
  "Return the value of Go environment variable NAME."

  (when (executable-find "go")

    (with-temp-buffer

      (when
          (zerop
           (call-process
            "go"
            nil
            t
            nil
            "env"
            name))

        (string-trim
         (buffer-string))))))


(defun catie/go-bin-directory ()
  "Return the directory where `go install' places executables."

  (let ((gobin
         (catie/go-env "GOBIN")))

    (if
        (and gobin
             (not
              (string-empty-p gobin)))

        gobin

      (when-let ((gopath
                  (catie/go-env "GOPATH")))

        (expand-file-name
         "bin"
         gopath)))))


(defun catie/gopls-path ()
  "Return the expected absolute path to gopls."

  (when-let ((bin
              (catie/go-bin-directory)))

    (expand-file-name
     "gopls"
     bin)))


;; lsp-mode installs gopls using:
;;
;;     go install golang.org/x/tools/gopls@latest
;;
;; That writes into GOBIN or GOPATH/bin, which is not guaranteed to be in
;; Emacs' exec-path.  Point lsp-mode directly at the exact installation path.
(when-let ((gopls
            (catie/gopls-path)))

  (setq lsp-go-gopls-server-path
        gopls))


;; Standard gofmt behavior, not gofumpt.
(setq lsp-go-use-gofumpt nil)

;; Good IDE-style completion behavior.
(setq lsp-go-use-placeholders t
      lsp-go-complete-function-calls t)


(defun catie/go-format-before-save ()
  "Format a Go buffer through gopls before saving."

  (when
      (and
       (derived-mode-p 'go-ts-mode)
       (bound-and-true-p lsp-mode)
       (lsp-workspaces))

    (lsp-format-buffer)))


(defun catie/go-setup ()
  "Configure a Go buffer."

  (setq-local lsp-enabled-clients
              '(gopls))

  ;; Go convention.
  (setq-local indent-tabs-mode
              t)

  (add-hook
   'before-save-hook
   #'catie/go-format-before-save
   nil
   t)

  (lsp))


(use-package go-ts-mode
  :ensure nil

  :mode
  ("\\.go\\'" . go-ts-mode)

  :hook
  (go-ts-mode . catie/go-setup))


;; ===========================================================================
;; Python
;; ===========================================================================

(use-package lsp-pyright
  :ensure t
  :after lsp-mode

  :custom

  (lsp-pyright-langserver-command
   "pyright")

  (lsp-pyright-type-checking-mode
   "standard")

  (lsp-pyright-diagnostic-mode
   "openFilesOnly")

  (lsp-pyright-auto-import-completions
   t)

  (lsp-pyright-auto-search-paths
   t))


(defun catie/python-setup ()
  "Configure a Python buffer."

  (require 'lsp-pyright)

  (setq-local lsp-enabled-clients
              '(pyright))

  (lsp))


(use-package python
  :ensure nil

  :mode
  ("\\.py\\'" . python-ts-mode)

  :hook
  (python-ts-mode . catie/python-setup))


;; ===========================================================================
;; PHP
;; ===========================================================================

(require 'php-ts-mode)
(require 'lsp-php)


(setq lsp-intelephense-format-enable nil)

(setq lsp-intelephense-completion-insert-use-declaration t)

(setq lsp-intelephense-telemetry-enabled nil)


(defun catie/php-setup ()
  "Configure a PHP buffer."

  (setq-local lsp-enabled-clients
              '(iph))

  (lsp))


(use-package php-ts-mode
  :ensure nil

  :mode
  (("\\.php\\'"   . php-ts-mode)
   ("\\.phtml\\'" . php-ts-mode))

  :hook
  (php-ts-mode . catie/php-setup))


;; ===========================================================================
;; Leader
;; ===========================================================================

(catie/leader

  "c B"
  '(catie/backend-status
    :which-key "backend status"))


(provide 'catie-backends)

;;; catie-backends.el ends here
