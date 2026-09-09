;;; early-init.el --- Early startup configuration -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil
      inhibit-startup-screen t
      inhibit-startup-message t
      initial-scratch-message nil
      frame-inhibit-implied-resize t
      inhibit-compacting-font-caches t)

(menu-bar-mode -1)

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))

(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(provide 'early-init)
;;; early-init.el ends here
