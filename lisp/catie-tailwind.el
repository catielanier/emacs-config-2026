;;; catie-tailwind.el --- Tailwind CSS IntelliSense -*- lexical-binding: t; -*-

;; Tailwind support is built into current lsp-mode.
(require 'lsp-tailwindcss)


;; ---------------------------------------------------------------------------
;; Modes
;; ---------------------------------------------------------------------------

;; lsp-mode's default list doesn't currently include all of the Emacs 31
;; tree-sitter modes we're using, so define ours explicitly.
(setq lsp-tailwindcss-major-modes
      '(js-ts-mode
        typescript-ts-mode
        tsx-ts-mode
        html-ts-mode
        css-ts-mode

        ;; Keep these ready for the next phase.
        web-mode
        svelte-mode
        vue-mode))


;; ---------------------------------------------------------------------------
;; IntelliSense
;; ---------------------------------------------------------------------------

;; Tailwind runs alongside TypeScript rather than replacing it.
(setq lsp-tailwindcss-add-on-mode t)

;; Completion inside class / className attributes.
(setq lsp-tailwindcss-suggestions t)

;; CSS information when hovering a Tailwind class.
(setq lsp-tailwindcss-hovers t)

;; Tailwind diagnostics.
(setq lsp-tailwindcss-validate t)

;; Tailwind code actions.
(setq lsp-tailwindcss-code-actions t)

;; Support Emmet-like Tailwind completion.
;;
;; Example:
;;
;;   div.flex.items-center
;;
(setq lsp-tailwindcss-emmet-completions t)

;; Show the px equivalent when Tailwind reports rem measurements.
;;
;; Example:
;;
;;   1rem → 16px
;;
(setq lsp-tailwindcss-show-pixel-equivalents t)

;; Standard 16px browser root.
(setq lsp-tailwindcss-root-font-size 16)


;; ---------------------------------------------------------------------------
;; Class attributes
;; ---------------------------------------------------------------------------

;; These are the locations where Tailwind IntelliSense should understand
;; class strings.
(setq lsp-tailwindcss-class-attributes
      ["class"
       "className"
       "ngClass"
       "class:list"])


;; ---------------------------------------------------------------------------
;; Do NOT lie about Tailwind projects
;; ---------------------------------------------------------------------------

;; Leave config detection enabled.
;;
;; Tailwind v3 projects need a detectable tailwind.config.*.
;; Tailwind v4 projects are detected from their Tailwind dependency.
;;
;; We don't want the server waking up in every random TSX project.
(setq lsp-tailwindcss-skip-config-check nil)


;; ---------------------------------------------------------------------------
;; Status helper
;; ---------------------------------------------------------------------------

(defun catie/tailwind-status ()
  "Show whether Tailwind LSP is attached to the current buffer."

  (interactive)

  (let ((servers
         (when (bound-and-true-p lsp-mode)
           (mapcar
            (lambda (workspace)
              (lsp--client-server-id
               (lsp--workspace-client workspace)))
            (lsp-workspaces)))))

    (if (memq 'tailwindcss servers)

        (message
         "Tailwind IntelliSense: connected")

      (message
       "Tailwind IntelliSense: not connected | LSP servers: %S"
       servers))))


;; ---------------------------------------------------------------------------
;; Leader binding
;; ---------------------------------------------------------------------------

(catie/leader

  "c t"
  '(catie/tailwind-status
    :which-key "Tailwind status"))


(provide 'catie-tailwind)

;;; catie-tailwind.el ends here
