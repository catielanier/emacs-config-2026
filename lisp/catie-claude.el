;;; catie-claude.el --- Claude Code IDE integration -*- lexical-binding: t; -*-

(require 'project)


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

  ;; Claude Code is a terminal application.
  ;;
  ;; vterm is already our known-good terminal backend.
  (setq claude-code-ide-terminal-backend
        'vterm)

  ;; We're intentionally using vterm.
  (setq claude-code-ide-show-backend-recommendation
        nil)

  ;; Let Claude use its flicker-free terminal rendering mode.
  (setq claude-code-ide-no-flicker
        t)

  ;; Keep the package's vterm optimizations enabled.
  (setq claude-code-ide-vterm-anti-flicker
        t)

  (setq claude-code-ide-vterm-render-delay
        0.005)

  (setq claude-code-ide-prevent-reflow-glitch
        t)


  ;; -------------------------------------------------------------------------
  ;; Window layout
  ;; -------------------------------------------------------------------------
  ;;
  ;; IMPORTANT:
  ;;
  ;; Claude is NOT a side window.
  ;;
  ;; Treemacs owns the actual right side of the frame.  Claude instead lives
  ;; in the rightmost part of the normal editor area:
  ;;
  ;;     editor | Claude | Treemacs
  ;;
  ;; That means Treemacs can disappear/reappear and will always remain
  ;; farther right than Claude.

  (setq claude-code-ide-use-side-window
        nil)

  ;; The package still consults this for some internal behavior.
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

  ;; Claude gets the useful IDE tools, but not arbitrary Elisp execution.
  (setq claude-code-ide-enable-execute-code
        nil)


  :config

  (claude-code-ide-emacs-tools-setup)


  ;; -------------------------------------------------------------------------
  ;; Display Claude immediately LEFT of Treemacs
  ;; -------------------------------------------------------------------------
  ;;
  ;; `rightmost' means the right edge of the frame's MAIN window area.
  ;;
  ;; Emacs side windows such as Treemacs live outside that main area, so:
  ;;
  ;;     main editor area           side window
  ;;
  ;;     editor | Claude          | Treemacs
  ;;
  ;; Opening Treemacs afterward still places it beyond Claude.

  (add-to-list
   'display-buffer-alist

   '("\\*claude-code\\["

     (display-buffer-in-direction)

     (direction . rightmost)

     ;; Wider than the previous 64-column experiment, but still leaves plenty
     ;; of room for the editor on a normal development terminal.
     (window-width . 72)

     ;; Try to preserve Claude's width while editor splits come and go.
     (preserve-size . (t . nil))))


  ;; -------------------------------------------------------------------------
  ;; Terminal navigation
  ;; -------------------------------------------------------------------------
  ;;
  ;; claude-code-ide adds its own local terminal bindings after creating its
  ;; vterm.  Re-assert our normal terminal navigation afterward so Claude
  ;; behaves exactly like the other terminal applications in this config.

  (defun catie/claude-terminal-navigation (&rest _)
    "Install Catie's terminal navigation in a Claude vterm."

    (when
        (derived-mode-p 'vterm-mode)

      ;; Claude is a terminal, not a normal Evil editing buffer.
      (when
          (featurep 'evil)

        (evil-emacs-state))


      ;; Window navigation.
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


      ;; Emacs tab navigation.
      (local-set-key
       (kbd "C-c [")
       #'tab-previous)

      (local-set-key
       (kbd "C-c ]")
       #'tab-next)


      ;; Terminal copy/navigation mode.
      (local-set-key
       (kbd "C-c v")
       #'vterm-copy-mode)


      ;; Same concept as C-c t in our normal terminal:
      ;; hide the terminal-like panel we're currently using.
      (local-set-key
       (kbd "C-c t")
       #'catie/claude-toggle)))


  ;; Upstream calls this after constructing each Claude terminal.
  ;; Install our navigation AFTER its terminal-specific bindings.
  (unless
      (advice-member-p
       #'catie/claude-terminal-navigation
       'claude-code-ide--setup-terminal-keybindings)

    (advice-add
     'claude-code-ide--setup-terminal-keybindings
     :after
     #'catie/claude-terminal-navigation)))


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
