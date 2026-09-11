;;; catie-claude.el --- Claude Code IDE integration -*- lexical-binding: t; -*-

(require 'project)


;; ---------------------------------------------------------------------------
;; Ghostel
;; ---------------------------------------------------------------------------
;;
;; Claude Code redraws extremely aggressively.  vterm is excellent for our
;; normal terminal and LazyGit, but Claude's TUI can produce large redraw /
;; reflow artifacts in a narrow editor pane.
;;
;; Ghostel uses libghostty's VT renderer and has explicit support for
;; synchronized terminal output used by TUIs such as Claude Code.
;;
;; ONLY Claude uses Ghostel.  Our normal terminal stack remains vterm.

(use-package ghostel
  :ensure t

  :config

  ;; -------------------------------------------------------------------------
  ;; Universal navigation inside Ghostel
  ;; -------------------------------------------------------------------------
  ;;
  ;; Ghostel starts in semi-char mode.  C-c remains available to Emacs there,
  ;; which makes it a natural match for our terminal navigation convention.

  (define-key
   ghostel-semi-char-mode-map
   (kbd "C-c h")
   #'windmove-left)

  (define-key
   ghostel-semi-char-mode-map
   (kbd "C-c j")
   #'windmove-down)

  (define-key
   ghostel-semi-char-mode-map
   (kbd "C-c k")
   #'windmove-up)

  (define-key
   ghostel-semi-char-mode-map
   (kbd "C-c l")
   #'windmove-right)


  ;; Emacs tabs.
  (define-key
   ghostel-semi-char-mode-map
   (kbd "C-c [")
   #'tab-previous)

  (define-key
   ghostel-semi-char-mode-map
   (kbd "C-c ]")
   #'tab-next))


;; ---------------------------------------------------------------------------
;; Claude Code IDE
;; ---------------------------------------------------------------------------

(use-package claude-code-ide
  :vc
  (:url "https://github.com/manzaltu/claude-code-ide.el"
   :rev :newest)

  :commands
  (claude-code-ide
   claude-code-ide-toggle
   claude-code-ide-menu
   claude-code-ide-stop
   claude-code-ide-resume
   claude-code-ide-list-sessions
   claude-code-ide-check-status
   claude-code-ide-insert-at-mentioned)

  :init

  ;; -------------------------------------------------------------------------
  ;; Terminal
  ;; -------------------------------------------------------------------------

  ;; Claude gets Ghostel.
  ;;
  ;; vterm remains our backend everywhere else.
  (setq claude-code-ide-terminal-backend
        'ghostel)

  ;; We're choosing the recommended backend deliberately.
  (setq claude-code-ide-show-backend-recommendation
        nil)


  ;; -------------------------------------------------------------------------
  ;; Window layout
  ;; -------------------------------------------------------------------------
  ;;
  ;; Claude is a normal window in the main editor area.
  ;;
  ;; Treemacs remains the actual right-side window:
  ;;
  ;;     editor | Claude | Treemacs
  ;;
  ;; Therefore Treemacs remains rightmost regardless of opening order.

  (setq claude-code-ide-use-side-window
        nil)

  (setq claude-code-ide-window-side
        'right)

  (setq claude-code-ide-focus-on-open
        t)


  ;; -------------------------------------------------------------------------
  ;; IDE integration
  ;; -------------------------------------------------------------------------

  (setq claude-code-ide-diagnostics-backend
        'flycheck)

  (setq claude-code-ide-use-ide-diff
        t)

  (setq claude-code-ide-switch-tab-on-ediff
        t)

  (setq claude-code-ide-show-claude-window-in-ediff
        t)

  ;; No arbitrary Elisp evaluation from Claude.
  (setq claude-code-ide-enable-execute-code
        nil)


  :config

  (claude-code-ide-emacs-tools-setup)


  ;; -------------------------------------------------------------------------
  ;; Display Claude immediately left of Treemacs
  ;; -------------------------------------------------------------------------

  (add-to-list
   'display-buffer-alist

   '("\\*claude-code\\["

     (display-buffer-in-direction)

     ;; Right edge of the MAIN editor area.
     ;;
     ;; Treemacs is a side window outside that area and therefore remains
     ;; farther right.
     (direction . rightmost)

     ;; Enough room for Claude's TUI while retaining a useful editor pane.
     (window-width . 72)

     (preserve-size . (t . nil))))


  ;; -------------------------------------------------------------------------
  ;; Claude-specific Ghostel navigation
  ;; -------------------------------------------------------------------------

  (defun catie/claude-ghostel-navigation (&rest _)
    "Apply Catie's terminal navigation to Claude's Ghostel buffer."

    (when
        (derived-mode-p 'ghostel-mode)

      (local-set-key
       (kbd "C-c h")
       #'windmove-left)

      (local-set-key
       (kbd "C-c j")
       #'windmove-down)

      (local-set-key
       (kbd "C-c k")
       #'windmove-up)

      (local-set-key
       (kbd "C-c l")
       #'windmove-right)

      (local-set-key
       (kbd "C-c [")
       #'tab-previous)

      (local-set-key
       (kbd "C-c ]")
       #'tab-next)

      ;; Hide/show Claude from inside its terminal.
      (local-set-key
       (kbd "C-c t")
       #'catie/claude-toggle)))


  ;; claude-code-ide sets up backend-specific terminal bindings after creating
  ;; the terminal.  Re-assert ours afterward.
  (unless
      (advice-member-p
       #'catie/claude-ghostel-navigation
       'claude-code-ide--setup-terminal-keybindings)

    (advice-add
     'claude-code-ide--setup-terminal-keybindings
     :after
     #'catie/claude-ghostel-navigation)))


;; ---------------------------------------------------------------------------
;; Project-aware toggle
;; ---------------------------------------------------------------------------

(defun catie/claude-toggle ()
  "Start, show or hide Claude Code for the current project."

  (interactive)

  (require 'claude-code-ide)

  (let* ((project-directory
          (claude-code-ide--get-working-directory))

         (sessions
          (claude-code-ide-mcp--sessions-for-project
           project-directory)))

    (if sessions

        (claude-code-ide-toggle)

      (claude-code-ide))))


;; ---------------------------------------------------------------------------
;; Status
;; ---------------------------------------------------------------------------

(defun catie/claude-status ()
  "Check Claude Code availability."

  (interactive)

  (require 'claude-code-ide)

  (claude-code-ide-check-status))


;; ---------------------------------------------------------------------------
;; Leader
;; ---------------------------------------------------------------------------

(catie/leader

  "a a"
  '(catie/claude-toggle
    :which-key "Claude Code")

  "a m"
  '(claude-code-ide-menu
    :which-key "Claude menu")

  "a x"
  '(claude-code-ide-stop
    :which-key "stop Claude")

  "a @"
  '(claude-code-ide-insert-at-mentioned
    :which-key "send selection to Claude"))


(provide 'catie-claude)

;;; catie-claude.el ends here
