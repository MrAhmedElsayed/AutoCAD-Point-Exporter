;; Name: Ahmed Elsayed
;; Date: 7/10/2024
;; Description: AutoLISP program 'pt.lsp' for AutoCAD, designed to automate point creation, exporting, and table generation, ensuring reliable and accurate data integration within AutoCAD environments.

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

;;; Function to create a points table
(defun CreatePointTable (insertionPoint ptList)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq space (vla-get-ModelSpace doc))

  ;; Convert insertion point to a 3D point
  (setq insertionPoint (vlax-3D-point insertionPoint))

  ;; Create the table object
  (setq tbl (vla-AddTable space insertionPoint (+ 2 (length ptList)) 4 1.0 2.0))

  ;; Set the table title
  (vla-SetText tbl 0 0 "Points Table")
  (vla-MergeCells tbl 0 0 0 3)
  (vla-SetCellAlignment tbl 0 0 acMiddleCenter)

  ;; Set the headers
  (vla-SetText tbl 1 0 "No.")
  (vla-SetText tbl 1 1 "X")
  (vla-SetText tbl 1 2 "Y")
  (vla-SetText tbl 1 3 "Z")
  (vla-SetCellAlignment tbl 1 0 acMiddleCenter)
  (vla-SetCellAlignment tbl 1 1 acMiddleCenter)
  (vla-SetCellAlignment tbl 1 2 acMiddleCenter)
  (vla-SetCellAlignment tbl 1 3 acMiddleCenter)
  
  ;; Add point data
  (setq i 2)
  (foreach pt ptList
    (vla-SetText tbl i 0 (car pt)) ;; Numbering starts from 1
    (vla-SetText tbl i 1 (rtos (cadr pt) 2 2))
    (vla-SetText tbl i 2 (rtos (caddr pt) 2 2))
    (vla-SetText tbl i 3 (rtos (cadddr pt) 2 2))
    (vla-SetCellAlignment tbl i 0 acMiddleCenter)
    (vla-SetCellAlignment tbl i 1 acMiddleCenter)
    (vla-SetCellAlignment tbl i 2 acMiddleCenter)
    (vla-SetCellAlignment tbl i 3 acMiddleCenter)
    (setq i (1+ i))
  )

  ;; Redraw the table to reflect changes
  (vla-Update tbl)
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
  (setq pt_list '())

  ;; Loop to select multiple points
  (while (setq p (getpoint (strcat "\nPoint No. " (itoa pn) " : " pre_code (itoa pn))))
    ;; Create point code by combining prefix code and point number
    (setq pt_code (strcat pre_code (itoa pn)))
    ;; Calculate text insertion point
    (setq ptxt (list (- (car p) (* 0.5 hs-factor))
                     (+ (cadr p) (* 0.5 hs-factor))))
    ;; Create point and text entities in AutoCAD
    (command "point" p)
    (command "text" "m" ptxt "0" pt_code)
    ;; Write point data to the file
    (if (equal filetype "TXT")
      (princ (strcat pt_code "\t" (rtos (car p) 2 2) "\t" (rtos (cadr p) 2 2) "\n") file)
      (princ (strcat pt_code "," (rtos (car p) 2 2) "," (rtos (cadr p) 2 2) "\n") file))
    ;; Increment point number
    (setq pn (1+ pn))
    ;; Append point data to the list
    (setq pt_list (append pt_list (list (list pt_code (car p) (cadr p) 0.0))))
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

  ;; Create table using the previously defined function
  (CreatePointTable p_l_up pt_list)

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