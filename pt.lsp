;;; Error handler function to reset variables and print error message
(defun derr (s)
  ;; Check if the error is not "Function cancelled"
  (if (/= s "Function cancelled")
    (princ (strcat "\n*Error: " s))  ; Print the error message
  )
  ;; Reset AutoCAD variables to their original state
  (setvar "cmdecho" echo)
  (setvar "blipmode" blip)
  (setvar "luprec" decimal)
  ;; Restore the original error handler
  (setq *error* olderr)
  ;; Close the file if it is open and not a directory
  (if (and file (not (vl-file-directory-p file)))
    (close file)
  )
  (princ)  ; Print a newline character
)

;;; Function to generate a fallback layer name using the current date and time
(defun generate-fallback-name ()
  ;; Get current date and time
  (setq current-date (rtos (getvar 'date) 2 0))
  (setq dt (vl-string-translate "." "_" current-date))
  ;; Generate the fallback layer name
  (setq fallback-name (strcat "stakeout_" dt))
  fallback-name  ; Return the fallback layer name
)

;;; Function to create and set the "Exported Points" layer with a valid name
(defun create-exported-points-layer ()
  ;; Get the drawing file name
  (setq dwg-name (getvar 'dwgname))
  ;; Check if the drawing file name contains only valid characters (ASCII letters, digits, and underscores)
  (if (not (wcmatch dwg-name "*[^a-zA-Z0-9_]*"))
    (setq layer-name dwg-name)  ; Use the drawing file name as the layer name
    ;; Generate a fallback name if the drawing file name contains invalid characters
    (setq layer-name (generate-fallback-name))
  )
  ;; Check if the layer does not exist, then create and set its color to yellow
  (if (not (tblsearch "layer" layer-name))
    (progn
      (command "._-layer" "m" layer-name "c" "Yellow" layer-name "")
      ;; Set the newly created layer as the current layer
      (command "._-layer" "s" layer-name "")
    )
    ;; If the layer already exists, simply set it as the current layer
    (command "._-layer" "s" layer-name "")
  )
  ;; Return the name of the layer
  layer-name
)

;;; Function to create a text style
(defun create-text-style ()
  ;; Check if the "Standard" text style does not exist
  (if (not (tblsearch "style" "Standard"))
    ;; Create the "Standard" text style with specified properties
    (command "._-style" "Standard" "txt.shx" 0.5 1.0 0.0 "N" "N" "N")
  )
  ;; Set the "Standard" text style as the current text style
  (command "._-style" "Standard" "txt.shx" 0.5 1.0 0.0 "N" "N" "N")
  (setvar "textstyle" "Standard")
)

;;; Function to select the file type (TXT or CSV)
(defun select-file-type ()
  (initget "TXT CSV")  ; Initialize keywords for user input
  ;; Prompt user to select the file type
  (setq filetype (getkword "\nSelect file type [TXT/CSV]: "))
  filetype  ; Return the selected file type
)

;;; Function to browse for a file
; (defun browse-file (ext)
;   ;; Prompt the user to select a file to save
;   (setq file (getfiled "Select or enter points file" (strcat "points." ext) ext 1))
;   file  ; Return the selected file path
; )


;;; Function to browse for a file ==> gave an error *Error: bad argument type: FILE nil
(defun browse-file (ext)
  ;; Get the drawing file name
  (setq dwg-name (getvar 'dwgname))
  
  ;; Check if the drawing file name contains non-ASCII characters (assuming Arabic or problematic characters)
  (if (vl-string-search "[^\x00-\x7F]" dwg-name)
    ;; If non-ASCII characters are found, use a fallback name
    (setq suggested-name (strcat "points." ext))
    ;; Otherwise, use the DWG file name as suggestion
    (setq suggested-name (strcat (vl-string-subst "." "_" dwg-name) "." ext))
  )

  ;; Prompt the user to select a file to save
  (setq file (getfiled "Select or enter points file" suggested-name ext 1))

  file  ; Return the selected file path
)



;;; Main function to export points
(defun c:pt()
  ;; Set up error handling
  (setq olderr *error*
        *error* derr)
  ;; Save current values of AutoCAD system variables
  (setq echo (getvar "cmdecho"))
  (setq blip (getvar "blipmode"))
  (setq decimal (getvar "luprec"))
  ;; Turn off command echoing and blipmode
  (setvar "cmdecho" 0)
  (setvar "blipmode" 0)

  ;; Create the "Exported Points" layer and text style
  (setq layer-name (create-exported-points-layer))
  (create-text-style)

  ;; Prompt user to select the file type
  (setq filetype (select-file-type))
  ;; Check if file type was selected
  (if (not filetype)
    (progn
      (princ "\nError: No file type selected.")
      (exit)
    )
  )
  
  ;; Determine file extension based on selected file type
  (setq file_ext (if (equal filetype "TXT") "txt" "csv"))
  ;; Prompt user to select or enter the points file
  (setq pt_file (browse-file file_ext))
  ;; Default to "points.txt" or "points.csv" if no file is selected
  (if (not pt_file)
    (setq pt_file (strcat "points." file_ext)))
  ;; Open the points file for writing
  (setq file (open pt_file "w"))

  ;; Prompt user for horizontal scale, prefix code, and start number
  (setq h-scale (getint "\nHorizontal Scale 1:"))
  (setq pre_code (getstring "\nPrefix Code:"))
  (setq start_pn (getint "\nStart Number:"))

  ;; Initialize variables
  (setq pn start_pn)
  (setq hs-factor (/ h-scale 100))
  (setq p 0)
  (setq n 1)
  (setq pt_list '())

  ;; Loop to get points from the user
  (while p
    (setq p (getpoint "\nSelect Point <Exit>:"))
    (if p
      (progn
        ;; Generate point code and coordinates
        (setq str_pn (itoa pn))
        (setq pt_code (strcat pre_code str_pn))
        (setq ptxt (list (- (car p) (* 0.5 hs-factor))
                         (+ (cadr p) (* 0.5 hs-factor))))

        ;; Create point and text entities in AutoCAD
        (command "point" p)
        (command "text" "m" ptxt "0" pt_code)

        ;; Write point data to the file
        (if (equal filetype "TXT")
          (princ (strcat pt_code "\t" (rtos (car p)) "\t" (rtos (cadr p)) "\n") file)
          (princ (strcat pt_code "," (rtos (car p)) "," (rtos (cadr p)) "\n") file)
        )
        ;; Increment point number
        (setq pn (+ pn 1))

        ;; Append point data to the list
        (setq pt_list (append pt_list (list (append (list pt_code) p))))
      )
    )
  )

  ;; Prompt user to select upper left corner for the table
  (prompt "\n** Points Coordinates Table **")
  (setq p_l_up (getpoint "\nSelect Upper Left Corner:"))
  ;; Check if the upper left corner is selected
  (if (not p_l_up)
    (progn
      (princ "\nError: Upper Left Corner not selected.")
      (exit)
    )
  )

  ;; Calculate positions for the table
  (setq p_r_up (list (+ (car p_l_up) (* 7.2 hs-factor))
                     (cadr p_l_up)))
  (setq ph1 (list (car p_l_up)
                  (- (cadr p_l_up) (* 1 hs-factor))))
  (setq ph2 (list (car p_r_up)
                  (- (cadr p_r_up) (* 1 hs-factor))))

  (setq ph_txt1 (list (+ (car p_l_up) (* 0.6 hs-factor))
                      (- (cadr p_l_up) (* 0.5 hs-factor))))
  (setq ph_txt2 (list (+ (car p_l_up) (* 2.7 hs-factor))
                      (- (cadr p_l_up) (* 0.5 hs-factor))))
  (setq ph_txt3 (list (+ (car p_l_up) (* 5.7 hs-factor))
                      (- (cadr p_l_up) (* 0.5 hs-factor))))

  ;; Create table header
  (command "line" p_l_up p_r_up "")
  (command "line" ph1 ph2 "")
  (command "text" "m" ph_txt1 "0" "Pt.")
  (command "text" "m" ph_txt2 "0" "X")
  (command "text" "m" ph_txt3 "0" "Y")

  ;; Loop to create table rows
  (setq len_ptlst (length pt_list))
  (setq n_lst 0)
  (repeat len_ptlst
    (setq p1 (list (car p_l_up)
                   (- (cadr p_l_up) (* (+ n_lst 2) hs-factor))))
    (setq p2 (list (car p_r_up)
                   (- (cadr p_r_up) (* (+ n_lst 2) hs-factor))))

    (setq ptxt1 (list (+ (car p1) (* 0.6 hs-factor))
                      (- (cadr p1) (* 0.5 hs-factor))))
    (setq ptxt2 (list (+ (car p1) (* 2.7 hs-factor))
                      (- (cadr p1) (* 0.5 hs-factor))))
    (setq ptxt3 (list (+ (car p1) (* 5.7 hs-factor))
                      (- (cadr p1) (* 0.5 hs-factor))))

    ;; Get the X and Y coordinates of the point
    (setq x (rtos (cadr (nth n_lst pt_list))))
    (setq y (rtos (caddr (nth n_lst pt_list))))

    ;; Write point data to the file
    (if (equal filetype "TXT")
      (princ (strcat (nth 0 (nth n_lst pt_list)) "\t" x "\t" y "\n") file)
      (princ (strcat (nth 0 (nth n_lst pt_list)) "," x "," y "\n") file)
    )

    ;; Create text entities and lines in AutoCAD
    (command "line" p1 p2 "")
    (command "text" "m" ptxt1 "0" (nth 0 (nth n_lst pt_list)))
    (command "text" "m" ptxt2 "0" x)
    (command "text" "m" ptxt3 "0" y)

    ;; Increment the point list index
    (setq n_lst (+ n_lst 1))
  )

  ;; Create vertical lines for the table
  (setq pv1 (list (+ (car p_l_up) (* 1.2 hs-factor))
                  (cadr p_l_up)))
  (setq pv2 (list (+ (car p_l_up) (* 4.2 hs-factor))
                  (cadr p_l_up)))
  (setq pv3 (list (+ (car p1) (* 1.2 hs-factor))
                  (cadr p1)))
  (setq pv4 (list (+ (car p1) (* 4.2 hs-factor))
                  (cadr p1)))

  (command "line" p_l_up p1 "")
  (command "line" pv1 pv3 "")
  (command "line" pv2 pv4 "")
  (command "line" p_r_up p2 "")

  ;; Reset AutoCAD variables to their original state
  (setvar "cmdecho" echo)
  (setvar "blipmode" blip)
  (setvar "luprec" decimal)
  ;; Restore the original error handler
  (setq *error* olderr)
  ;; Close the file
  (close file)
  (princ)  ; Print a newline character
)
