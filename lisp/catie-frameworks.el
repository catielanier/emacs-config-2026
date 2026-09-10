;;; catie-frameworks.el --- Svelte and Vue support -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; web-mode
;; ---------------------------------------------------------------------------

(use-package web-mode
  :ensure t
  :demand t

  :mode
  (("\\.svelte\\'" . web-mode)
   ("\\.vue\\'"    . web-mode))

  :config

  ;; Tell web-mode which templating engine applies to each file type.
  (add-to-list
   'web-mode-engines-alist
   '("svelte" . "\\.svelte\\'"))

  (add-to-list
   'web-mode-engines-alist
   '("vue" . "\\.vue\\'"))

  ;; Closing HTML/component tags is useful.
  (setq web-mode-enable-auto-closing
        t)

  ;; Smartparens already owns (), [], {}, quotes, etc.
  ;; Don't let web-mode compete with it.
  (setq web-mode-enable-auto-pairing
        nil)

  ;; Avoid surprise quote insertion.
  (setq web-mode-enable-auto-quoting
        nil)

  ;; Useful basic visual support.
  (setq web-mode-enable-css-colorization
        t))


;; ---------------------------------------------------------------------------
;; Language servers
;; ---------------------------------------------------------------------------

;; Both clients are already shipped with lsp-mode.
;;
;; Loading Volar here is important: current Volar integration adds its Vue
;; TypeScript plugin to ts-ls, allowing the two servers to cooperate.
(require 'lsp-svelte)
(require 'lsp-volar)


(defun catie/framework-lsp ()
  "Start the appropriate LSP stack for Svelte and Vue files."

  (when
      (and
       buffer-file-name

       (or
        (string-suffix-p
         ".svelte"
         buffer-file-name)

        (string-suffix-p
         ".vue"
         buffer-file-name)))

    (lsp)))


(add-hook
 'web-mode-hook
 #'catie/framework-lsp)


;; ---------------------------------------------------------------------------
;; Status
;; ---------------------------------------------------------------------------

(defun catie/framework-status ()
  "Show the language servers attached to the current framework buffer."

  (interactive)

  (let ((servers
         (when
             (bound-and-true-p lsp-mode)

           (mapcar
            (lambda (workspace)

              (lsp--client-server-id
               (lsp--workspace-client workspace)))

            (lsp-workspaces)))))

    (message
     "%s | engine: %s | LSP: %S"

     (cond
      ((and buffer-file-name
            (string-suffix-p ".svelte" buffer-file-name))
       "Svelte")

      ((and buffer-file-name
            (string-suffix-p ".vue" buffer-file-name))
       "Vue")

      (t
       "Web"))

     (if
         (boundp 'web-mode-engine)

         web-mode-engine

       "n/a")

     servers)))


(catie/leader

  "c W"
  '(catie/framework-status
    :which-key "web framework status"))


(provide 'catie-frameworks)

;;; catie-frameworks.el ends here
