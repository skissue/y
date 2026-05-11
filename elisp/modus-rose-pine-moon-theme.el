;;; modus-rose-pine-moon-theme.el --- Rose Pine Moon palette on top of modus-themes -*- lexical-binding:t -*-

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

;; A dark theme using the Rose Pine "Moon" palette
;; (https://rosepinetheme.com/), built as a derivative of the Modus
;; themes (v5.2+).  Moon is a slightly lighter and more saturated
;; sibling of Rose Pine "Main".  Any palette entry not mapped here
;; falls back to `modus-themes-vivendi-palette'.
;;
;; Diffs use a foreground-only convention.  Color role assignments
;; follow the Rose Pine spec:
;;   love → errors, builtins, git delete
;;   gold → strings, warnings
;;   rose → booleans, git change
;;   pine → functions, git rename
;;   foam → object keys, info, git add
;;   iris → parameters, links, hints, git merge
;;
;; Activation:
;;
;;   (require 'modus-themes)
;;   (load-theme 'modus-rose-pine-moon :no-confirm)

;;; Code:

(require 'modus-themes)

(defgroup modus-rose-pine-moon nil
  "A Rose Pine Moon palette theme built on top of `modus-themes'."
  :group 'faces
  :group 'modus-themes
  :prefix "modus-rose-pine-moon-"
  :tag "Modus Rose Pine Moon")

(defconst modus-rose-pine-moon-palette
  '(
;;; Named colors -- the Rose Pine "Moon" palette
;;; https://rosepinetheme.com/palette/ingredients/

    ;; Base surfaces
    (base            "#232136")
    (surface         "#2a273f")
    (overlay         "#393552")

    ;; Foregrounds
    (muted           "#6e6a86")
    (subtle          "#908caa")
    (text            "#e0def4")

    ;; Accents
    (love            "#eb6f92")
    (gold            "#f6c177")
    (rose            "#ea9a97")
    (pine            "#3e8fb0")
    (foam            "#9ccfd8")
    (iris            "#c4a7e7")

    ;; Highlights
    (highlight-low   "#2a283e")
    (highlight-med   "#44415a")
    (highlight-high  "#56526e")

;;; Semantic mappings

    ;; Basic surfaces
    (bg-main          base)
    (bg-dim           surface)
    (fg-main          text)
    (fg-dim           muted)
    (fg-alt           subtle)
    (bg-active        highlight-med)
    (bg-inactive      surface)
    (border           highlight-high)

    ;; Special purpose backgrounds
    (bg-completion        highlight-low)
    (bg-popup             surface)
    (bg-hover             highlight-med)
    (bg-hover-secondary   overlay)
    (bg-hl-line           highlight-low)
    (bg-region            highlight-med)
    (fg-region            fg-main)

    ;; Mode line
    (bg-mode-line-active        overlay)
    (fg-mode-line-active        text)
    (border-mode-line-active    highlight-high)
    (bg-mode-line-inactive      surface)
    (fg-mode-line-inactive      muted)
    (border-mode-line-inactive  surface)

    (modeline-err     love)
    (modeline-warning gold)
    (modeline-info    foam)

    ;; Tab bar
    (bg-tab-bar      surface)
    (bg-tab-current  bg-main)
    (bg-tab-other    overlay)

    ;; Diffs (foreground-only; per Rose Pine git role spec)
    (bg-added         bg-main)
    (bg-added-faint   bg-main)
    (bg-added-refine  bg-main)
    (bg-added-fringe  foam)
    (fg-added         foam)
    (fg-added-intense foam)

    (bg-changed         bg-main)
    (bg-changed-faint   bg-main)
    (bg-changed-refine  bg-main)
    (bg-changed-fringe  rose)
    (fg-changed         rose)
    (fg-changed-intense rose)

    (bg-removed         bg-main)
    (bg-removed-faint   bg-main)
    (bg-removed-refine  bg-main)
    (bg-removed-fringe  love)
    (fg-removed         love)
    (fg-removed-intense love)

    (bg-diff-context    surface)

    ;; Paren match
    (bg-paren-match        highlight-med)
    (bg-paren-expression   highlight-low)
    (underline-paren-match unspecified)

    ;; General mappings
    (cursor     rose)
    (keybind    foam)
    (name       pine)
    (identifier iris)

    (err     love)
    (warning gold)
    (info    foam)

    (underline-err     love)
    (underline-warning gold)
    (underline-note    foam)

    (bg-prominent-err     love)
    (fg-prominent-err     base)
    (bg-prominent-warning gold)
    (fg-prominent-warning base)
    (bg-prominent-note    foam)
    (fg-prominent-note    base)

    (bg-active-argument highlight-low)
    (fg-active-argument gold)
    (bg-active-value    highlight-low)
    (fg-active-value    foam)

    ;; Code
    (builtin       love)
    (comment       muted)
    (constant      iris)
    (docstring     subtle)
    (fnname        pine)
    (fnname-call   rose)
    (keyword       pine)
    (preprocessor  iris)
    (property      foam)
    (rx-backslash  love)
    (rx-construct  gold)
    (string        gold)
    (type          foam)
    (variable      text)
    (variable-use  text)
    (number        iris)
    (operator      subtle)
    (bracket       subtle)
    (delimiter     subtle)

    ;; Accents
    (accent-0 foam)
    (accent-1 rose)
    (accent-2 gold)
    (accent-3 iris)

    ;; Completion match
    (fg-completion-match-0 foam)
    (fg-completion-match-1 rose)
    (fg-completion-match-2 gold)
    (fg-completion-match-3 iris)

    ;; Date
    (date-common           foam)
    (date-deadline         love)
    (date-deadline-subtle  love)
    (date-event            subtle)
    (date-holiday          rose)
    (date-holiday-other    iris)
    (date-range            subtle)
    (date-scheduled        gold)
    (date-scheduled-subtle gold)
    (date-weekday          foam)
    (date-weekend          rose)

    ;; Links
    (fg-link                 foam)
    (underline-link          foam)
    (fg-link-symbolic        pine)
    (underline-link-symbolic pine)
    (fg-link-visited         iris)
    (underline-link-visited  iris)

    ;; Mail
    (mail-cite-0    foam)
    (mail-cite-1    gold)
    (mail-cite-2    rose)
    (mail-cite-3    iris)
    (mail-part      pine)
    (mail-recipient iris)
    (mail-subject   rose)
    (mail-other     muted)

    ;; Mark
    (bg-mark-delete bg-main)
    (fg-mark-delete love)
    (bg-mark-select bg-main)
    (fg-mark-select foam)
    (bg-mark-other  bg-main)
    (fg-mark-other  gold)

    ;; Prompt
    (fg-prompt iris)

    ;; Prose
    (fg-prose-code        foam)
    (fg-prose-macro       iris)
    (fg-prose-verbatim    gold)
    (prose-done           foam)
    (prose-todo           love)
    (prose-metadata       muted)
    (prose-metadata-value subtle)
    (prose-table          subtle)
    (prose-table-formula  iris)
    (prose-tag            muted)

    ;; Rainbow
    (rainbow-0 text)
    (rainbow-1 love)
    (rainbow-2 gold)
    (rainbow-3 rose)
    (rainbow-4 foam)
    (rainbow-5 iris)
    (rainbow-6 pine)
    (rainbow-7 subtle)
    (rainbow-8 muted)

    ;; Headings
    (fg-heading-0 iris)
    (fg-heading-1 text)
    (fg-heading-2 gold)
    (fg-heading-3 foam)
    (fg-heading-4 rose)
    (fg-heading-5 pine)
    (fg-heading-6 love)
    (fg-heading-7 iris)
    (fg-heading-8 muted))
  "The `modus-rose-pine-moon' palette.
Named colors have the form (NAME HEX-VALUE).  Semantic mappings
have the form (MAPPING-NAME COLOR-NAME).  Anything not defined
here is inherited from `modus-themes-vivendi-palette'.")

(defcustom modus-rose-pine-moon-palette-overrides nil
  "Overrides for `modus-rose-pine-moon-palette'.

Mirror the elements of `modus-rose-pine-moon-palette' (or any entry of
`modus-themes-vivendi-palette'), overriding their value.  See
Info node `(modus-themes) Palette overrides' for details."
  :group 'modus-rose-pine-moon
  :package-version '(modus-rose-pine-moon . "0.1.0")
  :type '(repeat (list symbol (choice symbol string)))
  :link '(info-link "(modus-themes) Palette overrides"))

(modus-themes-theme
 'modus-rose-pine-moon
 'modus-rose-pine-moon
 "Dark theme using the Rose Pine Moon palette, derived from `modus-themes'."
 'dark
 'modus-themes-vivendi-palette
 'modus-rose-pine-moon-palette
 'modus-rose-pine-moon-palette-overrides)

;;;###autoload
(when load-file-name
  (let ((dir (file-name-directory load-file-name)))
    (unless (file-equal-p dir (expand-file-name "themes/" data-directory))
      (add-to-list 'custom-theme-load-path dir))))

(provide-theme 'modus-rose-pine-moon)
;;; modus-rose-pine-moon-theme.el ends here
