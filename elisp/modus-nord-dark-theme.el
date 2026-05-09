;;; modus-nord-dark-theme.el --- Nord-inspired dark theme built on modus-themes -*- lexical-binding: t -*-

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

;; A dark theme built on modus-themes using all 16 Nord colors.
;;
;; The palette is constructed by prepending exact Nord color assignments
;; over the output of `modus-themes-generate-palette', which fills in the
;; full structural palette from the eight base hues.
;;
;; Color mapping:
;;
;; Polar Night (dark backgrounds):
;;   Nord0  #2E3440 → bg-main       primary background
;;   Nord1  #3B4252 → bg-dim        dimmed/secondary background
;;                  → bg-inactive   inactive UI elements
;;   Nord2  #434C5E → bg-alt        alternate background
;;                  → bg-active     active UI elements
;;   Nord3  #4C566A → border        borders and subtle dividers
;;
;; Snow Storm (light foregrounds):
;;   Nord4  #D8DEE9 → fg-dim        dimmed foreground
;;   Nord5  #E5E9F0 → fg-alt        alternate foreground
;;   Nord6  #ECEFF4 → fg-main       primary foreground
;;
;; Frost (cool blues/teals):
;;   Nord7  #8FBCBB → cyan-cooler   teal, cooler than Nord8
;;   Nord8  #88C0D0 → cyan          light blue (base hue)
;;   Nord9  #81A1C1 → blue-warmer   medium frost, warmer than Nord10
;;   Nord10 #5E81AC → blue          dark frost blue (base hue)
;;
;; Aurora (accent colors):
;;   Nord11 #BF616A → red           Aurora red (base hue)
;;   Nord12 #D08770 → yellow-warmer orange, warm Aurora hue
;;   Nord13 #EBCB8B → yellow        Aurora yellow (base hue)
;;   Nord14 #A3BE8C → green         Aurora green (base hue)
;;   Nord15 #B48EAD → magenta       Aurora purple (base hue)

;;; Code:

(require 'modus-themes)

(defcustom modus-nord-dark-palette-user nil
  "Like `modus-nord-dark-palette' for user-defined entries.
Extend the palette with custom named colors and/or semantic palette
mappings.  Those may then be used in combination with palette overrides
\(see `modus-themes-common-palette-overrides' and
`modus-nord-dark-palette-overrides')."
  :group 'modus-themes
  :type '(repeat (list symbol (choice symbol string))))

(defcustom modus-nord-dark-palette-overrides nil
  "Overrides for `modus-nord-dark-palette'.
Mirror the elements of the aforementioned palette, overriding their value.
For overrides shared across all Modus themes, see
`modus-themes-common-palette-overrides'.
Theme-specific overrides take precedence over shared overrides."
  :group 'modus-themes
  :type '(repeat (list symbol (choice symbol string))))

(defconst modus-nord-dark-palette
  (append
   '(;; Polar Night: all four dark shades mapped to background roles
     (bg-main     "#2E3440")   ; Nord0
     (bg-dim      "#3B4252")   ; Nord1
     (bg-alt      "#434C5E")   ; Nord2
     (bg-active   "#434C5E")   ; Nord2
     (bg-inactive "#3B4252")   ; Nord1
     (border      "#4C566A")   ; Nord3

     ;; Snow Storm: all three light shades mapped to foreground roles
     (fg-main "#ECEFF4")       ; Nord6
     (fg-dim  "#D8DEE9")       ; Nord4
     (fg-alt  "#E5E9F0")       ; Nord5

     ;; Frost: Nord7 and Nord9 fill the cyan/blue variant slots not
     ;; covered by the two base hues passed to generate-palette
     (cyan-cooler "#8FBCBB")   ; Nord7 - teal
     (blue-warmer "#81A1C1")   ; Nord9 - medium frost blue

     ;; Aurora: Nord12 (orange) takes the warm yellow slot
     (yellow-warmer "#D08770")) ; Nord12

   ;; Generate the full structural palette from Nord's eight base hues.
   ;; Entries prepended above take precedence over any generated overlap.
   (modus-themes-generate-palette
    '((bg-main  "#2E3440")     ; Nord0
      (fg-main  "#ECEFF4")     ; Nord6
      (red      "#BF616A")     ; Nord11
      (green    "#A3BE8C")     ; Nord14
      (yellow   "#EBCB8B")     ; Nord13
      (blue     "#5E81AC")     ; Nord10
      (magenta  "#B48EAD")     ; Nord15
      (cyan     "#88C0D0"))))  ; Nord8
  "Color palette for `modus-nord-dark-theme'.")

(modus-themes-theme
 'modus-nord-dark
 'modus-themes
 "Dark theme built on the complete Nord color palette.
All 16 Nord colors are mapped to modus palette roles: Polar Night
shades cover backgrounds, Snow Storm covers foregrounds, Frost provides
cool blue/teal accents, and Aurora provides the accent hues."
 'dark
 'modus-nord-dark-palette
 'modus-nord-dark-palette-user
 'modus-nord-dark-palette-overrides)

(provide 'modus-nord-dark-theme)

;;; modus-nord-dark-theme.el ends here
