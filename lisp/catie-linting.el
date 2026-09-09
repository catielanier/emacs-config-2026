;;; catie-linting.el --- ESLint integration -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; ESLint language server
;; ---------------------------------------------------------------------------

(use-package lsp-eslint
  :ensure nil
  :after lsp-mode

  :custom

  ;; Enable ESLint alongside the primary JS/TS language server.
  (lsp-eslint-enable t)

  ;; Validate continuously while editing.
  (lsp-eslint-run "onType")

  ;; Do NOT silently rewrite files on save.
  ;;
  ;; We want diagnostics and explicit fixes first.  Formatting-on-save will be
  ;; handled separately by the project's actual formatter configuration.
  (lsp-eslint-auto-fix-on-save nil)

  ;; ESLint is not our formatter.
  ;;
  ;; Prettier/project formatting gets its own layer next.
  (lsp-eslint-format nil)

  ;; Keep warnings visible.
  (lsp-eslint-quiet nil)

  ;; Do not nag about intentionally ignored files.
  (lsp-eslint-warn-on-ignored-files nil)

  ;; Project-local ESLint is preferred automatically by lsp-eslint.
  ;;
  ;; Keep npm as the package-manager protocol for the current work setup.
  (lsp-eslint-package-manager "npm"))


;; ---------------------------------------------------------------------------
;; Explicit ESLint commands
;; ---------------------------------------------------------------------------

(defun catie/eslint-fix ()
  "Run the ESLint fix-all code action for the current buffer."

  (interactive)

  (unless (bound-and-true-p lsp-mode)
    (user-error "LSP is not active in this buffer"))

  (lsp-eslint-apply-all-fixes))


(defun catie/eslint-restart ()
  "Restart LSP for the current buffer.

Useful after changing ESLint configuration or dependencies."

  (interactive)

  (lsp-workspace-restart))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  "e f"
  '(catie/eslint-fix
    :which-key "ESLint fix all")

  "e r"
  '(catie/eslint-restart
    :which-key "restart LSP"))


(provide 'catie-linting)

;;; catie-linting.el ends here
