;;; catie-copilot.el --- GitHub Copilot inline completion -*- lexical-binding: t; -*-


;; ---------------------------------------------------------------------------
;; Safe startup
;; ---------------------------------------------------------------------------

(defun catie/copilot-server-installed-p ()
  "Return non-nil when Copilot's language server is actually installed."

  (and
   ;; Don't explode during initial package installation.
   (require 'copilot nil t)

   (condition-case nil
       (progn
         (copilot-server-executable)
         t)

     (error nil))))


(defun catie/maybe-enable-copilot ()
  "Enable Copilot only when its language server exists.

This prevents Copilot from breaking package compilation during a fresh
Emacs bootstrap before `copilot-install-server' has been run."

  (when
      (catie/copilot-server-installed-p)

    (copilot-mode 1)))


;; ---------------------------------------------------------------------------
;; GitHub Copilot
;; ---------------------------------------------------------------------------

(use-package copilot
  :ensure t

  ;; Do NOT directly hook `copilot-mode' into prog-mode.
  ;;
  ;; Package installation/byte compilation itself opens programming buffers.
  ;; On a new machine that happens before the Copilot language server exists.
  :hook
  (prog-mode . catie/maybe-enable-copilot)

  :config

  ;; -------------------------------------------------------------------------
  ;; Acceptance keys
  ;; -------------------------------------------------------------------------
  ;;
  ;; Match Catie's Neovim setup:
  ;;
  ;;   C-j  -> accept whole suggestion
  ;;   F19  -> accept whole suggestion
  ;;
  ;; TAB / C-TAB / Space do NOT accept Copilot.

  ;; Current copilot.el supplies TAB acceptance by default.
  ;; Remove all of it.
  (keymap-unset
   copilot-completion-map
   "<tab>")

  (keymap-unset
   copilot-completion-map
   "TAB")

  (keymap-unset
   copilot-completion-map
   "C-<tab>")

  (keymap-unset
   copilot-completion-map
   "C-TAB")


  ;; Our acceptance keys.
  (keymap-set
   copilot-completion-map
   "C-j"
   #'copilot-accept-completion)

  (keymap-set
   copilot-completion-map
   "<f19>"
   #'copilot-accept-completion)


  ;; -------------------------------------------------------------------------
  ;; Tree-sitter language IDs
  ;; -------------------------------------------------------------------------

  (dolist
      (mapping
       '(("js-ts"         . "javascript")
         ("typescript-ts" . "typescript")
         ("tsx-ts"        . "typescriptreact")
         ("json-ts"       . "json")
         ("css-ts"        . "css")
         ("html-ts"       . "html")
         ("yaml-ts"       . "yaml")
         ("go-ts"         . "go")
         ("python-ts"     . "python")
         ("php-ts"        . "php")
         ("csharp-ts"     . "csharp")
         ("kotlin-ts"     . "kotlin")))

    (setf
     (alist-get
      (car mapping)
      copilot-major-mode-alist
      nil
      nil
      #'string=)

     (cdr mapping))))


;; ---------------------------------------------------------------------------
;; Svelte / Vue
;; ---------------------------------------------------------------------------

(defun catie/copilot-web-language ()
  "Set Copilot's web-mode language ID from the current filename."

  (when buffer-file-name

    (setq-local
     copilot-major-mode-alist
     (copy-tree
      copilot-major-mode-alist))

    (cond

     ((string-suffix-p
       ".svelte"
       buffer-file-name)

      (setf
       (alist-get
        "web"
        copilot-major-mode-alist
        nil
        nil
        #'string=)

       "svelte"))


     ((string-suffix-p
       ".vue"
       buffer-file-name)

      (setf
       (alist-get
        "web"
        copilot-major-mode-alist
        nil
        nil
        #'string=)

       "vue")))))


(add-hook
 'web-mode-hook
 #'catie/copilot-web-language)


;; ---------------------------------------------------------------------------
;; Controls
;; ---------------------------------------------------------------------------

(defun catie/copilot-status ()
  "Show Copilot status for the current buffer."

  (interactive)

  (message
   "Copilot: %s | server: %s"

   (if
       (bound-and-true-p copilot-mode)

       "enabled"

     "disabled")

   (if
       (catie/copilot-server-installed-p)

       "installed"

     "not installed")))


(catie/leader

  "a"
  '(:ignore t
    :which-key "AI")

  "a c"
  '(copilot-mode
    :which-key "toggle Copilot")

  "a s"
  '(catie/copilot-status
    :which-key "Copilot status"))


(provide 'catie-copilot)

;;; catie-copilot.el ends here
