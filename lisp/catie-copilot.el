;;; catie-copilot.el --- GitHub Copilot inline completion -*- lexical-binding: t; -*-


;; ---------------------------------------------------------------------------
;; GitHub Copilot
;; ---------------------------------------------------------------------------

(use-package copilot
  :ensure t

  ;; Inline suggestions in programming buffers.
  ;;
  ;; Current copilot.el already defaults to only triggering suggestions while
  ;; Evil is in Insert state, which is exactly what we want.
  :hook
  (prog-mode . copilot-mode)

  :config

  ;; -------------------------------------------------------------------------
  ;; Acceptance keys
  ;; -------------------------------------------------------------------------
  ;;
  ;; Match Catie's Neovim configuration exactly:
  ;;
  ;;   C-j  -> accept suggestion
  ;;   F19  -> accept suggestion
  ;;
  ;; TAB, C-TAB and Space must NOT accept Copilot.

  ;; copilot.el ships these acceptance bindings by default.
  ;; Remove them so Corfu / indentation / normal editor behavior keeps TAB.
  (keymap-unset copilot-completion-map "<tab>")
  (keymap-unset copilot-completion-map "TAB")

  (keymap-unset copilot-completion-map "C-<tab>")
  (keymap-unset copilot-completion-map "C-TAB")

  ;; Our actual acceptance keys.
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
  ;;
  ;; copilot.el normally derives the language ID from `major-mode'.
  ;;
  ;; Emacs' tree-sitter mode names don't always correspond directly to the
  ;; language IDs expected by Copilot, so make those mappings explicit.

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
;;
;; Both currently use `web-mode' in our configuration, so major-mode alone
;; cannot tell Copilot which framework is being edited.
;;
;; Give each web-mode buffer the correct Copilot language ID based on its real
;; filename.

(defun catie/copilot-web-language ()
  "Set Copilot's web-mode language ID from the current filename."

  (when buffer-file-name

    ;; Make this mapping buffer-local so a Vue buffer and Svelte buffer can
    ;; coexist without changing one another.
    (setq-local
     copilot-major-mode-alist
     (copy-tree copilot-major-mode-alist))

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
;; Small controls
;; ---------------------------------------------------------------------------

(defun catie/copilot-status ()
  "Show whether Copilot is enabled in the current buffer."

  (interactive)

  (message
   "Copilot: %s"
   (if
       (bound-and-true-p copilot-mode)

       "enabled"

     "disabled")))


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
