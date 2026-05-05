;;; early-init.el --- Pre-GUI initialization -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Runs before the GUI frame is created and before package.el initializes.
;; Only startup performance and frame setup belong here.

;;; Code:

;; --- Startup performance ---

;; Maximize GC threshold during init to avoid repeated collections while
;; loading packages. Restored to a reasonable value in init.el after
;; everything has loaded.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Every file load is matched against this alist for special handlers
;; (TRAMP, compressed files, etc.). During startup we're loading local
;; .el files only -- clearing it removes repeated regex matching.
(defvar me--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; VC probes every opened file against all known backends. During init
;; that's pure overhead.
(defvar me--vc-handled-backends (bound-and-true-p vc-handled-backends))
(setq vc-handled-backends nil)

;; Restore after startup completes.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)   ; 32 MB
                  gc-cons-percentage 0.1)))

;; --- Suppress startup noise ---

;; Byte-compile and native-comp warnings are not actionable for the user.
(setq byte-compile-warnings '(not obsolete))
(setq native-comp-async-report-warnings-errors 'silent)

;; --- Frame setup (before first frame is drawn) ---

;; Disable UI chrome before the frame renders to avoid a flash of
;; toolbar/scrollbar that immediately gets removed.
(setq default-frame-alist
      '((tool-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        ;; Reasonable initial size; will be overridden if you maximize.
        (width . 120)
        (height . 45)))

(push '(menu-bar-lines . 0) default-frame-alist)

;; Pixel-precise resizing avoids gaps on tiling WMs and full-screen.
(setq frame-resize-pixelwise t)

;; Don't resize the frame when toggling UI elements.
(setq frame-inhibit-implied-resize t)

;; --- Package.el ---

;; We initialize packages ourselves in init.el.
(setq package-enable-at-startup nil)

(provide 'early-init)
;;; early-init.el ends here
