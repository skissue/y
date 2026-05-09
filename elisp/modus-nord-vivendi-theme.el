;;; modus-nord-vivendi-theme.el --- Nord-inspired dark theme built on modus-themes -*- lexical-binding: t -*-

;; Author: Ad <me@skissue.xyz>
;; Maintainer: Ad <me@skissue.xyz>
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (modus-themes "5.2.0"))
;; Homepage: https://github.com/skissue/gxy
;; Keywords: faces themes

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; Commentary:

;; A dark theme inspired by the Nord color palette, built on top of the
;; modus-themes framework.  Uses modus-themes-generate-palette (v5.2+)
;; to derive a complete palette from Nord's eight base hues.
;;
;; Nord colors used:
;;   bg-main  → Nord0  #2E3440  Polar Night (darkest)
;;   fg-main  → Nord6  #ECEFF4  Snow Storm (brightest)
;;   red      → Nord11 #BF616A  Aurora red
;;   green    → Nord14 #A3BE8C  Aurora green
;;   yellow   → Nord13 #EBCB8B  Aurora yellow
;;   blue     → Nord10 #5E81AC  Frost dark blue
;;   magenta  → Nord15 #B48EAD  Aurora purple
;;   cyan     → Nord8  #88C0D0  Frost light blue

;;; Code:

(require 'modus-themes)

(defcustom modus-nord-vivendi-palette-user nil
  "Like `modus-nord-vivendi-palette' for user-defined entries.
Extend the palette with custom named colors and/or semantic palette
mappings.  Those may then be used in combination with palette overrides
\(see `modus-themes-common-palette-overrides' and
`modus-nord-vivendi-palette-overrides')."
  :group 'modus-themes
  :type '(repeat (list symbol (choice symbol string))))

(defcustom modus-nord-vivendi-palette-overrides nil
  "Overrides for `modus-nord-vivendi-palette'.
Mirror the elements of the aforementioned palette, overriding their value.
For overrides shared across all Modus themes, see
`modus-themes-common-palette-overrides'.
Theme-specific overrides take precedence over shared overrides."
  :group 'modus-themes
  :type '(repeat (list symbol (choice symbol string))))

(defconst modus-nord-vivendi-palette
  (modus-themes-generate-palette
   '((bg-main "#2E3440")    ; Nord0  - Polar Night
     (fg-main "#ECEFF4")    ; Nord6  - Snow Storm
     (red     "#BF616A")    ; Nord11 - Aurora
     (green   "#A3BE8C")    ; Nord14 - Aurora
     (yellow  "#EBCB8B")    ; Nord13 - Aurora
     (blue    "#5E81AC")    ; Nord10 - Frost
     (magenta "#B48EAD")    ; Nord15 - Aurora
     (cyan    "#88C0D0")))  ; Nord8  - Frost
  "Color palette for `modus-nord-vivendi-theme'.")

(modus-themes-theme
 'modus-nord-vivendi
 'modus-themes
 "Dark theme inspired by the Nord palette, built on modus-themes.
Uses the cool, arctic colors of Nord's Polar Night backgrounds and
Frost/Aurora accents.  Conforms with WCAG AAA contrast standards."
 'dark
 'modus-nord-vivendi-palette
 'modus-nord-vivendi-palette-user
 'modus-nord-vivendi-palette-overrides)

(provide 'modus-nord-vivendi-theme)

;;; modus-nord-vivendi-theme.el ends here
