;;; modus-flexoki-theme.el --- Flexoki palette on top of modus-themes -*- lexical-binding:t -*-

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

;; A dark theme using the Flexoki palette by Steph Ango
;; (https://stephango.com/flexoki), built as a derivative of the Modus
;; themes (v5.2+).  Any palette entry not mapped here falls back to
;; `modus-themes-vivendi-palette'.
;;
;; Diffs use a foreground-only convention.  Color role assignments
;; follow the Flexoki spec for syntax highlighting:
;;   tx-3 → comments        re → imports / errors
;;   tx-2 → punctuation     or → functions
;;   gr   → keywords        ye → constants
;;   cy   → strings         bl → variables, attributes
;;   pu   → numbers         ma → language features / builtins
;;
;; Activation:
;;
;;   (require 'modus-themes)
;;   (load-theme 'modus-flexoki :no-confirm)

;;; Code:

(require 'modus-themes)

(defgroup modus-flexoki nil
  "A Flexoki palette theme built on top of `modus-themes'."
  :group 'faces
  :group 'modus-themes
  :prefix "modus-flexoki-"
  :tag "Modus Flexoki")

(defconst modus-flexoki-palette
  '(
;;; Named colors -- the Flexoki palette
;;; https://stephango.com/flexoki

    ;; Base ramp (warm monochromatic)
    (black     "#100F0F")
    (base-950  "#1C1B1A")
    (base-900  "#282726")
    (base-850  "#343331")
    (base-800  "#403E3C")
    (base-700  "#575653")
    (base-600  "#6F6E69")
    (base-500  "#878580")
    (base-400  "#9F9D96")
    (base-300  "#B7B5AC")
    (base-200  "#CECDC3")
    (base-150  "#DAD8CE")
    (base-100  "#E6E4D9")
    (base-50   "#F2F0E5")
    (paper     "#FFFCF0")

    ;; Accents -- 400 (primary in dark mode)
    (red-400      "#D14D41")
    (orange-400   "#DA702C")
    (yellow-400   "#D0A215")
    (green-400    "#879A39")
    (cyan-400     "#3AA99F")
    (blue-400     "#4385BE")
    (purple-400   "#8B7EC8")
    (magenta-400  "#CE5D97")

    ;; Accents -- 600 (alternate in dark mode)
    (red-600      "#AF3029")
    (orange-600   "#BC5215")
    (yellow-600   "#AD8301")
    (green-600    "#66800B")
    (cyan-600     "#24837B")
    (blue-600     "#205EA6")
    (purple-600   "#5E409D")
    (magenta-600  "#A02F6F")

    ;; Flexoki role aliases for the dark theme
    (bg    black)
    (bg-2  base-950)
    (ui    base-900)
    (ui-2  base-850)
    (ui-3  base-800)
    (tx-3  base-700)
    (tx-2  base-500)
    (tx    base-200)

    (re    red-400)     (re-2  red-600)
    (or    orange-400)  (or-2  orange-600)
    (ye    yellow-400)  (ye-2  yellow-600)
    (gr    green-400)   (gr-2  green-600)
    (cy    cyan-400)    (cy-2  cyan-600)
    (bl    blue-400)    (bl-2  blue-600)
    (pu    purple-400)  (pu-2  purple-600)
    (ma    magenta-400) (ma-2  magenta-600)

;;; Semantic mappings

    ;; Basic surfaces
    (bg-main          bg)
    (bg-dim           bg-2)
    (fg-main          tx)
    (fg-dim           tx-3)
    (fg-alt           tx-2)
    (bg-active        ui-3)
    (bg-inactive      ui)
    (border           ui-3)

    ;; Special purpose backgrounds
    (bg-completion        ui)
    (bg-popup             bg-2)
    (bg-hover             ui-2)
    (bg-hover-secondary   ui-3)
    (bg-hl-line           bg-2)
    (bg-region            ui-2)
    (fg-region            fg-main)

    ;; Mode line
    (bg-mode-line-active        ui-2)
    (fg-mode-line-active        tx)
    (border-mode-line-active    ui-3)
    (bg-mode-line-inactive      ui)
    (fg-mode-line-inactive      tx-3)
    (border-mode-line-inactive  ui)

    (modeline-err     re)
    (modeline-warning or)
    (modeline-info    cy)

    ;; Tab bar
    (bg-tab-bar      bg-2)
    (bg-tab-current  bg-main)
    (bg-tab-other    ui)

    ;; Diffs (foreground-only)
    (bg-added         bg-main)
    (bg-added-faint   bg-main)
    (bg-added-refine  bg-main)
    (bg-added-fringe  gr)
    (fg-added         gr)
    (fg-added-intense gr)

    (bg-changed         bg-main)
    (bg-changed-faint   bg-main)
    (bg-changed-refine  bg-main)
    (bg-changed-fringe  ye)
    (fg-changed         ye)
    (fg-changed-intense ye)

    (bg-removed         bg-main)
    (bg-removed-faint   bg-main)
    (bg-removed-refine  bg-main)
    (bg-removed-fringe  re)
    (fg-removed         re)
    (fg-removed-intense re)

    (bg-diff-context    bg-2)

    ;; Paren match
    (bg-paren-match        ui-3)
    (bg-paren-expression   ui)
    (underline-paren-match unspecified)

    ;; General mappings
    (cursor     tx)
    (keybind    bl)
    (name       cy)
    (identifier bl)

    (err     re)
    (warning or)
    (info    cy)

    (underline-err     re)
    (underline-warning or)
    (underline-note    cy)

    (bg-prominent-err     re)
    (fg-prominent-err     bg)
    (bg-prominent-warning or)
    (fg-prominent-warning bg)
    (bg-prominent-note    cy)
    (fg-prominent-note    bg)

    (bg-active-argument ui)
    (fg-active-argument or)
    (bg-active-value    ui)
    (fg-active-value    cy)

    ;; Code (per Flexoki syntax highlighting spec)
    (builtin       ma)
    (comment       tx-3)
    (constant      ye)
    (docstring     tx-3)
    (fnname        or)
    (fnname-call   or)
    (keyword       gr)
    (preprocessor  re)
    (property      bl)
    (rx-backslash  ma)
    (rx-construct  or)
    (string        cy)
    (type          ma)
    (variable      bl)
    (variable-use  bl)
    (number        pu)
    (operator      tx-2)
    (bracket       tx-2)
    (delimiter     tx-2)

    ;; Accents
    (accent-0 bl)
    (accent-1 or)
    (accent-2 gr)
    (accent-3 ma)

    ;; Completion match
    (fg-completion-match-0 bl)
    (fg-completion-match-1 or)
    (fg-completion-match-2 gr)
    (fg-completion-match-3 ma)

    ;; Date
    (date-common           cy)
    (date-deadline         re)
    (date-deadline-subtle  re-2)
    (date-event            fg-alt)
    (date-holiday          ma)
    (date-holiday-other    pu)
    (date-range            fg-alt)
    (date-scheduled        ye)
    (date-scheduled-subtle ye-2)
    (date-weekday          cy)
    (date-weekend          ma)

    ;; Links
    (fg-link                 cy)
    (underline-link          cy)
    (fg-link-symbolic        bl)
    (underline-link-symbolic bl)
    (fg-link-visited         pu)
    (underline-link-visited  pu)

    ;; Mail
    (mail-cite-0    bl)
    (mail-cite-1    ye)
    (mail-cite-2    cy)
    (mail-cite-3    ma)
    (mail-part      gr)
    (mail-recipient pu)
    (mail-subject   or)
    (mail-other     tx-3)

    ;; Mark
    (bg-mark-delete bg-main)
    (fg-mark-delete re)
    (bg-mark-select bg-main)
    (fg-mark-select cy)
    (bg-mark-other  bg-main)
    (fg-mark-other  ye)

    ;; Prompt
    (fg-prompt bl)

    ;; Prose
    (fg-prose-code        cy)
    (fg-prose-macro       ma)
    (fg-prose-verbatim    gr)
    (prose-done           gr)
    (prose-todo           re)
    (prose-metadata       tx-3)
    (prose-metadata-value fg-alt)
    (prose-table          fg-alt)
    (prose-table-formula  ma)
    (prose-tag            tx-3)

    ;; Rainbow
    (rainbow-0 tx)
    (rainbow-1 re)
    (rainbow-2 or)
    (rainbow-3 ye)
    (rainbow-4 gr)
    (rainbow-5 cy)
    (rainbow-6 bl)
    (rainbow-7 pu)
    (rainbow-8 ma)

    ;; Headings
    (fg-heading-0 cy)
    (fg-heading-1 tx)
    (fg-heading-2 ye)
    (fg-heading-3 bl)
    (fg-heading-4 ma)
    (fg-heading-5 gr)
    (fg-heading-6 or)
    (fg-heading-7 pu)
    (fg-heading-8 tx-3))
  "The `modus-flexoki' palette.
Named colors have the form (NAME HEX-VALUE).  Semantic mappings
have the form (MAPPING-NAME COLOR-NAME).  Anything not defined
here is inherited from `modus-themes-vivendi-palette'.")

(defcustom modus-flexoki-palette-overrides nil
  "Overrides for `modus-flexoki-palette'.

Mirror the elements of `modus-flexoki-palette' (or any entry of
`modus-themes-vivendi-palette'), overriding their value.  See
Info node `(modus-themes) Palette overrides' for details."
  :group 'modus-flexoki
  :package-version '(modus-flexoki . "0.1.0")
  :type '(repeat (list symbol (choice symbol string)))
  :link '(info-link "(modus-themes) Palette overrides"))

(modus-themes-theme
 'modus-flexoki
 'modus-flexoki
 "Dark theme using the Flexoki palette, derived from `modus-themes'."
 'dark
 'modus-themes-vivendi-palette
 'modus-flexoki-palette
 'modus-flexoki-palette-overrides)

;;;###autoload
(when load-file-name
  (let ((dir (file-name-directory load-file-name)))
    (unless (file-equal-p dir (expand-file-name "themes/" data-directory))
      (add-to-list 'custom-theme-load-path dir))))

(provide-theme 'modus-flexoki)
;;; modus-flexoki-theme.el ends here
