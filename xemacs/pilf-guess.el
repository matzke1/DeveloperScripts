;;; Guess indentation

(defun pgi-guess-tabbed-indent-ratio (width)
  "The ratio of HT-indented lines to indented lines.

Returns the number of lines indented with tab characters as a
ratio of the total number of lines indented with at least one tab
or WIDTH space characters.  If no lines are sufficiently indented
then returns zero."
  (let* ((n-tabbed-lines (how-many "^\t"))
	 (n-nontabbed-lines (how-many (concat "^" (make-string width ?\s))))
	 (n-indented-lines (+ n-tabbed-lines n-nontabbed-lines)))
    (if (= n-indented-lines 0)
	0
      (/ (float n-tabbed-lines) n-indented-lines))))

(defun pgi-guess-tab-width ()
  "Returns the tab width if HT is consistently used for indentation.

Returns either 4 or 8 if at least 95% of indented lines in the
specified region (or the whole buffer) begin with a tab
character.  Otherwise returns nil."
  (let ((tab4-ratio (pgi-guess-tabbed-indent-ratio 4))
	(tab8-ratio (pgi-guess-tabbed-indent-ratio 8)))
    (cond ((and (>= tab8-ratio 0.95) (< tab4-ratio 0.95)) 8)
	  ((and (>= tab8-ratio 0.95) (>= tab4-ratio 0.95)) 4)
	  (t nil))))

(defun pgi-important-indentation ()
  "Returns a line's indentation if the line is important for calculating indentation.

This function assumes that the tab width has already been set
correctly since it uses the current-column function."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward "[:blank:]")
    (if (and (not (c-in-literal))
	     (not (looking-at "//"))
	     (not (looking-at "/\\*"))
	     (not (looking-at "{")))
	(current-column)
      nil)))

(defun pgi-decide-base-indentation (indentation-mods)
  "Decides the base indentation when given a vector of indentation amounts.

Element I of the vector is the number of important lines having an indentation
amount that is a multiple of i+1."
  (let* ((i (- (length indentation-mods) 1))
	 (nlines (aref indentation-mods 0))
	 (threshold 0.6)
	 (best))
    (while (and (>= i 0) (null best) (> nlines 0))
      (when (>= (/ (float (aref indentation-mods i)) nlines) threshold)
	(setq best (+ i 1)))
      (setq i (- i 1)))
    best))


(defun pgi-guess-parameters ()
  "Guess various things about indentation.

This function tries to guess everything we need in a single pass through the buffer."

  (save-excursion
    (let* ((indentation-mods (make-vector 8 0)); elmt #i is number of important lines with non-zero indentation modulo i+1
	   (braces-alist '((block-open after)
			   (block-close before after)      ;probably should be c-snug-do-while
			   (brace-list-intro)              ;things like 'int **x = {{'
			   (brace-list-close)
			   (defun-open after)              ;that start a function body normally hang
			   (defun-close before after)	   ;that close a function body are on a line by themselves
			   (extern-lang-open after)	   ;after things like 'extern "C"'
			   (extern-lang-close before after)
			   (namespace-open after)	   ;things like 'namespace foo {'
			   (namespace-close before after)
			   (statement-case-open after)     ;as in 'case x: {'
			   (statement-cont)                ;things like 'int *x = {'
			   (substatement-open after)	   ;that follow 'if', 'for', etc.

			   (brace-list-open)               ;?

			   (brace-entry-open)              ;?
			   (module-open after)		   ;?
			   (composition-open after)	   ;?
			   (inexpr-class-open after)	   ;?
			   (inexpr-class-close before))))  ;?

      (goto-char (point-min))
      (while (progn
	       ;; Each of the cases below assume that point is at the first non-blank character of the line and
	       ;; should save-excursion if they move point.
	       (beginning-of-line)
	       (skip-chars-forward "[:blank:]")

	       ;; Save amount of indentation for this line if the line is important for computing the base indentation
	       (let ((indentation (pgi-important-indentation)))
		 (when (and (not (null indentation)) (> indentation 0))
		   (when (= 0 (% indentation 8)) (aset indentation-mods 7 (+ 1 (aref indentation-mods 7))))
		   (when (= 0 (% indentation 7)) (aset indentation-mods 6 (+ 1 (aref indentation-mods 6))))
		   (when (= 0 (% indentation 6)) (aset indentation-mods 5 (+ 1 (aref indentation-mods 5))))
		   (when (= 0 (% indentation 5)) (aset indentation-mods 4 (+ 1 (aref indentation-mods 4))))
		   (when (= 0 (% indentation 4)) (aset indentation-mods 3 (+ 1 (aref indentation-mods 3))))
		   (when (= 0 (% indentation 3)) (aset indentation-mods 2 (+ 1 (aref indentation-mods 2))))
		   (when (= 0 (% indentation 2)) (aset indentation-mods 1 (+ 1 (aref indentation-mods 1))))
		   (aset indentation-mods 0 (+ 1 (aref indentation-mods 0)))))

	       ;; If this line starts with a brace, then figure out what type it is and add the 'before symbol to
	       ;; its value in the the braces-alist.
	       (when (looking-at "{")
		 (let ((syntax (c-guess-basic-syntax))) ; returns a list of (syntax-element position) pairs.
		   (while syntax
		     (let* ((syntax-elmt (car (car syntax)))
			    (hanging (assoc syntax-elmt braces-alist))
			    (value (cdr hanging)))
		       (message "curly brace at beginning of line for %s" syntax-elmt)
		       (when hanging
			 (setq braces-alist (cons (list syntax-elmt (delete-dups (append '(before) value))) braces-alist))))
		     (setq syntax (cdr syntax)))))

	       (= (forward-line) 0)))

      (message "hanging-braces:")
      (mapcar (lambda (x) (message "  %s" x)) braces-alist)

      (pgi-decide-base-indentation indentation-mods))))

      



      




(defun pilf-guess-indentation-ratio (amount &optional pointmin pointmax)
  "Returns indentation for the specified indentation amount.

Considers all important indented lines of the source code and
returns the number of lines (as a ratio) indented a multiple of
the specified amount."
  (let ((n-matching-lines 0)
	(n-indented-lines 0))
    (save-excursion
      (goto-char (or pointmin (point-min)))
      (beginning-of-line)
      (while (re-search-forward "^[\t ]+" pointmax t)
	(let ((indentation (pilf-guess-important-indentation)))
	  (when (and (not (null indentation)) (> indentation 0))
	    (setq n-indented-lines (+ n-indented-lines 1))
	    (when (= 0 (% indentation amount))
	      (setq n-matching-lines (+ n-matching-lines 1)))))))
    (if (= 0 n-indented-lines)
	nil
      (/ (float n-matching-lines) n-indented-lines))))

(defun pilf-guess-base-indentation (&optional default pointmin pointmax)
  "Returns the base indentation.

If not enough lines are present to determine base indentation then the default is returned."
  (let ((threshold 0.4))
    (cond ((>= (or (pilf-guess-indentation-ratio 8) 0) threshold) 8)
	  ((>= (or (pilf-guess-indentation-ratio 7) 0) threshold) 7)
	  ((>= (or (pilf-guess-indentation-ratio 6) 0) threshold) 6)
	  ((>= (or (pilf-guess-indentation-ratio 5) 0) threshold) 5)
	  ((>= (or (pilf-guess-indentation-ratio 4) 0) threshold) 4)
	  ((>= (or (pilf-guess-indentation-ratio 3) 0) threshold) 3)
	  ((>= (or (pilf-guess-indentation-ratio 2) 0) threshold) 2)
	  ((>= (or (pilf-guess-indentation-ratio 1) 0) threshold) 1))))
