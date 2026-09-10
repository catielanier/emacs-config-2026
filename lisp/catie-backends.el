;;; catie-backends.el --- Go, Python and PHP support -*- lexical-binding: t; -*-

(require 'lsp-mode)


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

  ;; Do not let some unrelated Go server become the primary client.
  (setq-local lsp-enabled-clients
              '(gopls))

  ;; gofmt convention.
  (setq-local indent-tabs-mode
              t)

  ;; Format only this Go buffer on save.
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

;; Pyright's Emacs client is maintained separately from lsp-mode itself.
(use-package lsp-pyright
  :ensure t
  :after lsp-mode

  :custom

  ;; Use upstream Pyright.
  (lsp-pyright-langserver-command
   "pyright")

  ;; Repositories can override this with pyrightconfig.json/pyproject.toml.
  (lsp-pyright-type-checking-mode
   "standard")

  ;; Don't wastefully analyze every unopened file unless the project asks.
  (lsp-pyright-diagnostic-mode
   "openFilesOnly")

  ;; Yes please.
  (lsp-pyright-auto-import-completions
   t)

  (lsp-pyright-auto-search-paths
   t))


(defun catie/python-setup ()
  "Configure a Python buffer."

  ;; Ensure the Pyright client has actually been loaded before `lsp'.
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


;; Intelephense has its own formatter opinions.
;;
;; We explicitly disable them because PHP formatting must eventually come
;; from the repository's chosen formatter rather than Emacs deciding that
;; everything should be PSR-12.
(setq lsp-intelephense-format-enable nil)

;; Useful IDE behavior.
(setq lsp-intelephense-completion-insert-use-declaration t)

;; Keep telemetry off.
(setq lsp-intelephense-telemetry-enabled nil)


(defun catie/php-setup ()
  "Configure a PHP buffer."

  ;; `iph' is lsp-mode's server ID for Intelephense.
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
