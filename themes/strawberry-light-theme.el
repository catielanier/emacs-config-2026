;;; strawberry-light-theme.el --- Strawberry Light theme for Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; An Emacs port of nightsense's Strawberry Light Vim theme.
;;
;; Original:
;; https://github.com/haystackandroid/strawberry
;;
;; Strawberry's syntax philosophy:
;;
;;   red     warnings/errors/deletions
;;   orange  preprocessors/search-in-progress/titles
;;   yellow  search results/TODOs/changes
;;   green   statements/actions/additions
;;   teal    types
;;   blue    constants/strings
;;   purple  special syntax
;;   pink    identifiers/functions

;;; Code:

(deftheme strawberry-light
  "A soft pink light theme based on nightsense's Strawberry Light.")

(let* (;; Base palette
       (base0   "#fff0f7")
       (base1   "#f0dde6")
       (base2   "#b5a3ac")
       (base3   "#9e8b95")
       (base4   "#8a7680")
       (base5   "#75616b")
       (base6   "#3b2c33")
       (base7   "#2b1d24")

       ;; Accent palette
       (red     "#f55050")
       (orange  "#e06a26")
       (yellow  "#d4ac35")
       (green   "#219e21")
       (teal    "#1b9e9e")
       (blue    "#468dd4")
       (purple  "#a26fbf")
       (pink    "#d46a84"))

  (custom-theme-set-faces
   'strawberry-light

   ;; -------------------------------------------------------------------------
   ;; Core Emacs
   ;; -------------------------------------------------------------------------

   `(default
      ((t (:foreground ,base5
           :background ,base0))))

   `(cursor
      ((t (:foreground ,base0
           :background ,pink))))

   `(fringe
      ((t (:foreground ,base3
           :background ,base0))))

   `(region
      ((t (:foreground ,base6
           :background ,base2))))

   `(secondary-selection
      ((t (:foreground ,base6
           :background ,base1))))

   `(highlight
      ((t (:background ,base1))))

   `(shadow
      ((t (:foreground ,base3))))

   `(bold
      ((t (:weight bold))))

   `(italic
      ((t (:slant italic))))

   `(underline
      ((t (:underline t))))

   `(link
      ((t (:foreground ,blue
           :underline t))))

   `(link-visited
      ((t (:foreground ,purple
           :underline t))))

   `(success
      ((t (:foreground ,green))))

   `(warning
      ((t (:foreground ,orange))))

   `(error
      ((t (:foreground ,red
           :weight bold))))

   `(escape-glyph
      ((t (:foreground ,purple))))

   `(homoglyph
      ((t (:foreground ,red))))

   `(trailing-whitespace
      ((t (:foreground ,base0
           :background ,red))))

   ;; -------------------------------------------------------------------------
   ;; Line numbers / window furniture
   ;; -------------------------------------------------------------------------

   `(line-number
      ((t (:foreground ,base4
           :background ,base1))))

   `(line-number-current-line
      ((t (:foreground ,base0
           :background ,base3
           :weight normal))))

   `(vertical-border
      ((t (:foreground ,base2
           :background ,base0))))

   `(window-divider
      ((t (:foreground ,base2))))

   `(window-divider-first-pixel
      ((t (:foreground ,base2))))

   `(window-divider-last-pixel
      ((t (:foreground ,base2))))

   ;; -------------------------------------------------------------------------
   ;; Mode line
   ;;
   ;; Mirrors Strawberry's pink StatusLine.
   ;; -------------------------------------------------------------------------

   `(mode-line
      ((t (:foreground ,base0
           :background ,pink
           :box nil))))

   `(mode-line-active
      ((t (:foreground ,base0
           :background ,pink
           :box nil))))

   `(mode-line-inactive
      ((t (:foreground ,base5
           :background ,base1
           :box nil))))

   `(header-line
      ((t (:foreground ,base5
           :background ,base1
           :box nil))))

   ;; -------------------------------------------------------------------------
   ;; Tab Bar
   ;;
   ;; Strawberry:
   ;; TabLineSel = pink
   ;; TabLine    = muted pink background
   ;; -------------------------------------------------------------------------

   `(tab-bar
      ((t (:foreground ,base5
           :background ,base1
           :box nil))))

   `(tab-bar-tab
      ((t (:foreground ,base0
           :background ,pink
           :box nil
           :weight bold))))

   `(tab-bar-tab-inactive
      ((t (:foreground ,base4
           :background ,base1
           :box nil))))

   ;; -------------------------------------------------------------------------
   ;; Minibuffer / completion
   ;; -------------------------------------------------------------------------

   `(minibuffer-prompt
      ((t (:foreground ,pink
           :weight bold))))

   `(completions-common-part
      ((t (:foreground ,pink
           :weight bold))))

   `(completions-first-difference
      ((t (:foreground ,base6))))

   ;; Vertico
   `(vertico-current
      ((t (:foreground ,base6
           :background ,base1))))

   `(vertico-group-title
      ((t (:foreground ,pink
           :weight bold))))

   `(vertico-group-separator
      ((t (:foreground ,base2))))

   ;; Marginalia
   `(marginalia-documentation
      ((t (:foreground ,base3
           :slant italic))))

   `(marginalia-date
      ((t (:foreground ,teal))))

   `(marginalia-file-name
      ((t (:foreground ,base5))))

   `(marginalia-file-priv-dir
      ((t (:foreground ,blue))))

   ;; Corfu
   ;;
   ;; Mirrors Vim Pmenu / PmenuSel.
   `(corfu-default
      ((t (:foreground ,base6
           :background ,base2))))

   `(corfu-current
      ((t (:foreground ,base0
           :background ,base5))))

   `(corfu-border
      ((t (:foreground ,base2
           :background ,base2))))

   `(corfu-bar
      ((t (:background ,base4))))

   `(corfu-annotations
      ((t (:foreground ,base3))))

   `(corfu-deprecated
      ((t (:foreground ,base3
           :strike-through t))))

   ;; -------------------------------------------------------------------------
   ;; Searching / matching
   ;; -------------------------------------------------------------------------

   `(isearch
      ((t (:foreground ,base0
           :background ,orange
           :weight bold))))

   `(isearch-fail
      ((t (:foreground ,base0
           :background ,red))))

   `(lazy-highlight
      ((t (:foreground ,base6
           :background ,yellow))))

   `(match
      ((t (:foreground ,base6
           :background ,yellow))))

   `(query-replace
      ((t (:inherit isearch))))

   `(show-paren-match
      ((t (:foreground ,base6
           :background ,base2
           :weight bold))))

   `(show-paren-mismatch
      ((t (:foreground ,base0
           :background ,red
           :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Font Lock / syntax
   ;;
   ;; This follows Strawberry's original semantic color scheme closely.
   ;; -------------------------------------------------------------------------

   ;; Comments
   `(font-lock-comment-face
      ((t (:foreground ,base3))))

   `(font-lock-comment-delimiter-face
      ((t (:foreground ,base3))))

   `(font-lock-doc-face
      ((t (:foreground ,base3))))

   ;; Preprocessor / preliminary elements = orange
   `(font-lock-preprocessor-face
      ((t (:foreground ,orange))))

   `(font-lock-warning-face
      ((t (:foreground ,red
           :weight bold))))

   ;; Statements/actions = green
   `(font-lock-keyword-face
      ((t (:foreground ,green))))

   `(font-lock-operator-face
      ((t (:foreground ,green))))

   ;; Types = teal
   `(font-lock-type-face
      ((t (:foreground ,teal))))

   ;; Constants = blue
   `(font-lock-constant-face
      ((t (:foreground ,blue))))

   `(font-lock-number-face
      ((t (:foreground ,blue))))

   `(font-lock-string-face
      ((t (:foreground ,blue))))

   ;; Special syntax = purple
   `(font-lock-builtin-face
      ((t (:foreground ,purple))))

   `(font-lock-escape-face
      ((t (:foreground ,purple))))

   `(font-lock-bracket-face
      ((t (:foreground ,purple))))

   `(font-lock-delimiter-face
      ((t (:foreground ,purple))))

   `(font-lock-misc-punctuation-face
      ((t (:foreground ,purple))))

   ;; Objects / names = pink
   `(font-lock-function-name-face
      ((t (:foreground ,pink))))

   `(font-lock-function-call-face
      ((t (:foreground ,pink))))

   `(font-lock-variable-name-face
      ((t (:foreground ,pink))))

   `(font-lock-variable-use-face
      ((t (:foreground ,pink))))

   `(font-lock-property-name-face
      ((t (:foreground ,pink))))

   `(font-lock-property-use-face
      ((t (:foreground ,pink))))

   ;; -------------------------------------------------------------------------
   ;; Dired
   ;; -------------------------------------------------------------------------

   `(dired-directory
      ((t (:foreground ,base5
           :weight bold))))

   `(dired-symlink
      ((t (:foreground ,teal))))

   `(dired-mark
      ((t (:foreground ,green
           :weight bold))))

   `(dired-marked
      ((t (:foreground ,pink
           :weight bold))))

   `(dired-flagged
      ((t (:foreground ,red))))

   `(dired-header
      ((t (:foreground ,orange
           :weight bold))))

   `(dired-ignored
      ((t (:foreground ,base3))))

   ;; -------------------------------------------------------------------------
   ;; Diff
   ;; -------------------------------------------------------------------------

   `(diff-added
      ((t (:foreground ,green))))

   `(diff-removed
      ((t (:foreground ,red))))

   `(diff-changed
      ((t (:foreground ,yellow))))

   `(diff-refine-added
      ((t (:foreground ,base0
           :background ,green))))

   `(diff-refine-removed
      ((t (:foreground ,base0
           :background ,red))))

   `(diff-refine-changed
      ((t (:foreground ,base6
           :background ,yellow))))

   `(diff-header
      ((t (:foreground ,base5
           :background ,base1))))

   `(diff-file-header
      ((t (:foreground ,orange
           :background ,base1
           :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Magit
   ;; -------------------------------------------------------------------------

   `(magit-section-heading
      ((t (:foreground ,orange
           :weight bold))))

   `(magit-section-highlight
      ((t (:background ,base1))))

   `(magit-branch-local
      ((t (:foreground ,pink))))

   `(magit-branch-current
      ((t (:foreground ,pink
           :weight bold
           :box t))))

   `(magit-branch-remote
      ((t (:foreground ,blue))))

   `(magit-hash
      ((t (:foreground ,base3))))

   `(magit-tag
      ((t (:foreground ,purple))))

   `(magit-diff-added
      ((t (:foreground ,green))))

   `(magit-diff-added-highlight
      ((t (:foreground ,green
           :background ,base1))))

   `(magit-diff-removed
      ((t (:foreground ,red))))

   `(magit-diff-removed-highlight
      ((t (:foreground ,red
           :background ,base1))))

   `(magit-diff-context
      ((t (:foreground ,base4))))

   `(magit-diff-context-highlight
      ((t (:foreground ,base5
           :background ,base1))))

   `(magit-diff-hunk-heading
      ((t (:foreground ,base5
           :background ,base2))))

   `(magit-diff-hunk-heading-highlight
      ((t (:foreground ,base6
           :background ,base2
           :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Treemacs
   ;; -------------------------------------------------------------------------

   `(treemacs-root-face
      ((t (:foreground ,pink
           :weight bold))))

   `(treemacs-directory-face
      ((t (:foreground ,base5))))

   `(treemacs-file-face
      ((t (:foreground ,base5))))

   `(treemacs-tags-face
      ((t (:foreground ,base3))))

   `(treemacs-git-modified-face
      ((t (:foreground ,orange))))

   `(treemacs-git-added-face
      ((t (:foreground ,green))))

   `(treemacs-git-conflict-face
      ((t (:foreground ,red))))

   `(treemacs-git-untracked-face
      ((t (:foreground ,base3))))

   ;; -------------------------------------------------------------------------
   ;; Diagnostics
   ;; -------------------------------------------------------------------------

   `(flycheck-error
      ((t (:foreground ,red
           :underline t))))

   `(flycheck-warning
      ((t (:foreground ,orange
           :underline t))))

   `(flycheck-info
      ((t (:foreground ,teal
           :underline t))))

   `(flymake-error
      ((t (:foreground ,red
           :underline t))))

   `(flymake-warning
      ((t (:foreground ,orange
           :underline t))))

   `(flymake-note
      ((t (:foreground ,teal
           :underline t))))

   ;; -------------------------------------------------------------------------
   ;; Doom Modeline
   ;; -------------------------------------------------------------------------

   `(doom-modeline-buffer-file
      ((t (:foreground ,base0
           :weight bold))))

   `(doom-modeline-buffer-modified
      ((t (:foreground ,yellow
           :weight bold))))

   `(doom-modeline-project-dir
      ((t (:foreground ,base0
           :weight bold))))

   `(doom-modeline-project-parent-dir
      ((t (:foreground ,base1))))

   `(doom-modeline-info
      ((t (:foreground ,teal))))

   `(doom-modeline-warning
      ((t (:foreground ,yellow))))

   `(doom-modeline-urgent
      ((t (:foreground ,red
           :weight bold))))

   ;; -------------------------------------------------------------------------
   ;; Org
   ;; -------------------------------------------------------------------------

   `(org-level-1
      ((t (:foreground ,pink
           :weight bold))))

   `(org-level-2
      ((t (:foreground ,orange
           :weight bold))))

   `(org-level-3
      ((t (:foreground ,green
           :weight bold))))

   `(org-level-4
      ((t (:foreground ,blue
           :weight bold))))

   `(org-level-5
      ((t (:foreground ,purple
           :weight bold))))

   `(org-level-6
      ((t (:foreground ,teal
           :weight bold))))

   `(org-todo
      ((t (:foreground ,yellow
           :weight bold))))

   `(org-done
      ((t (:foreground ,green
           :weight bold))))

   `(org-date
      ((t (:foreground ,blue
           :underline t))))

   `(org-code
      ((t (:foreground ,blue))))

   `(org-verbatim
      ((t (:foreground ,purple))))

   `(org-block
      ((t (:foreground ,base5
           :background ,base1))))

   `(org-block-begin-line
      ((t (:foreground ,base3
           :background ,base1))))

   `(org-block-end-line
      ((t (:foreground ,base3
           :background ,base1))))

   ;; -------------------------------------------------------------------------
   ;; Markdown
   ;; -------------------------------------------------------------------------

   `(markdown-header-face
      ((t (:foreground ,pink
           :weight bold))))

   `(markdown-header-face-1
      ((t (:foreground ,pink
           :weight bold))))

   `(markdown-header-face-2
      ((t (:foreground ,orange
           :weight bold))))

   `(markdown-header-face-3
      ((t (:foreground ,green
           :weight bold))))

   `(markdown-code-face
      ((t (:foreground ,blue
           :background ,base1))))

   `(markdown-inline-code-face
      ((t (:foreground ,blue))))

   `(markdown-link-face
      ((t (:foreground ,pink))))

   `(markdown-url-face
      ((t (:foreground ,blue
           :underline t))))

   ;; -------------------------------------------------------------------------
   ;; Rainbow Delimiters
   ;; -------------------------------------------------------------------------

   `(rainbow-delimiters-depth-1-face
      ((t (:foreground ,pink))))

   `(rainbow-delimiters-depth-2-face
      ((t (:foreground ,purple))))

   `(rainbow-delimiters-depth-3-face
      ((t (:foreground ,blue))))

   `(rainbow-delimiters-depth-4-face
      ((t (:foreground ,teal))))

   `(rainbow-delimiters-depth-5-face
      ((t (:foreground ,green))))

   `(rainbow-delimiters-depth-6-face
      ((t (:foreground ,orange))))

   `(rainbow-delimiters-depth-7-face
      ((t (:foreground ,pink))))

   `(rainbow-delimiters-depth-8-face
      ((t (:foreground ,purple))))

   `(rainbow-delimiters-depth-9-face
      ((t (:foreground ,blue))))

   `(rainbow-delimiters-unmatched-face
      ((t (:foreground ,base0
           :background ,red
           :weight bold))))))

(provide-theme 'strawberry-light)

;;; strawberry-light-theme.el ends here
