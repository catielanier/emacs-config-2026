;;; catie-evil.el --- Evil and navigation -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; Evil
;; ---------------------------------------------------------------------------

(use-package evil
  :ensure t

  :init

  (setq evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-want-fine-undo t
        evil-respect-visual-line-mode t
        evil-undo-system 'undo-redo)

  :config

  (evil-mode 1)

  ;; -------------------------------------------------------------------------
  ;; Native Emacs application buffers
  ;; -------------------------------------------------------------------------

  (dolist (mode
           '(dired-mode
             help-mode
             compilation-mode
             messages-buffer-mode
             special-mode))

    (evil-set-initial-state
     mode
     'emacs))

  ;; -------------------------------------------------------------------------
  ;; Neovim-style tab navigation
  ;; -------------------------------------------------------------------------

  (evil-global-set-key
   'normal
   (kbd "g t")
   #'tab-next)

  (evil-global-set-key
   'normal
   (kbd "g T")
   #'tab-previous))

;; ---------------------------------------------------------------------------
;; Quiet Ex prompt
;; ---------------------------------------------------------------------------

(defun catie/evil-ex-quiet-feedback (original message &rest args)
  "Suppress Evil's unnecessary live Ex command commentary."

  (unless
      (member message
              '("Incomplete command"
                "Unknown command"))

    (apply original message args)))


(advice-add
 'evil-ex-echo
 :around
 #'catie/evil-ex-quiet-feedback)

;; ---------------------------------------------------------------------------
;; Evil extensions
;; ---------------------------------------------------------------------------

(use-package evil-surround
  :ensure t
  :after evil

  :config

  (global-evil-surround-mode 1))


(use-package evil-commentary
  :ensure t
  :after evil

  :config

  (evil-commentary-mode 1))


(use-package evil-mc
  :ensure t
  :after evil

  :config

  (global-evil-mc-mode 1))


;; ---------------------------------------------------------------------------
;; Split helpers
;; ---------------------------------------------------------------------------

(defun catie/split-right ()
  "Create a right-hand split and move into it."

  (interactive)

  (select-window
   (split-window-right)))


(defun catie/split-below ()
  "Create a lower split and move into it."

  (interactive)

  (select-window
   (split-window-below)))


;; ---------------------------------------------------------------------------
;; General / leader key
;; ---------------------------------------------------------------------------

(use-package general
  :ensure t
  :after evil

  :config

  ;; -------------------------------------------------------------------------
  ;; Leader
  ;; -------------------------------------------------------------------------

  (general-create-definer catie/leader

    :states
    '(normal visual motion)

    :keymaps
    'override

    :prefix
    "SPC")


  ;; -------------------------------------------------------------------------
  ;; Base leader bindings
  ;; -------------------------------------------------------------------------

  (catie/leader

    ;; Command palette
    "SPC"
    '(execute-extended-command
      :which-key "command")


    ;; -----------------------------------------------------------------------
    ;; Windows
    ;; -----------------------------------------------------------------------

    "w"
    '(:ignore t
      :which-key "window")

    "w h"
    '(windmove-left
      :which-key "left")

    "w j"
    '(windmove-down
      :which-key "down")

    "w k"
    '(windmove-up
      :which-key "up")

    "w l"
    '(windmove-right
      :which-key "right")

    "w v"
    '(catie/split-right
      :which-key "split right")

    "w s"
    '(catie/split-below
      :which-key "split below")

    "w q"
    '(delete-window
      :which-key "close window")


    ;; -----------------------------------------------------------------------
    ;; Quit
    ;; -----------------------------------------------------------------------

    "q"
    '(:ignore t
      :which-key "quit")

    "q q"
    '(save-buffers-kill-terminal
      :which-key "quit Emacs"))


  ;; -------------------------------------------------------------------------
  ;; Universal tab navigation
  ;; -------------------------------------------------------------------------

  (general-define-key

    :keymaps
    'override

    "C-c ["
    #'tab-previous

    "C-c ]"
    #'tab-next))


;; ---------------------------------------------------------------------------
;; Redraw after tab switching
;; ---------------------------------------------------------------------------
;;
;; Full-screen TUIs such as LazyGit running inside vterm can leave stale
;; terminal cells behind when switching to another Emacs tab.
;;
;; Force Emacs to repaint the terminal after every tab selection, regardless
;; of whether the switch came from:
;;
;;   C-c [
;;   C-c ]
;;   gt / gT
;;   SPC TAB ...
;;   mouse/tab-bar interaction

(defun catie/redraw-after-tab-switch (&rest _)
  "Force a complete display refresh after switching Emacs tabs."

  (redraw-display)

  ;; Force pending redisplay immediately as well.  This is intentionally a
  ;; little aggressive because full-screen terminal applications can leave
  ;; stale cells behind otherwise.
  (redisplay t))


(add-hook
 'tab-bar-tab-post-select-functions
 #'catie/redraw-after-tab-switch)


;; ---------------------------------------------------------------------------
;; Treemacs Evil integration
;; ---------------------------------------------------------------------------

(use-package treemacs-evil
  :ensure t
  :after
  (treemacs evil)

  :config

  ;; Treemacs defines its own Evil state called `treemacs`.
  ;; Keep the same directional window-navigation muscle memory as normal
  ;; editing buffers.

  (evil-define-key
   'treemacs
   treemacs-mode-map

   ;; ------------------------------------------------------------------------
   ;; Window navigation
   ;; ------------------------------------------------------------------------

   (kbd "C-w h")
   #'windmove-left

   (kbd "C-w j")
   #'windmove-down

   (kbd "C-w k")
   #'windmove-up

   (kbd "C-w l")
   #'windmove-right


   ;; ------------------------------------------------------------------------
   ;; Vim-style tree navigation
   ;; ------------------------------------------------------------------------

   (kbd "j")
   #'treemacs-next-line

   (kbd "k")
   #'treemacs-previous-line

   (kbd "h")
   #'treemacs-COLLAPSE-action

   (kbd "l")
   #'treemacs-RET-action

   (kbd "RET")
   #'treemacs-RET-action

   (kbd "TAB")
   #'treemacs-TAB-action


   ;; ------------------------------------------------------------------------
   ;; Universal tab navigation from Treemacs
   ;; ------------------------------------------------------------------------

   (kbd "C-c [")
   #'tab-previous

   (kbd "C-c ]")
   #'tab-next))


;; ---------------------------------------------------------------------------
;; Project dashboard
;; ---------------------------------------------------------------------------

(with-eval-after-load 'catie-projects

  ;; `catie-project-home-mode` derives from special-mode, which normally starts
  ;; in Emacs state according to our configuration above.
  ;;
  ;; The project dashboard is part of the editing interface, so give it normal
  ;; Evil state and therefore the SPC leader.

  (evil-set-initial-state
   'catie-project-home-mode
   'normal))


(provide 'catie-evil)

;;; catie-evil.el ends here
