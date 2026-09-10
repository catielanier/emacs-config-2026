;;; catie-linux.el --- Linux-specific behaviour -*- lexical-binding: t; -*-

(require 'browse-url)
(require 'subr-x)


;; ---------------------------------------------------------------------------
;; Clipboard backend
;; ---------------------------------------------------------------------------

(defun catie/linux-wayland-p ()
  "Return non-nil when Emacs is running in a Wayland session."

  (and
   (getenv "WAYLAND_DISPLAY")
   (not
    (string-empty-p
     (getenv "WAYLAND_DISPLAY")))))


(defun catie/linux-clipboard-backend ()
  "Return the best available Linux clipboard backend.

Prefer wl-clipboard under Wayland, then fall back to xclip or xsel."

  (cond

   ;; Wayland-native clipboard.
   ((and
     (catie/linux-wayland-p)
     (executable-find "wl-copy")
     (executable-find "wl-paste"))

    'wl-clipboard)


   ;; X11 clipboard.
   ((executable-find "xclip")

    'xclip)


   ;; Alternate X11 clipboard utility.
   ((executable-find "xsel")

    'xsel)


   ;; Nothing usable.
   (t

    nil)))


;; ---------------------------------------------------------------------------
;; Copy
;; ---------------------------------------------------------------------------

(defun catie/linux-copy (text &optional _push)
  "Copy TEXT to the Linux system clipboard."

  (pcase
      (catie/linux-clipboard-backend)

    ('wl-clipboard

     (with-temp-buffer

       (insert text)

       (call-process-region
        (point-min)
        (point-max)
        "wl-copy"
        nil
        nil
        nil)))


    ('xclip

     (with-temp-buffer

       (insert text)

       (call-process-region
        (point-min)
        (point-max)
        "xclip"
        nil
        nil
        nil
        "-selection"
        "clipboard"
        "-in")))


    ('xsel

     (with-temp-buffer

       (insert text)

       (call-process-region
        (point-min)
        (point-max)
        "xsel"
        nil
        nil
        nil
        "--clipboard"
        "--input")))


    (_

     (message
      "No Linux clipboard utility available"))))


;; ---------------------------------------------------------------------------
;; Paste
;; ---------------------------------------------------------------------------

(defun catie/linux-paste ()
  "Return text currently on the Linux system clipboard."

  (pcase
      (catie/linux-clipboard-backend)

    ('wl-clipboard

     (with-temp-buffer

       ;; wl-paste normally appends a newline to textual output.
       ;; --no-newline gives Emacs exactly what is on the clipboard.
       (when
           (zerop
            (call-process
             "wl-paste"
             nil
             t
             nil
             "--no-newline"))

         (buffer-string))))


    ('xclip

     (with-temp-buffer

       (when
           (zerop
            (call-process
             "xclip"
             nil
             t
             nil
             "-selection"
             "clipboard"
             "-out"))

         (buffer-string))))


    ('xsel

     (with-temp-buffer

       (when
           (zerop
            (call-process
             "xsel"
             nil
             t
             nil
             "--clipboard"
             "--output"))

         (buffer-string))))


    (_

     nil)))


(setq interprogram-cut-function
      #'catie/linux-copy

      interprogram-paste-function
      #'catie/linux-paste)


;; ---------------------------------------------------------------------------
;; URLs
;; ---------------------------------------------------------------------------

;; Open links through the desktop's registered default application.
;;
;; On Linux this ultimately uses xdg-open, so it works whether the default
;; browser is Firefox, Chrome, Vivaldi, etc.
(setq browse-url-browser-function
      #'browse-url-xdg-open)


;; ---------------------------------------------------------------------------
;; Status
;; ---------------------------------------------------------------------------

(defun catie/linux-platform-status ()
  "Show the Linux desktop integration currently being used."

  (interactive)

  (message
   "Linux | session: %s | clipboard: %s | xdg-open: %s"
   (cond

    ((catie/linux-wayland-p)
     "Wayland")

    ((getenv "DISPLAY")
     "X11")

    (t
     "TTY"))

   (or
    (catie/linux-clipboard-backend)
    "none")

   (if
       (executable-find "xdg-open")

       "yes"

     "missing")))


(provide 'catie-linux)

;;; catie-linux.el ends here
