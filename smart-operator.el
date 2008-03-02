;;; smart-operator.el --- Insert operators with surrounding spaces smartly

;; Copyright (C) 2004, 2005, 2007, 2008 William Xu

;; Author: William Xu <william.xwl@gmail.com>
;; Version: 1.0
;; Url: http://williamxu.net9.org/ref/smart-operator.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with EMMS; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; When typing operators, this package can automatically insert spaces
;; before and after operators. For instance, `=' will become ` = ', `+='
;; will become ` += '. This is handy for writing C-style sources.

;; To use, put this file to your load-path and the following to your
;; ~/.emacs:
;;             (require 'smart-operator)
;;
;; Then `M-x smart-operator-mode' for toggling this minor mode.

;; Usage Tips
;; ----------

;; - If you want it to insert operator with surrounding spaces , you'd
;;   better not type the front space yourself, instead, type operator
;;   directly. smart-operator-mode will also take this as a hint on how
;;   to properly generating spaces in some specific occasions. For
;;   example, in c-mode, `a*' -> `a * ', `char *' -> `char *'.

;;; Acknowledgements

;; Nikolaj Schumacher <n_schumacher@web.de>, for suggesting
;; reimplementing as a minor mode and providing an initial patch for
;; that.

;;; Code:

;;; smart-operator minor mode

(setq smart-operator-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap "=" 'smart-operator-self-insert-command)
    (define-key keymap "<" 'smart-operator-<)
    (define-key keymap ">" 'smart-operator->)
    (define-key keymap "%" 'smart-operator-self-insert-command)
    (define-key keymap "+" 'smart-operator-+)
    (define-key keymap "-" 'smart-operator--)
    (define-key keymap "*" 'smart-operator-*)
    (define-key keymap "/" 'smart-operator-self-insert-command)
    (define-key keymap "&" 'smart-operator-&)
    (define-key keymap "|" 'smart-operator-self-insert-command)
    (define-key keymap "!" 'smart-operator-self-insert-command)
    (define-key keymap ":" 'smart-operator-:)
    (define-key keymap "?" 'smart-operator-?)
    (define-key keymap "," 'smart-operator-,)
    (define-key keymap "." 'smart-operator-.)
    keymap))
;  "Keymap used my `smart-operator-mode'.")

;;;###autoload
(define-minor-mode smart-operator-mode
  "Insert operators with surrounding spaces smartly."
  nil "_+_ " smart-operator-mode-map)

(defun smart-operator-mode-on ()
  (smart-operator-mode 1))

;;;###autoload
(defun smart-operator-self-insert-command (arg)
  "Insert the entered operator plus surrounding spaces."
  (interactive "p")
  (smart-operator-insert (string last-command-char)))

(defvar smart-operator-list
  '("=" "<" ">" "%" "+" "-" "*" "/" "&" "|" "!" ":" "?" "," "."))

(defun smart-operator-insert (op &optional only-after)
  "Insert operator OP with surrounding spaces.
e.g., `=' will become ` = ', `+=' will become ` += '.

When ONLY-AFTER, insert space at back only."
  (delete-horizontal-space)
  (if (or (looking-back (regexp-opt smart-operator-list)
                        (save-excursion (beginning-of-line)
                                        (point)))
          only-after
          (bolp))
      (progn (insert (concat op " "))
             (save-excursion
               (backward-char 2)
               (when (bolp)
                 (indent-according-to-mode))))
    (insert (concat " " op " "))))

(defun smart-operator-bol ()
  (save-excursion
    (beginning-of-line)
    (point)))


;;; Fine Tunings

(defun smart-operator-< ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((and (memq major-mode '(c-mode c++-mode))
              (looking-back
               (concat "\\("
                       (regexp-opt
                        '("#include" "vector" "deque" "list" "map"
                          "multimap" "set" "hash_map" "iterator" "template"
                          "pair" "auto_ptr"))
                       "\\)\\ *")
               (smart-operator-bol)))
         (insert "<>")
         (backward-char))
        (t
         (smart-operator-insert "<"))))

(defun smart-operator-: ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((memq major-mode '(c-mode c++-mode))
         (if (looking-back "\\?.+" (smart-operator-bol))
             (smart-operator-c-mode-:)
           (insert ":")))
        (t
         (smart-operator-insert ":" t))))

(defun smart-operator-, ()
  "See `smart-operator-insert'."
  (interactive)
  (smart-operator-insert "," t))

(defun smart-operator-. ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((or (looking-back "[0-9]" (1- (point)))
             (and (memq major-mode '(c-mode c++-mode))
                  (looking-back "[a-z]" (1- (point)))))
         (insert "."))
        (t
         (smart-operator-insert "." t)
         (insert " "))))

(defun smart-operator-& ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((memq major-mode '(c-mode c++-mode))
         (if (or (looking-back " " (1- (point)))
                 (bolp))
             (insert "&")
           (smart-operator-insert "&")))
        (t
         (smart-operator-insert "&"))))

(defun smart-operator-* ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((memq major-mode '(c-mode c++-mode))
         (if (or (looking-back "[0-9a-zA-Z]" (1- (point)))
                 (bolp))
             (smart-operator-insert "*")
           (insert "*")))
        (t
         (smart-operator-insert "*"))))

(defun smart-operator-> ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((and (memq major-mode '(c-mode c++-mode))
              (looking-back " - " (- (point) 3)))
         (save-excursion
           (delete-char -3)
           (insert "->")))
        (t
         (smart-operator-insert ">"))))

(defun smart-operator-+ ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((and (memq major-mode '(c-mode c++-mode))
              (looking-back "+ " (- (point) 2)))
         (delete-char -2)
         (delete-horizontal-space)
         (insert "++")
         (indent-according-to-mode))
        (t
         (smart-operator-insert "+"))))

(defun smart-operator-- ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((and (memq major-mode '(c-mode c++-mode))
              (looking-back "- " (- (point) 2)))
         (delete-char -2)
         (delete-horizontal-space)
         (insert "--")
         (indent-according-to-mode))
        (t
         (smart-operator-insert "-"))))

(defun smart-operator-? ()
  "See `smart-operator-insert'."
  (interactive)
  (cond ((memq major-mode '(c-mode c++-mode))
         (smart-operator-insert "?"))
        (t
         (smart-operator-insert "?" t))))

(provide 'smart-operator)

;;; smart-operator.el ends here