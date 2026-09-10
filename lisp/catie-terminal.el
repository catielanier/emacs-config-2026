;;; catie-terminal.el --- Project terminals with vterm -*- lexical-binding: t; -*-

(require 'project)
(require 'seq)


;; ---------------------------------------------------------------------------
;; Fish
;; ---------------------------------------------------------------------------

(defun catie/find-fish ()
  "Return the Fish executable path."
  (or (executable-find "fish")
      "/opt/homebrew/bin/fish"
      "/usr/local/bin/fish"
      "/usr/bin/fish"))

(setq shell-file-name (catie/find-fish)
      explicit-shell-file-name (catie/find-fish))


;; ---------------------------------------------------------------------------
;; Project terminal tracking
;; ---------------------------------------------------------------------------

(defvar catie/project-terminal-buffers
  (make-hash-table :test #'equal)
  "Map project roots to their vterm buffers.")


(defun catie/normalize-project-root (root)
  "Return normalized directory form of ROOT."
  (file-name-as-directory
   (expand-file-name root)))


(defun catie/project-terminal-name (root)
  "Return the vterm buffer name for ROOT."
  (format
   "*vterm:%s*"
   (file-name-nondirectory
    (directory-file-name root))))


(defun catie/existing-project-terminal (root)
  "Return the live vterm buffer for ROOT, or nil."
  (let* ((root
          (catie/normalize-project-root root))
         (buffer
          (gethash root catie/project-terminal-buffers)))

    (if (buffer-live-p buffer)
        buffer

      (remhash root catie/project-terminal-buffers)
      nil)))


;; ---------------------------------------------------------------------------
;; vterm
;; ---------------------------------------------------------------------------

(use-package vterm
  :ensure t

  :commands
  (vterm-mode
   vterm-copy-mode)

  :custom
  (vterm-shell (catie/find-fish))
  (vterm-kill-buffer-on-exit t)
  (vterm-max-scrollback 10000)

  ;; Allow narrow terminal panes to report their REAL width.
  ;;
  ;; vterm defaults to 80 columns minimum, which causes TUIs such as
  ;; Claude Code to render content beyond the visible edge of a sidebar.
  (vterm-min-window-width 40)
  :config

  ;; vterm is a terminal, not an Evil editing buffer.
  (when (featurep 'evil)
    (evil-set-initial-state
     'vterm-mode
     'emacs))

  ;; -------------------------------------------------------------------------
  ;; Emacs controls from inside vterm
  ;; -------------------------------------------------------------------------
  ;;
  ;; Normal terminal input remains normal:
  ;;
  ;;   Backspace -> shell
  ;;   C-w       -> shell backward-kill-word
  ;;   Space     -> shell
  ;;
  ;; C-c is our explicit Emacs prefix.

  (define-key
   vterm-mode-map
   (kbd "C-c t")
   #'catie/project-terminal)

  ;; Window navigation.
  (define-key
   vterm-mode-map
   (kbd "C-c h")
   #'windmove-left)

  (define-key
   vterm-mode-map
   (kbd "C-c j")
   #'windmove-down)

  (define-key
   vterm-mode-map
   (kbd "C-c k")
   #'windmove-up)

  (define-key
   vterm-mode-map
   (kbd "C-c l")
   #'windmove-right)

  ;; Universal Emacs tab navigation.
  (define-key
   vterm-mode-map
   (kbd "C-c [")
   #'tab-previous)

  (define-key
   vterm-mode-map
   (kbd "C-c ]")
   #'tab-next)

  ;; Copy mode.
  (define-key
   vterm-mode-map
   (kbd "C-c v")
   #'vterm-copy-mode)

  ;; Keep tab navigation working while vterm-copy-mode is active too.
  (with-eval-after-load 'vterm
    (define-key
     vterm-copy-mode-map
     (kbd "C-c [")
     #'tab-previous)

    (define-key
     vterm-copy-mode-map
     (kbd "C-c ]")
     #'tab-next)))


;; ---------------------------------------------------------------------------
;; Create vterm buffer without displaying it
;; ---------------------------------------------------------------------------

(defun catie/create-project-terminal-buffer (root)
  "Create and return a vterm buffer rooted at ROOT.

This does not decide which window will display the buffer."

  (require 'vterm)

  (let* ((root
          (catie/normalize-project-root root))
         (buffer-name
          (catie/project-terminal-name root))
         (buffer
          (get-buffer-create buffer-name)))

    (with-current-buffer buffer
      (setq default-directory root)

      (unless (derived-mode-p 'vterm-mode)
        (vterm-mode)))

    (puthash
     root
     buffer
     catie/project-terminal-buffers)

    buffer))


;; ---------------------------------------------------------------------------
;; Find main editor window
;; ---------------------------------------------------------------------------

(defun catie/editor-window-p (window)
  "Return non-nil when WINDOW is suitable as the main editor window."

  (and
   (window-live-p window)

   (not
    (window-minibuffer-p window))

   ;; Exclude Treemacs and other side windows.
   (not
    (window-parameter window 'window-side))

   ;; Exclude terminals.
   (with-current-buffer
       (window-buffer window)

     (not
      (derived-mode-p 'vterm-mode)))))


(defun catie/editor-window ()
  "Return an appropriate main editor window."

  (if (catie/editor-window-p
       (selected-window))

      (selected-window)

    (or
     (seq-find
      #'catie/editor-window-p
      (window-list nil 'no-minibuffer))

     (user-error
      "No editor window available"))))


;; ---------------------------------------------------------------------------
;; Create lower terminal split
;; ---------------------------------------------------------------------------

(defun catie/create-terminal-window (editor-window)
  "Create a terminal-sized split beneath EDITOR-WINDOW."

  (let* ((editor-height
          (window-total-height editor-window))
         (terminal-height
          (max
           10
           (floor
            (* editor-height 0.30)))))

    (split-window
     editor-window
     (- terminal-height)
     'below)))


;; ---------------------------------------------------------------------------
;; Toggle project terminal
;; ---------------------------------------------------------------------------

(defun catie/project-terminal ()
  "Toggle the current project's vterm beneath the editor."

  (interactive)

  (let* ((project
          (project-current t))
         (root
          (catie/normalize-project-root
           (project-root project)))
         (buffer
          (catie/existing-project-terminal root))
         (terminal-window
          (and
           buffer
           (get-buffer-window
            buffer
            (selected-frame)))))

    (cond

     ;; Terminal focused: hide it.
     ((and
       terminal-window
       (eq terminal-window
           (selected-window)))

      (delete-window
       terminal-window))

     ;; Terminal visible elsewhere: focus it.
     (terminal-window

      (select-window
       terminal-window))

     ;; Existing terminal buffer is hidden.
     (buffer

      (let* ((editor-window
              (catie/editor-window))
             (new-window
              (catie/create-terminal-window
               editor-window)))

        (set-window-buffer
         new-window
         buffer)

        (select-window
         new-window)))

     ;; No terminal exists yet.
     (t

      (let* ((buffer
              (catie/create-project-terminal-buffer root))
             (editor-window
              (catie/editor-window))
             (new-window
              (catie/create-terminal-window
               editor-window)))

        (set-window-buffer
         new-window
         buffer)

        (select-window
         new-window))))))


;; ---------------------------------------------------------------------------
;; Dedicated terminal tab
;; ---------------------------------------------------------------------------

(defun catie/project-terminal-tab ()
  "Open the current project's terminal in a dedicated Emacs tab."

  (interactive)

  (let* ((project
          (project-current t))
         (root
          (catie/normalize-project-root
           (project-root project)))
         (project-name
          (file-name-nondirectory
           (directory-file-name root)))
         (tab-name
          (format
           "%s:terminal"
           project-name))
         (buffer
          (or
           (catie/existing-project-terminal root)
           (catie/create-project-terminal-buffer root))))

    (if
        (member
         tab-name
         (mapcar
          (lambda (tab)
            (alist-get 'name tab))
          (tab-bar-tabs)))

        (tab-switch
         tab-name)

      (tab-new)

      (tab-bar-rename-tab
       tab-name)

      (delete-other-windows)

      (switch-to-buffer
       buffer))))


;; ---------------------------------------------------------------------------
;; Plain terminal
;; ---------------------------------------------------------------------------

(defun catie/terminal-here ()
  "Open a new vterm rooted in the current directory."

  (interactive)

  (require 'vterm)

  (let* ((root
          default-directory)
         (buffer
          (generate-new-buffer
           "*vterm*")))

    (with-current-buffer buffer
      (setq default-directory root)
      (vterm-mode))

    (switch-to-buffer
     buffer)))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  "t"
  '(:ignore t :which-key "terminal")

  "t t"
  '(catie/project-terminal
    :which-key "terminal split")

  "t T"
  '(catie/project-terminal-tab
    :which-key "terminal tab")

  "t e"
  '(catie/terminal-here
    :which-key "terminal here"))


(provide 'catie-terminal)

;;; catie-terminal.el ends here
