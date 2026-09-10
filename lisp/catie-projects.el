;;; catie-projects.el --- Projects and workspaces -*- lexical-binding: t; -*-

(require 'project)


;; ---------------------------------------------------------------------------
;; Project home buffer
;; ---------------------------------------------------------------------------

(define-derived-mode catie-project-home-mode special-mode "Project"
  "Major mode for Catie's project home buffers.")


(with-eval-after-load 'evil

  ;; The dashboard is part of the editing environment, so it should support
  ;; Evil Normal state and the SPC leader.
  (evil-set-initial-state
   'catie-project-home-mode
   'normal))


;; ---------------------------------------------------------------------------
;; Project discovery
;; ---------------------------------------------------------------------------

(defconst catie/projects-root
  (expand-file-name "~/projects/")
  "Root directory containing Catie's projects.")


(defun catie/refresh-projects ()
  "Discover Git projects directly beneath `catie/projects-root'."

  (interactive)

  (when
      (file-directory-p
       catie/projects-root)

    ;; Deliberately non-recursive.
    (project-remember-projects-under
     catie/projects-root
     nil)))


(add-hook
 'emacs-startup-hook
 #'catie/refresh-projects)


;; ---------------------------------------------------------------------------
;; Project naming
;; ---------------------------------------------------------------------------

(defun catie/project-name-from-root (root)
  "Return a clean project name for ROOT."

  (file-name-nondirectory
   (directory-file-name
    (expand-file-name root))))


(defun catie/current-tab-name ()
  "Return the name of the currently selected Emacs tab."

  (alist-get
   'name
   (tab-bar--current-tab)))


(defun catie/current-tab-names ()
  "Return the names of all current Emacs tabs."

  (mapcar
   (lambda (tab)
     (alist-get 'name tab))

   (tab-bar-tabs)))


(defun catie/home-tab-p ()
  "Return non-nil when the current tab is the initial Home tab."

  (equal
   (catie/current-tab-name)
   "Home"))


;; ---------------------------------------------------------------------------
;; Project dashboard
;; ---------------------------------------------------------------------------

(defun catie/project-home-buffer (root)
  "Return the project home buffer for ROOT."

  (let* ((root
          (file-name-as-directory
           (expand-file-name root)))

         (name
          (catie/project-name-from-root
           root))

         (buffer
          (get-buffer-create
           (format
            "*project:%s*"
            name))))

    (with-current-buffer buffer

      (setq default-directory
            root)

      (unless
          (derived-mode-p
           'catie-project-home-mode)

        (catie-project-home-mode))

      (let ((inhibit-read-only
             t))

        (erase-buffer)

        (insert
         (propertize
          name
          'face
          '(:weight bold
            :height 1.4)))

        (insert "\n")
        (insert root)
        (insert "\n\n")

        (insert
         "SPC p f    find file\n")

        (insert
         "SPC p g    search project\n")

        (insert
         "SPC t t    terminal split\n")

        (insert
         "SPC t T    terminal tab\n")

        (insert
         "SPC g g    LazyGit\n")))

    buffer))


;; ---------------------------------------------------------------------------
;; IDE layout
;; ---------------------------------------------------------------------------

(defun catie/project-layout (root)
  "Create Catie's standard IDE layout for project ROOT."

  (let* ((root
          (file-name-as-directory
           (expand-file-name root)))

         (home-buffer
          (catie/project-home-buffer
           root)))

    (switch-to-buffer
     home-buffer)

    (setq default-directory
          root)

    (delete-other-windows)

    ;; Treemacs lives permanently on the right.
    (let ((editor-window
           (selected-window)))

      (require 'treemacs)

      (treemacs-display-current-project-exclusively)

      ;; Treemacs can grab focus while opening.
      (when
          (window-live-p
           editor-window)

        (select-window
         editor-window)))))


;; ---------------------------------------------------------------------------
;; Tabspaces
;; ---------------------------------------------------------------------------

(use-package tabspaces
  :after project

  :custom

  (tabspaces-use-filtered-buffers-as-default
   t)

  (tabspaces-default-tab
   "Home")

  (tabspaces-remove-to-default
   t)

  (tabspaces-include-buffers
   '("*scratch*"))

  ;; Never create files inside company/project repositories.
  (tabspaces-initialize-project-with-todo
   nil)

  ;; No session persistence.
  (tabspaces-session
   nil)

  (tabspaces-session-auto-restore
   nil)

  (tabspaces-keymap-prefix
   nil)

  (tabspaces-fully-resolve-paths
   t)

  (tab-bar-new-tab-choice
   "*scratch*")

  :config

  (setq tab-bar-show
        1

        tab-bar-close-button-show
        nil

        tab-bar-new-button-show
        nil

        tab-bar-tab-hints
        t)

  (tabspaces-mode
   1)

  (tab-bar-mode
   1)

  (tab-bar-rename-tab
   "Home"))


;; ---------------------------------------------------------------------------
;; Create/switch project workspace
;; ---------------------------------------------------------------------------

(defun catie/open-project-tab (workspace-name already-open)
  "Open WORKSPACE-NAME with the correct tab behavior.

The initial Home tab is consumed by the first project.

Existing projects simply switch to their existing tab.

After LazyGit exists, every newly-created project tab is inserted
immediately to its left."

  (cond

   ;; Project already exists: preserve its entire workspace.
   (already-open

    (tab-bar-switch-to-tab
     workspace-name))


   ;; FIRST PROJECT:
   ;;
   ;; Turn the otherwise-useless Home tab directly into the project workspace.
   ((catie/home-tab-p)

    (tab-bar-rename-tab
     workspace-name))


   ;; LazyGit is our permanent right-hand anchor.
   ;;
   ;; Select it invisibly and create the new project immediately to its left.
   ((and
     (fboundp
      'catie/lazygit-tab-exists-p)

     (catie/lazygit-tab-exists-p))

    (let ((inhibit-redisplay
           t)

          (tab-bar-new-tab-to
           'left))

      (tab-bar-switch-to-tab
       catie/lazygit-tab-name)

      (tabspaces-switch-or-create-workspace
       workspace-name)))


   ;; Fallback: normal new workspace.
   (t

    (tabspaces-switch-or-create-workspace
     workspace-name))))


(defun catie/open-project-workspace ()
  "Open a known project in its own workspace.

The first project consumes the initial Home tab.

Opening the first project also creates the shared LazyGit tab silently
on the far right.

Every subsequent new project is inserted immediately to LazyGit's left.

Selecting a project that's already open switches to its existing tab
without disturbing its layout."

  (interactive)

  (let ((projects
         (project-known-project-roots)))

    (unless projects

      (user-error
       "No projects known; run M-x catie/refresh-projects"))

    (let* ((selected-root
            (completing-read
             "Project: "
             projects
             nil
             t))

           (root
            (file-name-as-directory
             (expand-file-name
              selected-root)))

           (workspace-name
            (catie/project-name-from-root
             root))

           (already-open
            (member
             workspace-name
             (catie/current-tab-names))))

      ;; Create or select the project's tab.
      (catie/open-project-tab
       workspace-name
       already-open)

      ;; New projects get the standard editor + Treemacs layout.
      ;;
      ;; Existing projects keep everything exactly as it was.
      (unless already-open

        (setq default-directory
              root)

        (catie/project-layout
         root))

      ;; Only the first project opened in this Emacs session triggers
      ;; automatic LazyGit creation.
      (when
          (fboundp
           'catie/lazygit-autostart-for-first-project)

        (catie/lazygit-autostart-for-first-project
         root)))))


;; ---------------------------------------------------------------------------
;; Project file/search commands
;; ---------------------------------------------------------------------------

(defun catie/project-find-file ()
  "Find a file in the current project."

  (interactive)

  (let ((project
         (project-current t)))

    (project-find-file
     project)))


(defun catie/consult-ripgrep-project ()
  "Ripgrep through the current project."

  (interactive)

  (require 'consult)

  (let ((project
         (project-current t)))

    (consult-ripgrep
     (project-root
      project))))


;; ---------------------------------------------------------------------------
;; Consult workspace buffers
;; ---------------------------------------------------------------------------

(with-eval-after-load 'consult

  (with-eval-after-load 'tabspaces

    ;; Keep the full buffer source available but hidden by default.
    (plist-put
     consult-source-buffer
     :hidden
     t)

    (plist-put
     consult-source-buffer
     :default
     nil)

    (defvar consult--source-workspace
      (list

       :name
       "Workspace Buffers"

       :narrow
       ?w

       :history
       'buffer-name-history

       :category
       'buffer

       :state
       #'consult--buffer-state

       :default
       t

       :items
       (lambda ()

         (consult--buffer-query
          :predicate
          #'tabspaces--local-buffer-p

          :sort
          'visibility

          :as
          #'buffer-name)))

      "Workspace-local buffer source for Consult.")

    (add-to-list
     'consult-buffer-sources
     'consult--source-workspace)))


;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(catie/leader

  ;; Workspaces
  "TAB"
  '(:ignore t
    :which-key "workspace")

  "TAB TAB"
  '(tabspaces-switch-or-create-workspace
    :which-key "switch/create")

  "TAB n"
  '(tab-new
    :which-key "new")

  "TAB c"
  '(tabspaces-close-workspace
    :which-key "close")

  "TAB k"
  '(tabspaces-kill-buffers-close-workspace
    :which-key "close + kill buffers")

  "TAB s"
  '(tab-switch
    :which-key "switch by name")


  ;; Projects
  "p"
  '(:ignore t
    :which-key "project")

  "p p"
  '(catie/open-project-workspace
    :which-key "switch project")

  "p f"
  '(catie/project-find-file
    :which-key "find file")

  "p b"
  '(project-switch-to-buffer
    :which-key "project buffer")

  "p g"
  '(catie/consult-ripgrep-project
    :which-key "ripgrep")

  "p d"
  '(project-dired
    :which-key "project directory")

  "p r"
  '(catie/refresh-projects
    :which-key "refresh projects")


  ;; UI
  "o"
  '(:ignore t
    :which-key "open")

  "o t"
  '(treemacs-select-window
    :which-key "file tree"))


(provide 'catie-projects)

;;; catie-projects.el ends here
