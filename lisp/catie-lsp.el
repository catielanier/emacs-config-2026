;;; catie-lsp.el --- Language Server Protocol configuration -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; Flycheck
;; ---------------------------------------------------------------------------

(use-package flycheck
  :ensure t

  :init
  (global-flycheck-mode 1))


;; ---------------------------------------------------------------------------
;; lsp-mode
;; ---------------------------------------------------------------------------

(use-package lsp-mode
  :ensure t

  :commands
  (lsp
   lsp-deferred
   lsp-install-server
   lsp-find-definition
   lsp-find-references
   lsp-rename
   lsp-execute-code-action
   lsp-describe-thing-at-point)

  :hook
  ((js-ts-mode         . lsp)
   (typescript-ts-mode . lsp)
   (tsx-ts-mode        . lsp))

  :init

  ;; -------------------------------------------------------------------------
  ;; Performance
  ;; ---------------------------------------------------------------------------

  (setq read-process-output-max
        (* 1024 1024))

  (setq gc-cons-threshold
        100000000)


  ;; -------------------------------------------------------------------------
  ;; TypeScript
  ;; ---------------------------------------------------------------------------
  ;;
  ;; IMPORTANT:
  ;;
  ;; Prefer the TypeScript installation belonging to the project itself.
  ;;
  ;; This:
  ;;
  ;;   1. avoids lsp-mode's current macOS bug where its managed TypeScript
  ;;      installation is not found correctly;
  ;;
  ;;   2. means each repo uses the TypeScript version it was actually built
  ;;      and tested against;
  ;;
  ;;   3. does not write or modify anything in the repository.

  (setq lsp-clients-typescript-prefer-use-project-ts-server t)


  ;; -------------------------------------------------------------------------
  ;; Completion / diagnostics
  ;; ---------------------------------------------------------------------------

  ;; Corfu consumes completion-at-point.
  (setq lsp-completion-provider
        :capf)

  ;; Flycheck is our diagnostics frontend.
  (setq lsp-diagnostics-provider
        :flycheck)

  ;; No snippet engine yet.
  (setq lsp-enable-snippet
        nil)


  ;; -------------------------------------------------------------------------
  ;; IDE behavior
  ;; ---------------------------------------------------------------------------

  (setq lsp-enable-symbol-highlighting
        t)

  (setq lsp-signature-auto-activate
        t)

  (setq lsp-signature-render-documentation
        t)

  (setq lsp-eldoc-enable-hover
        t)


  ;; -------------------------------------------------------------------------
  ;; UI
  ;; ---------------------------------------------------------------------------

  (setq lsp-headerline-breadcrumb-enable
        nil)

  (setq lsp-modeline-code-actions-enable
        t)

  (setq lsp-modeline-diagnostics-enable
        t)

  (setq lsp-modeline-workspace-status-enable
        t)


  ;; -------------------------------------------------------------------------
  ;; Workspace behavior
  ;; ---------------------------------------------------------------------------

  (setq lsp-keep-workspace-alive
        nil)

  (setq lsp-auto-guess-root
        nil)

  (setq lsp-response-timeout
        10)

  ;; Do not set `lsp-use-plists` here.
  )


;; ---------------------------------------------------------------------------
;; lsp-ui
;; ---------------------------------------------------------------------------

(use-package lsp-ui
  :ensure t
  :after lsp-mode

  :commands
  lsp-ui-mode

  :custom

  (lsp-ui-sideline-enable t)

  (lsp-ui-sideline-show-diagnostics t)

  (lsp-ui-sideline-show-hover nil)

  (lsp-ui-sideline-show-code-actions t)

  (lsp-ui-sideline-delay 0.15)

  (lsp-ui-sideline-diagnostic-max-lines 2)

  ;; Terminal-first Emacs: don't use floating child-frame docs.
  (lsp-ui-doc-enable nil)

  (lsp-ui-peek-enable t))


;; ---------------------------------------------------------------------------
;; Consult integration
;; ---------------------------------------------------------------------------

(use-package consult-lsp
  :ensure t
  :after
  (consult lsp-mode)

  :commands
  (consult-lsp-symbols
   consult-lsp-diagnostics))


;; ---------------------------------------------------------------------------
;; LSP navigation
;; ---------------------------------------------------------------------------

(defun catie/lsp-definition ()
  "Jump to the definition of the symbol at point."

  (interactive)

  (lsp-find-definition))


(defun catie/lsp-references ()
  "Show references to the symbol at point."

  (interactive)

  (lsp-find-references))


(defun catie/lsp-documentation ()
  "Show documentation for the symbol at point."

  (interactive)

  (lsp-describe-thing-at-point))


(defun catie/lsp-rename ()
  "Rename the symbol at point across the workspace."

  (interactive)

  (call-interactively
   #'lsp-rename))


(defun catie/lsp-code-action ()
  "Choose an available LSP code action."

  (interactive)

  (lsp-execute-code-action))


;; ---------------------------------------------------------------------------
;; Diagnostics
;; ---------------------------------------------------------------------------

(defun catie/diagnostic-next ()
  "Jump to the next Flycheck diagnostic."

  (interactive)

  (flycheck-next-error))


(defun catie/diagnostic-previous ()
  "Jump to the previous Flycheck diagnostic."

  (interactive)

  (flycheck-previous-error))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  ;; Code
  "c"
  '(:ignore t
    :which-key "code")

  "c d"
  '(catie/lsp-definition
    :which-key "definition")

  "c r"
  '(catie/lsp-references
    :which-key "references")

  "c R"
  '(catie/lsp-rename
    :which-key "rename")

  "c a"
  '(catie/lsp-code-action
    :which-key "code action")

  "c h"
  '(catie/lsp-documentation
    :which-key "documentation")

  "c s"
  '(consult-lsp-symbols
    :which-key "workspace symbols")


  ;; Diagnostics
  "e"
  '(:ignore t
    :which-key "errors")

  "e n"
  '(catie/diagnostic-next
    :which-key "next")

  "e p"
  '(catie/diagnostic-previous
    :which-key "previous")

  "e l"
  '(flycheck-list-errors
    :which-key "list")

  "e w"
  '(consult-lsp-diagnostics
    :which-key "workspace diagnostics"))


(provide 'catie-lsp)

;;; catie-lsp.el ends here
