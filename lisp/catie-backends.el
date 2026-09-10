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
;;; catie-backends.el --- Backend language support -*- lexical-binding: t; -*-

(require 'lsp-mode)
(require 'subr-x)
(require 'treesit)


;; ---------------------------------------------------------------------------
;; Shared helpers
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


;; lsp-mode's Go installer uses `go install`, so the result may land outside
;; Emacs' exec-path.  Resolve it directly from the Go environment.
(when-let ((gopls
            (catie/gopls-path)))

  (setq lsp-go-gopls-server-path
        gopls))


;; Use standard Go formatting rather than imposing gofumpt.
(setq lsp-go-use-gofumpt
      nil)

(setq lsp-go-use-placeholders
      t)

(setq lsp-go-complete-function-calls
      t)


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

  ;; Formatting deliberately NOT enabled here.
  ;;
  ;; Python repositories may use Ruff, Black, etc.  We will obey the
  ;; repository rather than impose one globally.
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


;; Do not let Intelephense impose formatting.
(setq lsp-intelephense-format-enable
      nil)

(setq lsp-intelephense-completion-insert-use-declaration
      t)

(setq lsp-intelephense-telemetry-enabled
      nil)


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
;; C#
;; ===========================================================================

;; csharp-mode/csharp-ts-mode are built into modern Emacs.
(require 'csharp-mode)

;; Use Microsoft's current Roslyn language server rather than OmniSharp or
;; csharp-ls.
(require 'lsp-roslyn)


(defun catie/csharp-setup ()
  "Configure a C# buffer."

  ;; Several C# clients are registered by lsp-mode.  Pin this buffer to the
  ;; modern Microsoft Roslyn server so lsp-mode never has to guess.
  (setq-local lsp-enabled-clients
              '(csharp-roslyn))

  ;; Do not add format-on-save here.  Formatting policy should come from the
  ;; actual .NET repository.
  (lsp))


(add-to-list
 'auto-mode-alist
 '("\\.cs\\'" . csharp-ts-mode))


(add-hook
 'csharp-ts-mode-hook
 #'catie/csharp-setup)


;; ===========================================================================
;; Kotlin
;; ===========================================================================

;; kotlin-ts-mode uses fwcd's tree-sitter-kotlin grammar.
(add-to-list
 'treesit-language-source-alist

 '(kotlin
   "https://github.com/fwcd/tree-sitter-kotlin"))


(use-package kotlin-ts-mode
  :ensure t

  :mode
  (("\\.kt\\'"  . kotlin-ts-mode)
   ("\\.kts\\'" . kotlin-ts-mode)))


(require 'lsp-kotlin)


;; We're not using snippets yet.
(setq lsp-kotlin-completion-snippets-enabled
      nil)

;; Don't create dependency caches inside repositories.
(setq lsp-kotlin-ondisk-cache-enabled
      nil)


(defun catie/kotlin-setup ()
  "Configure a Kotlin buffer."

  (setq-local lsp-enabled-clients
              '(kotlin-ls))

  ;; No global ktlint/format-on-save policy.
  (lsp))


(add-hook
 'kotlin-ts-mode-hook
 #'catie/kotlin-setup)


;; ===========================================================================
;; SQL
;; ===========================================================================

(require 'sql)
(require 'lsp-sql)


(defun catie/sql-setup ()
  "Configure a SQL buffer."

  ;; Use the generic SQL language server.
  (setq-local lsp-enabled-clients
              '(sql-ls))

  ;; Do NOT configure database credentials here.
  ;;
  ;; Database-specific completion can later use a private sql-language-server
  ;; configuration/environment variables rather than committing secrets to
  ;; the Emacs repo.
  (lsp))


(add-to-list
 'auto-mode-alist
 '("\\.sql\\'" . sql-mode))


(add-hook
 'sql-mode-hook
 #'catie/sql-setup)


;; ===========================================================================
;; Leader
;; ===========================================================================

(catie/leader

  "c B"
  '(catie/backend-status
    :which-key "backend status"))


(provide 'catie-backends)

;;; catie-backends.el ends here
