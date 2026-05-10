;;; modus-nord-theme.el --- Nord palette on top of modus-themes -*- lexical-binding:t -*-

;; Author: ad
;; URL: https://github.com/skissue/gxy
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (modus-themes "5.2.0"))
;; Keywords: faces, theme, accessibility

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; Commentary:

;; A dark theme using the Nord palette (https://www.nordtheme.com/),
;; built as a derivative of the Modus themes (v5.2+).  Any palette
;; entry not mapped here falls back to `modus-themes-vivendi-palette',
;; so the theme is functional immediately and can be tightened
;; incrementally.
;;
;; Diffs use Nord's traditional foreground-only convention.
;;
;; Activation:
;;
;;   (require 'modus-themes)
;;   (load-theme 'modus-nord :no-confirm)

;;; Code:

(require 'modus-themes)

(defgroup modus-nord nil
  "A Nord-palette theme built on top of `modus-themes'."
  :group 'faces
  :group 'modus-themes
  :prefix "modus-nord-"
  :tag "Modus Nord")

(defconst modus-nord-palette
  '(
;;; Named colors -- the Nord palette
;;; https://www.nordtheme.com/docs/colors-and-palettes

    ;; Polar Night (backgrounds, dark to light)
    (nord0  "#2E3440")
    (nord1  "#3B4252")
    (nord2  "#434C5E")
    (nord3  "#4C566A")

    ;; Snow Storm (foregrounds, dim to bright)
    (nord4  "#D8DEE9")
    (nord5  "#E5E9F0")
    (nord6  "#ECEFF4")

    ;; Frost (cool blue/cyan accents)
    (nord7  "#8FBCBB")
    (nord8  "#88C0D0")
    (nord9  "#81A1C1")
    (nord10 "#5E81AC")

    ;; Aurora (warm accents: red, orange, yellow, green, purple)
    (nord11 "#BF616A")
    (nord12 "#D08770")
    (nord13 "#EBCB8B")
    (nord14 "#A3BE8C")
    (nord15 "#B48EAD")

;;; Semantic mappings

    ;; Basic surfaces
    (bg-main          nord0)
    (bg-dim           nord1)
    (fg-main          nord4)
    (fg-dim           nord3)
    (fg-alt           nord6)
    (bg-active        nord3)
    (bg-inactive      nord1)
    (border           nord3)

    ;; Special purpose backgrounds
    (bg-completion        nord2)
    (bg-popup             nord1)
    (bg-hover             nord3)
    (bg-hover-secondary   nord2)
    (bg-hl-line           nord1)
    (bg-region            nord2)
    (fg-region            fg-main)

    ;; Mode line
    (bg-mode-line-active        nord2)
    (fg-mode-line-active        nord6)
    (border-mode-line-active    nord3)
    (bg-mode-line-inactive      nord1)
    (fg-mode-line-inactive      nord3)
    (border-mode-line-inactive  nord1)

    (modeline-err     nord11)
    (modeline-warning nord13)
    (modeline-info    nord8)

    ;; Tab bar
    (bg-tab-bar      nord1)
    (bg-tab-current  bg-main)
    (bg-tab-other    nord2)

    ;; Diffs (foreground-only, Nord convention)
    (bg-added         bg-main)
    (bg-added-faint   bg-main)
    (bg-added-refine  bg-main)
    (bg-added-fringe  nord14)
    (fg-added         nord14)
    (fg-added-intense nord14)

    (bg-changed         bg-main)
    (bg-changed-faint   bg-main)
    (bg-changed-refine  bg-main)
    (bg-changed-fringe  nord13)
    (fg-changed         nord13)
    (fg-changed-intense nord13)

    (bg-removed         bg-main)
    (bg-removed-faint   bg-main)
    (bg-removed-refine  bg-main)
    (bg-removed-fringe  nord11)
    (fg-removed         nord11)
    (fg-removed-intense nord11)

    (bg-diff-context    nord1)

    ;; Paren match
    (bg-paren-match        nord3)
    (bg-paren-expression   nord1)
    (underline-paren-match unspecified)

    ;; General mappings
    (cursor    nord4)
    (keybind   nord8)
    (name      nord7)
    (identifier nord7)

    (err     nord11)
    (warning nord13)
    (info    nord8)

    (underline-err     nord11)
    (underline-warning nord13)
    (underline-note    nord8)

    (bg-prominent-err     nord11)
    (fg-prominent-err     nord0)
    (bg-prominent-warning nord13)
    (fg-prominent-warning nord0)
    (bg-prominent-note    nord8)
    (fg-prominent-note    nord0)

    (bg-active-argument nord2)
    (fg-active-argument nord13)
    (bg-active-value    nord2)
    (fg-active-value    nord8)

    ;; Code
    (builtin       nord9)
    (comment       nord3)
    (constant      nord15)
    (docstring     nord3)
    (fnname        nord8)
    (fnname-call   nord8)
    (keyword       nord9)
    (preprocessor  nord13)
    (property      nord8)
    (rx-backslash  nord13)
    (rx-construct  nord13)
    (string        nord14)
    (type          nord7)
    (variable      nord4)
    (variable-use  nord4)
    (number        nord15)
    (operator      nord9)
    (bracket       nord4)
    (delimiter     nord6)

    ;; Accents
    (accent-0 nord8)
    (accent-1 nord14)
    (accent-2 nord13)
    (accent-3 nord15)

    ;; Completion match
    (fg-completion-match-0 nord8)
    (fg-completion-match-1 nord14)
    (fg-completion-match-2 nord13)
    (fg-completion-match-3 nord15)

    ;; Date
    (date-common           nord8)
    (date-deadline         nord11)
    (date-deadline-subtle  nord11)
    (date-event            fg-alt)
    (date-holiday          nord12)
    (date-holiday-other    nord15)
    (date-range            fg-alt)
    (date-scheduled        nord13)
    (date-scheduled-subtle nord13)
    (date-weekday          nord8)
    (date-weekend          nord12)

    ;; Links
    (fg-link               nord8)
    (underline-link        nord8)
    (fg-link-symbolic      nord7)
    (underline-link-symbolic nord7)
    (fg-link-visited       nord15)
    (underline-link-visited nord15)

    ;; Mail
    (mail-cite-0    nord10)
    (mail-cite-1    nord14)
    (mail-cite-2    nord8)
    (mail-cite-3    nord13)
    (mail-part      nord7)
    (mail-recipient nord15)
    (mail-subject   nord12)
    (mail-other     nord3)

    ;; Mark
    (bg-mark-delete bg-main)
    (fg-mark-delete nord11)
    (bg-mark-select bg-main)
    (fg-mark-select nord8)
    (bg-mark-other  bg-main)
    (fg-mark-other  nord13)

    ;; Prompt
    (fg-prompt nord8)

    ;; Prose
    (fg-prose-code        nord7)
    (fg-prose-macro       nord15)
    (fg-prose-verbatim    nord14)
    (prose-done           nord14)
    (prose-todo           nord11)
    (prose-metadata       nord3)
    (prose-metadata-value nord4)
    (prose-table          nord4)
    (prose-table-formula  nord13)
    (prose-tag            nord3)

    ;; Rainbow (rainbow-delimiters and similar)
    (rainbow-0 nord4)
    (rainbow-1 nord11)
    (rainbow-2 nord12)
    (rainbow-3 nord13)
    (rainbow-4 nord14)
    (rainbow-5 nord15)
    (rainbow-6 nord8)
    (rainbow-7 nord7)
    (rainbow-8 nord10)

    ;; Headings
    (fg-heading-0 nord8)
    (fg-heading-1 nord4)
    (fg-heading-2 nord13)
    (fg-heading-3 nord10)
    (fg-heading-4 nord15)
    (fg-heading-5 nord14)
    (fg-heading-6 nord11)
    (fg-heading-7 nord7)
    (fg-heading-8 nord3))
  "The `modus-nord' palette.
Named colors have the form (NAME HEX-VALUE).  Semantic mappings
have the form (MAPPING-NAME COLOR-NAME).  Anything not defined
here is inherited from `modus-themes-vivendi-palette'.")

(defcustom modus-nord-palette-overrides nil
  "Overrides for `modus-nord-palette'.

Mirror the elements of `modus-nord-palette' (or any entry of
`modus-themes-vivendi-palette'), overriding their value.  See
Info node `(modus-themes) Palette overrides' for details."
  :group 'modus-nord
  :package-version '(modus-nord . "0.1.0")
  :type '(repeat (list symbol (choice symbol string)))
  :link '(info-link "(modus-themes) Palette overrides"))

(modus-themes-theme
 'modus-nord
 'modus-nord
 "Dark theme using the Nord palette, derived from `modus-themes'."
 'dark
 'modus-themes-vivendi-palette
 'modus-nord-palette
 'modus-nord-palette-overrides)

;;;###autoload
(when load-file-name
  (let ((dir (file-name-directory load-file-name)))
    (unless (file-equal-p dir (expand-file-name "themes/" data-directory))
      (add-to-list 'custom-theme-load-path dir))))

(provide-theme 'modus-nord)
;;; modus-nord-theme.el ends here
