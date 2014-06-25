extensions [ grapher url ] 




globals
[
  ;; These are dummy data that will be temporarily used while fine-tuning PLAY-webapp interface, teachstu experience and database fields
  ;; initialization of these variables is done in method setup-vars
  schoolname
  teachername
  classname
  classyear
  activityname
  activityid
  classroomlist
  schoolteacherlist
  classdetailslist
  
  ;; These variables are for drawing of a sick face on unauthenticated clients
  sickface
  sickfacex
  sickfacey
  unauthenticatedclients          ;; a list to track which clients don't pass authentication
  
  ;; These variables are used in the highlighting of the equations and gallery-exporting
  output-contents
  output-expressions-only
  highlight-group                ;; this will be either "RED" or "GREEN"
  red-highlight-index            ;; to keep track of how many red equations have been pushed to the gallery so far
  green-highlight-index
  gallery-save-number           ;; to keep track of how many times gallery has been used
  r-highlight                   ;; RGB values used when highlighting selected equations
  g-highlight
  b-highlight
  r-default                     ;; RGB values of the default color for the equations
  g-default
  b-default
  r-teacher                     ;; RGB values for teacher's equations
  g-teacher
  b-teacher

  rule                          ;; the text of a verbal rule, given by the teacher
  student-index                 ;; the index of which student's work is visible to the teacher
  equation-index                ;; the index of which f1...f4 is visible.
  
  student-list                  ;; a list of student names

  ;; The following are for assigning unique shape and colors to each individual students
  all-shapes                    ;; a list of the combinations of turtle shapes and colors
  available-shapes              ;; to prevent reusing shapes
  all-colors
  color-names                   ;; all the colors we use. 
  color-rgb-values              ;; same index.  corresponding colors in R-G-B triples for sending to geogebra
  
  numtps                        ;;teacher point counter.  so that teacher points added don't overwrite each other.
  
  current-timestamp             ;; the date-and-time stamp for use in file-saving
  current-data-file             ;;filename (date-and-time based) to which we're saving student data..
  current-login-file            ;;filename (date-and-time based) to which we're saving student LOGIN time stamps..
  current-GGB-file              ;;filename (date-and-time baesd) to which we're saving the GGB window contents

  ;; The following are for Teacher controls
  frozenp?                      ;;if true, students can't move their points.
  frozenf?                      ;; if true, students can't post new functions.
  old-display-geogebra-window?  ;; to facilitate detection of flipping of the display-geogebra-window? switch
  old-Freeze_Functions          ;; to facilitate detection of flipping of the Freeze_Functions switch
  old-Freeze_Points             ;; to facilitate detection of flipping of the Freeze_Points switch
  old-Project_Points            ;; to facilitate detection of flipping of the Project_Points switch
  old-Students_See_Each_Other   ;; to facilitate detection of flipping of the Students_See_Each_Other switch
  old-Student_Points

  ;; The following are used in dynamic resizing of the view plane
  x-scale
  y-scale
  x-offset
  y-offset
  x-maximum-edge                ;; the logical variable which denote boundary of the world, for use in boundary-checking when moving points
  x-minimum-edge
  y-maximum-edge
  y-minimum-edge
  vernum
] ;; end globals




breed [ grids grid ]
breed [ axes axis ]
breed [ students student]




students-own
[
  user-id                ;; unique id, input by student when they log in, to identify each point turtle
  shape-combo            ;; the string describing the shape and color of the student's turtle
  color-rgb-value        ;; rgb triple for color (for sending to ggb)
  equation-list  
  equation-history
  lxcor                  ;; logical x coordinate
  lycor                  ;; logical y coordinate
]




;;;;;;;;;;;;;;;;;;;;;;;;
;;  SETUP Procedures  ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup-hubnet-infrastructure
  hubnet-set-client-interface "COMPUTER" []
  hubnet-reset 
end




to startup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  ca
  reset-highlighting-indexes
  set unauthenticatedclients( list )  ;; initializes the list of unauthorized clients
  setup-vars
  
  ;; Leaving this chunk for future versions
  ;;let sname  user-input "Enter a server name to start a HubNet activity.\n\nThis name will be used for naming data files\ncreated by the activity.\n\nLeave blank to work offline..."
  ;;if (not empty? sname) 
  ;;[setup-hubnet-infrastructure]
  
  setup-hubnet-infrastructure
    set classroomlist make-classroom-list
    ifelse( length classroomlist != 0 )
    [
      set schoolteacherlist make-schoolteacher-list classroomlist
      let chosenschoolteacher ( user-one-of "Please select school and teacher: " schoolteacherlist )
      if( chosenschoolteacher != "" )
      [
        let stpieces split-token chosenschoolteacher "; "
        set schoolname  ( item 1 split-token item 0 stpieces "=" )
        set teachername ( item 1 split-token item 1 stpieces "=" )
      
        set classdetailslist filter-list chosenschoolteacher classroomlist
        let chosenclass ( user-one-of "Please select a class: " classdetailslist ) 
        if( chosenclass != "" )
        [
          let cdpieces split-token chosenclass "; "
          set classname ( item 1 split-token item 0 cdpieces "=" )
          set classyear ( item 1 split-token item 1 cdpieces "=" )
        ]
      ]
      make-GGB-file
      setup
    ]
    [
    
    ]
end




to setup
  save-GGB-window
  clear-GeoGebra-student-data
  clear-NetLogo-student-data
  merge-csv-files
  resize-window
  setup-vars
  setup-grid
  blind-unauthenticated-clients
  set available-shapes all-shapes
  start-activity classname classyear activityname
  start-saving-data
  make-login-file
  relogin
  reset-ticks
  random-distribute-students
  make-GGB-file
end




to setup-vars
  clear-patches  
  set sickfacex 0
  set sickfacey 0
  set sickface make-sickface-patches sickfacex sickfacey ;; make a sickface at the origin

  set current-timestamp get-unique-timestamp
  
;; NOTE: tied classyear to teacher's computer clock
  ;; set classyear substring current-timestamp ( length current-timestamp - 4 ) ( length current-timestamp ) 

  ;; NOTE: time info from teacher's computer clock is used as part of the default activityname
  set activityname ( word schoolname ":" teachername ":" classname ":" classyear ":" current-timestamp )
  
  set activityid 0
  set classroomlist ( list  )

  set output-contents ""
  set output-expressions-only []

  clear-output  
  set-edges
  set rule ""
  set numtps 0

  set student-list []
  set student-index -1
  set color-names [ "red" "orange" "yellow" "brown" "green" "blue" "pink" "purple" ]
  set all-colors [ red orange yellow brown green blue pink violet ]
  set color-rgb-values [ [255 0 0] [255 69 0] [255 255 0] [ 160 82 45 ] [50 205 50] [65 105 225] [255 182 193] [153 50 204] ]
  set all-shapes [ "heart" "star" "circle" "diamond" "square" "rhombus" "triangle" "heart" ]

  set frozenp? true
  set frozenf? true
  set Freeze_Functions true
  set old-Freeze_Functions true
  set Student_Points true
  set old-Student_Points true
  set Freeze_Points true
  set old-Freeze_Points true  
  set Project_Points false
  set old-Project_Points false
  set old-Students_See_Each_Other false                             
  set current-data-file "temp.csv"

  set old-display-geogebra-window? false
  set gallery-save-number 1
  
  set r-highlight 255
  set g-highlight 255
  set b-highlight 255
  
  set r-default 50
  set g-default 50
  set b-default 255
  
  set r-teacher 80
  set g-teacher 255
  set b-teacher 80
  
  set highlight-group ""
  set vernum "CNECT Collaborative Grapher v3.4"
end




to set-edges
  set x-maximum-edge x-maximum
  set x-minimum-edge x-minimum
  set y-maximum-edge y-maximum
  set y-minimum-edge y-minimum
end




;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  every 0.1
  [
    if( Student_Points != old-Student_Points )
    [
      ifelse( Student_Points = true )
      [
        ask students
        [
          randomize-coordinates
          hubnet-send-override user-id self "hidden?" [false]
        ]
      ]
      [
        set Project_Points false
        ask students
        [
          hubnet-send-override user-id self "hidden?" [true]  
        ] 
      ]
      set old-Student_Points Student_Points 
    ]
    
    if ( Freeze_Functions != old-Freeze_Functions )
    [
      let time date-and-time
      file-open current-data-file
      ifelse ( Freeze_Functions )
      [ 
        set frozenf? true
        ;; syncPoint01 
        file-print( word "Teacher" "," time "," "FREEZE STUDENT FUNCTIONS" "," "FREEZE STUDENT FUNCTIONS" )
      ]
      [ 
        set frozenf? false
        ;; syncPoint02 
        file-print( word "Teacher" "," time "," "UNFREEZE STUDENT FUNCTIONS" "," "UNFREEZE STUDENT FUNCTIONS" )
      ]
      set old-Freeze_Functions Freeze_Functions 
      file-close-all
    ]
    
    if ( Freeze_Points != old-Freeze_Points )
    [
      let time date-and-time
      file-open current-data-file
      ifelse ( Freeze_Points )
      [ 
        freeze-student-points
        ;; syncPoint03 
        file-print( word "Teacher" "," time "," "FREEZE STUDENT POINTS" "," "FREEZE STUDENT POINTS" )
      ]
      [ 
        unfreeze-student-points
        ;; syncPoint04 
        file-print( word "Teacher" "," time "," "UNFREEZE STUDENT POINTS" "," "UNFREEZE STUDENT POINTS" )
      ]
      set old-Freeze_Points Freeze_Points 
      file-close-all
    ]
    
    if ( Project_Points != old-Project_Points )
    [
      let time date-and-time
      file-open current-data-file
      ifelse ( Project_Points )
      [ 
        show-student-points
        ;; syncPoint05 
        file-print( word "Teacher" "," time "," "SHOW STUDENT POINTS" "," "SHOW STUDENT POINTS" )
      ]
      [ 
        set Students_See_Each_Other false
        hide-student-points
        ;; syncPoint06 
        file-print( word "Teacher" "," time "," "HIDE STUDENT POINTS" "," "HIDE STUDENT POINTS" )
      ]
      set old-Project_Points Project_Points
      file-close-all
    ]
    
    if( Students_See_Each_Other != old-Students_See_Each_Other )
    [
      ifelse( Students_See_Each_Other )
      [
        set Project_Points true
        ask students
        [
          hubnet-send-override user-id self "hidden?" [false] 
          ask other students
          [
            hubnet-send-override user-id myself "hidden?" [ false ] 
          ]
        ] 
      ]
      [
        ask students
        [
          hubnet-send-override user-id self "hidden?" [false]
          ask other students 
          [ 
            hubnet-send-override user-id myself "hidden?" [true]
            hubnet-send-override [user-id] of myself  self  "hidden?" [true]
          ]  
        ]
      ]
      set old-Students_See_Each_Other Students_See_Each_Other
    ]
    
    listen-clients
    display
  ]
end




to start-saving-data
  file-close-all  
  set current-data-file word current-timestamp "FUNCTION.csv"
  file-open current-data-file
end




to make-login-file        ;; get current-data-file and replace the word "FUNCTION" with "LOGIN"
  set current-login-file word current-timestamp "LOGIN.csv"
end




to make-GGB-file
  set current-GGB-file word current-timestamp "GGB.ggb"
end




to relogin
  file-open current-login-file
    ask students [
      ;; syncPoint07
      file-print( word date-and-time "," user-id ) 
    ]
  file-close
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PROCEDURES FOR CONTROLLING THE STUDENT-IN-FOCUS ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; return the student in index, position of the sorted list
;; of the student agentset
to-report current-student [ errors? ]  
  if student-index < 0
  [
    if errors?
    [ user-message "Please select a student equation using the < and > buttons."  ]
    report nobody
  ]
 report item student-index sort students 
end




to-report current-student-name
  let s current-student false
  ifelse s = nobody
  [ report s ]
  [ report [user-id] of s ]
end




to-report current-student-equation
  let s current-student false
  ifelse s = nobody
  [ report "" ]
  [ report "to implement" ]
end




;; advance to the next student equation
to right-direction
  ifelse (student-index + 1 >= count students  )
    [ set student-index 0 ]
    [ set student-index student-index + 1 ]
end




;; go back to the previous student equation
to left-direction
  ifelse student-index = 0
    [ set student-index (count students  - 1) ]
    [ set student-index student-index - 1 ]
end




;; set the rule to the value that the user enters in an input dialog
to set-message
  set rule message_to_students  
  let time date-and-time
  file-open current-data-file
  ;; syncPoint08
  file-print( word "Teacher" "," time "," "SENT MESSAGE TO STUDENTS" "," rule )
  file-close-all
  
  carefully[
    let annotate url:post ( word "http://" server_ip "/annotateActivity" )
                          ( list
                            ( list "aid" activityid )
                            ( list "annotation" Message_to_Students )
                          )
    ;;show ( word "Sending Activity Annotation: " Message_to_Students " > DB reply: " annotate )
  ]
  [ user-message "No connection to the database" ]
  ask students
  [ send-me-updates ]
end




;; send a list of the position of every student's turtle, to every student
to send-points-to-students
  let point-list ""
  ask students
  [
    let point-place (word "(" precision xcor 1 "," precision ycor 1 ")")
    set point-list (word point-list point-place " ")
  ]
  set point-list substring point-list 0 (length point-list - 1)
  ask students
  [ hubnet-send user-id "points" (point-list) ]
end




;;;;;;;;;;;;;;;;;;;;;
;; Grid Procedures ;;
;;;;;;;;;;;;;;;;;;;;;

to setup-grid
  ask grids [ die ]
  ask axes [ die ]
  create-axes 1 
  [ 
    set breed axes
    set shape "line"
    set size 31
    set heading 90                              ;; horizontal axis
    set color yellow
    set xcor 0                                  ;; horizontally center
    set ycor convert-to-ycor 0                  
  ]

  create-axes 1
  [ 
    set breed axes
    set shape "line"
    set size 41
    set heading 0                               ;; vertical axis
    set color yellow
    set xcor convert-to-xcor 0                  ;; horizontally center
    set ycor 0
  ]
    
  let x-index x-minimum-edge
  while [ x-index <= x-maximum-edge ]
  [
    let grid-level ceiling ( ( x-maximum-edge - x-minimum-edge ) / 100 )
    if( x-index mod grid-level = 0 )
    [
      create-grids 1
      [
        setxy (convert-to-xcor x-index) ( convert-to-ycor 0 )
        set size 0.75
        set shape "line"
        set heading 0
        set color yellow
      ]
    ]
    set x-index x-index + 1 
  ]
  
  let y-index y-minimum-edge
  while [ y-index <= y-maximum-edge ]
  [
    let grid-level ceiling ( ( y-maximum-edge - y-minimum-edge ) / 100 )
    if( y-index mod grid-level = 0 )
    [
      create-grids 1
      [
        setxy ( convert-to-xcor 0 ) ( convert-to-ycor y-index )
        set size 0.75
        set shape "line"
        set heading 90
        set color yellow 
      ]
    ] 
    set y-index y-index + 1
  ] 
end




;; report the coordinates of the mouse, with respect to the range and scale of the graph
;; rather than the patch coordinate system
to-report mouse-coords
  report (word "(" ( precision mouse-xcor  1)
         "," ( precision mouse-ycor 1 ) ")")
end




;;;;;;;;;;;;;;;;;;;;;;;
;; HubNet Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;

to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [
      ifelse authenticate hubnet-message-source teachername schoolname classname classyear
      [ create-new-student ]      ;; authentication successful
      [                           ;; authentication failed
        set unauthenticatedclients lput hubnet-message-source unauthenticatedclients
        hubnet-send-override hubnet-message-source sickface "pcolor" [ red ]
        hubnet-send-override hubnet-message-source patch 2 -8 "plabel" [ "LOGIN FAILED!" ]
        hubnet-send-override hubnet-message-source grids "hidden?" [ true ]
        hubnet-send-override hubnet-message-source axes "hidden?" [ true ]
        hubnet-send hubnet-message-source "Message from Teacher" "LOGIN FAILED! Your Username Is Not In The Database For This Class. Please Close NetLogo Client and Try Again."
      ] 
    ]
    [
      ifelse hubnet-exit-message?
      [ remove-student ]
      [ 
        ifelse( member? hubnet-message-source unauthenticatedclients )
        [ hubnet-send hubnet-message-source "Message from Teacher" "PLEASE QUIT HUBNET CLIENT AND RE-LOGIN." ] ;; remind unauthorized clients
        [ execute-command hubnet-message-tag ] 
        ;;send-update-to hubnet-message-source
      ]
    ]
  ]
end




;; update a specific client monitor
to send-me-updates
  hubnet-send user-id "Your shape:" (shape-combo)
  hubnet-send user-id "Message from Teacher" (rule)
  hubnet-send user-id "      x" lxcor
  hubnet-send user-id "      y" lycor
end




to create-new-student
  create-students 1
  [
    setup-student-vars
    let ownself user-id
    send-me-updates
    if( Students_See_Each_Other = false )
    [
      ask other students 
      [ 
        hubnet-send-override user-id myself "hidden?" [true]
        hubnet-send-override [user-id] of myself  self  "hidden?" [true]
      ]
      hubnet-send-override user-id self "hidden?" [false]
    ]
    grapher:add-student-point user-id lxcor lycor
  ]
end




to remove-student
  ask students with [user-id = hubnet-message-source]
  [
    set available-shapes sentence available-shapes shape-combo ;; return the shape used by this studnet to the list of available ones.
    die
  ]
end




to execute-move [new-heading]
  ask students with [user-id = hubnet-message-source]
  [
    set heading new-heading
    let can-go? false
    
    ifelse (heading = 0)
    [
      if (lycor <= y-maximum-edge - 1 ) 
      [
        set can-go? true
        set lycor lycor + 1
        set ycor convert-to-ycor lycor
      ]
    ]
    [
      ifelse (heading = 180)
      [
        if (lycor >= y-minimum-edge + 1 )
        [
          set can-go? true
          set lycor lycor - 1
          set ycor convert-to-ycor lycor
        ]
      ]
      [
        ifelse (heading = 90)
        [
          if (lxcor <= x-maximum-edge - 1) 
          [ 
            set can-go? true
            set lxcor lxcor + 1
            set xcor convert-to-xcor lxcor
          ]
        ]
        [
          if (heading = 270)
          [
            if (lxcor >= x-minimum-edge + 1)
            [
              set can-go? true
              set lxcor lxcor - 1
              set xcor convert-to-xcor lxcor
            ]
          ]
        ]
      ] 
    ]
  
    if (can-go?) 
    [ 
      hubnet-send user-id "      x" lxcor
      hubnet-send user-id "      y" lycor
      grapher:add-student-point user-id lxcor lycor
      post "POINT" hubnet-message-source classname classyear "0" ( word "Xcoor:" lxcor " Ycoor:" lycor ) true
    ]
  ]
end




to execute-change-shape
  ask students with [ user-id = hubnet-message-source ]
  [change-shape]
end




to execute-jump [ dir new-val ]
  ;; replace the horizontal/vertical coordinate value with new-val
  if dir = "horizontal"
  [ 
    ifelse( new-val >= x-minimum-edge and new-val <= x-maximum-edge )
    [
      ask students with [ user-id = hubnet-message-source ] 
      [ 
        set xcor convert-to-xcor new-val
        set lxcor new-val
        grapher:add-student-point user-id lxcor lycor
        post "POINT" hubnet-message-source classname classyear "0" ( word "Xcoor:" lxcor " Ycoor:" lycor ) true
      ]
    ]
    [
      ask students with [ user-id = hubnet-message-source ]
      [ send-me-updates ] 
    ]
  ]
  if( dir = "vertical" )
  [
    ifelse( new-val >= y-minimum-edge and new-val <= y-maximum-edge )
    [
      ask students with [ user-id = hubnet-message-source ] 
      [ 
        set ycor convert-to-ycor new-val
        set lycor new-val
        grapher:add-student-point user-id lxcor lycor
        post "POINT" hubnet-message-source classname classyear "0" ( word "Xcoor:" lxcor " Ycoor:" lycor ) true
      ]
    ]
    [
      ask students with [ user-id = hubnet-message-source ]
      [ send-me-updates ]
    ]
  ]
end





to execute-command [command]  
   ifelse command = "up"
  [ 
    if( frozenp? = false )
    [ execute-move 0 ] 
  ][
  ifelse command = "down"
  [ 
    if( frozenp? = false )
    [ execute-move 180 ]
  ][
  ifelse command = "right"
  [ 
    if( frozenp? = false )
    [ execute-move 90 ]
  ][
  ifelse command = "left"
  [ 
    if( frozenp? = false )
    [ execute-move 270 ]
  ][
  ifelse command = "Change Shape"
  [
    if( frozenp? = false ) 
    [ execute-change-shape ]
  ][
  ifelse command = "      x"
  [
    if( frozenp? = false )
    [ execute-jump "horizontal" hubnet-message ]
  ][
  ifelse command = "      y"
  [ 
    if( frozenp? = false )
    [ execute-jump "vertical" hubnet-message ] 
  ][
  if ( member? "my-equation" command  )
  [
    ifelse  ( not frozenf?  )
    [
      let eq-num last hubnet-message-tag
      let eq lower! hubnet-message ;;     
      if (eq != "EMPTY" and eq != "FUNCTIONS FROZEN")
      [
        set eq clean-equation eq      
        let isvalid grapher:add-student-function-validated hubnet-message-source (word "f" eq-num) eq r-default g-default b-default
        if( not isvalid )
        [
          hubnet-send hubnet-message-source hubnet-message-tag ( word hubnet-message " Is Invalid" )
        ]

        let eq-timestamp get-unique-timestamp
        ;; post to database
        post "EQUATION" hubnet-message-source classname classyear eq-num eq isvalid
       
        let time date-and-time
        file-open current-data-file
        ;; syncPoint09
        let isvalidword ""
        ifelse( isvalid )
          [ set isvalidword "VALID" ]
          [ set isvalidword "INVALID" ]
        file-print (word hubnet-message-source "," time "," (word "f" eq-num) ","  eq "," isvalidword)   ;WRITE TO TDATA FILE name, timestamp, function number, function expression, isvalidword. 
        file-close-all
        ask students with [ user-id = hubnet-message-source ] 
        [ set equation-history lput (list time eq-num eq ) equation-history 
          set equation-list replace-item (read-from-string eq-num) equation-list eq ] 
      ]
    ]
    [
      ask students with [ user-id = hubnet-message-source ]
     [ hubnet-send user-id command "FUNCTIONS FROZEN" ]
    ]
  ]
  
  ] ] ] ] ] ] ] 
end




to-report clean-equation [ incoming ]
  let outgoing incoming
  if( member? "\n" incoming ) 
  [
    let keep-til-here position "\n" incoming
    set outgoing substring incoming 0 keep-til-here
  ]
  report outgoing
end




to setup-student-vars  ;; turtle procedure
  set user-id hubnet-message-source
  set equation-list [ "0" "0" "0" "0" "0"]  ;to allow indexing by 1,2,... create an always-empty O-th element.
  set equation-history [ ] 
  randomize-coordinates

  change-shape
  set heading 0
  set size 2
  ifelse ( Project_Points )
  [ 
    set hidden? false 
    grapher:set-student-object-visible user-id "P" true
  ]
  [
    set hidden? true
    grapher:set-student-object-visible user-id "P" false
  ]
  file-open( current-login-file )
  ;; syncPoint10
  file-print( word date-and-time "," user-id )
  file-close 
end




to change-shape ;; turtle procedure
  set shape one-of all-shapes
  let color-index random (length all-colors)  
  set color item color-index all-colors
  set color-rgb-value item color-index color-rgb-values
  let color-name item color-index color-names 
  set shape-combo (word color-name " " shape)
  
  grapher:add-student-point user-id lxcor lycor
  grapher:color-student-object user-id "P" item 0 color-rgb-value item 1 color-rgb-value item 2 color-rgb-value
  hubnet-send user-id "Your shape:" shape-combo
end




to send-info-win-to-students
  ask students [
    hubnet-send user-id Send_as processed-output-contents
    ]
end




to freeze-student-points
  set frozenp? true
end




to unfreeze-student-points
  set frozenp? false
end




to clear-NetLogo-student-data
   ask students
  [
    set equation-history []
    set equation-list [ "0" "0" "0" "0" "0"]  ;to allow indexing by 1,2,... create an always-empty O-th element.
    hubnet-send user-id "my-equation-1" "EMPTY"
    hubnet-send user-id "my-equation-2" "EMPTY"
    hubnet-send user-id "my-equation-3" "EMPTY"
    hubnet-send user-id "my-equation-4" "EMPTY"
  ] 
end




to clear-GeoGebra-student-data
  grapher:clear-geogebra
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;DATA GENERATION PROCEDURES ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report processed-output-contents
  let poc ""
  let index 1
  foreach output-expressions-only
  [
    let line (word ":f" index "(x):="?) ;; adding colons (:) so it becomes readable to NSpire and Calculator
    set poc (word poc line "\n")
    set index index + 1
  ]
  set poc substring poc 1 ( length poc - 1 )
  report poc
end




to-report get-unique-filename [ filetype ]
  let it replace-all ":" date-and-time "-"
  set it replace-all " " it "_"
  set it (word it "--" filetype ".csv")
  report it
end




to-report get-unique-timestamp
  let it replace-all ":" date-and-time "-"
  set it replace-all " " it "_"
  report it
end




to-report replace-all [ ochar string nchar]
  while [ member? ochar string ]
  [
    let p position ochar string
    set string replace-item p string nchar
  ]
  report string
end




;NOT USED
to output-history-to-csv-file [ the-file ]
  file-open the-file
  ask students
  [
    foreach equation-history
    [
      file-print (word user-id "," item 0 ? ","(word "f" item 1 ?) ","  item 2 ? )   ;name, timestamp, function number, function expression.
    ]
  ]
  file-close-all
end




to hide-student-points
ask students [ 
  set hidden? true 
  grapher:set-student-object-visible user-id "P" false 
]
end




to show-student-points
ask students [ 
  set hidden? false 
  grapher:set-student-object-visible user-id "P" true 
]
end




to sync-GGB-window
  grapher:set-coordinates (list x-minimum-edge x-maximum-edge y-minimum-edge y-maximum-edge )
end




to resize-window
  set-edges
  calculate-scale
  calculate-offset
  sync-GGB-window
  relocate-students
  setup-grid
end




to calculate-scale
  set x-scale ( ( max-pxcor - min-pxcor ) / ( x-maximum-edge - x-minimum-edge ) )
  set y-scale ( ( max-pycor - min-pycor ) / ( y-maximum-edge - y-minimum-edge ) )
end




to calculate-offset
  set x-offset ( ( abs ( x-minimum-edge / ( x-maximum-edge - x-minimum-edge ) ) - 0.5 ) * ( max-pxcor - min-pxcor ) )
  set y-offset ( ( abs ( y-minimum-edge / ( y-maximum-edge - y-minimum-edge ) ) - 0.5 ) * ( max-pycor - min-pycor ) )
end




to-report convert-to-xcor [ lgxcor ]
  report ( ( lgxcor * x-scale ) + x-offset )
end




to-report convert-to-ycor [ lgycor ]
  report ( ( lgycor * y-scale ) + y-offset )
end




to-report convert-to-lxcor [ physxcor ]
  report ( physxcor - x-offset ) / x-scale
end




to-report convert-to-lycor [ physycor ]
  report ( physycor - y-offset ) / y-scale
end




to reposition-students
  ask students
  [
    set xcor convert-to-xcor lxcor
    set ycor convert-to-ycor lycor 
  ]
end




to relocate-students
  ask students
  [
    map-to-view x-minimum-edge x-maximum-edge y-minimum-edge y-maximum-edge 
    send-me-updates
  ]
end




to map-to-view [ cx1 cx2 cy1 cy2 ]
  ifelse( (lxcor < cx1) or (lxcor > cx2) or (lycor < cy1) or (lycor > cy2) )
  [
    randomize-coordinates
  ]
  [
    set xcor convert-to-xcor lxcor
    set ycor convert-to-ycor lycor  
  ]
end




to randomize-coordinates
  set lxcor ( random ( x-maximum-edge - x-minimum-edge + 1 ) + x-minimum-edge )
  set lycor ( random ( y-maximum-edge - y-minimum-edge + 1 ) + y-minimum-edge )
  set xcor convert-to-xcor lxcor
  set ycor convert-to-ycor lycor
  grapher:add-student-point user-id lxcor lycor
  send-me-updates
end




to random-distribute-students
  ask students
  [
    randomize-coordinates 
    grapher:add-student-point user-id lxcor lycor
    grapher:color-student-object user-id "P" item 0 color-rgb-value item 1 color-rgb-value item 2 color-rgb-value
    ifelse ( Project_Points )
    [ 
      set hidden? false 
      grapher:set-student-object-visible user-id "P" true
    ]
    [
      set hidden? true
      grapher:set-student-object-visible user-id "P" false
    ]
  ]
end




to save-GGB-window
  grapher:save-geogebra-file current-GGB-file
end




to color-selected-funcs-green
  clear-output
  set output-contents ""
  set output-expressions-only []
  let x1y1list grapher:functions-passing-through x1 y1
  ;;show ( word "The following functions pass through " x1 "," y1 " :" ) 
  ;;show x1y1list
  foreach x1y1list 
  [
    let anexp grapher:get-function-expression ?
    output-print (word ? "(x)=" anexp )
    set output-contents (word output-contents ? "(x)=" anexp "\n")
    set output-expressions-only (lput anexp output-expressions-only )
    grapher:color-named-object ? 0 153 0
    set highlight-group "G"
    set r-highlight 0
    set g-highlight 153
    set b-highlight 0
  ]
end




to color-selected-funcs-red
  clear-output
  set output-contents ""
  set output-expressions-only []
  let x2y2list grapher:functions-passing-through x2 y2
  foreach x2y2list 
  [
    let anexp grapher:get-function-expression ?
    output-print (word ? "(x)=" anexp )
    set output-contents (word output-contents ? "(x)=" anexp "\n")
    set output-expressions-only (lput anexp output-expressions-only )
    grapher:color-named-object ? 255 0 0
    set highlight-group "R"
    set r-highlight 255
    set g-highlight 0
    set b-highlight 0
  ]
end




to send-info-win-to-gallery
  let prefix highlight-group
  if( highlight-group = "G" ) ;; use the green-highlight-index
  [
    let i 0
    while [ i < length output-expressions-only ] ;; loop through the list of output expressions only
    [
      grapher:add-function-to-gallery ( word prefix green-highlight-index ) ( item ( i ) output-expressions-only ) r-highlight g-highlight b-highlight
      ;;show ( word prefix green-highlight-index )
      ;;show ( item ( i ) output-expressions-only )
      set green-highlight-index green-highlight-index + 1 
      set i i + 1
    ]
  ]
  if( highlight-group = "R" )
  [
    let i 0
    while [ i < length output-expressions-only ] ;; loop through the list of output expressions only
    [
      grapher:add-function-to-gallery ( word prefix red-highlight-index ) ( item ( i ) output-expressions-only ) r-highlight g-highlight b-highlight
      ;;show ( word prefix red-highlight-index )
      ;;show ( item ( i ) output-expressions-only )
      set red-highlight-index red-highlight-index + 1 
      set i i + 1
    ]
  ]
end




to save-gallery
  let gallery-filename ( word current-timestamp "GALLERYSAVE_" gallery-save-number ".ggb" )       ;; make gallery-save-filename
  grapher:save-gallery gallery-filename                                                          ;; save it
  set gallery-save-number gallery-save-number + 1                                                ;; keep track of save number
end




to reset-highlighting-indexes
  set green-highlight-index 1
  set red-highlight-index 1
end




to post [ stype usrname clsname  clsyear id contribution validity ]
  carefully [
    let status url:post( word "http://" server_ip "/contribution" )
                       ( list
                         ( list "stype" stype )
                         ( list "username" usrname )
                         ( list "actid" activityid )
                         ( list "contribid" id )
                         ( list "contribution" contribution )
                         ( list "validity" (word validity) )
                       )
    ;;show ( word "posting " stype " " contribution " " validity " > DB reply: " status )
  ]
  [ user-message "No connection to Database.\nCan't post student contribution." ]
end




to-report make-sickface-patches [ sfx sfy ]
  let sf ( patch-set patch (sfx - 4) (sfy - 2) ;; lips section
                           patch (sfx - 3) (sfy - 2)
                           patch (sfx - 2) (sfy - 2) 
                           patch (sfx - 1) (sfy - 2) 
                           patch (sfx - 0) (sfy - 2)
                           patch (sfx + 1) (sfy - 2)
                           patch (sfx + 2) (sfy - 2)
                           patch (sfx + 3) (sfy - 2)
                           patch (sfx + 4) (sfy - 2)
                           patch (sfx + 1) (sfy - 3) ;; tounge section
                           patch (sfx + 2) (sfy - 3)
                           patch (sfx + 3) (sfy - 3)
                           patch (sfx + 1) (sfy - 4)
                           patch (sfx + 2) (sfy - 4)
                           patch (sfx + 3) (sfy - 4)
                           patch (sfx + 2) (sfy - 5)
                           patch (sfx - 3) (sfy + 2) ;; left eye
                           patch (sfx - 4) (sfy + 3)
                           patch (sfx - 5) (sfy + 4)
                           patch (sfx - 4) (sfy + 1)
                           patch (sfx - 5) (sfy + 0)
                           patch (sfx + 3) (sfy + 2) ;; right eye
                           patch (sfx + 4) (sfy + 3)
                           patch (sfx + 5) (sfy + 4)
                           patch (sfx + 4) (sfy + 1)
                           patch (sfx + 5) (sfy + 0)
               )
  report sf
end




to-report authenticate [ usrname tuname schname clsname clsyear ]
    let status ""
    carefully [
        set status url:post ( word "http://" server_ip "/login" )
                            ( list
                              ( list "username" usrname )
			                        ( list "tuname" tuname )
			                        ( list "schoolname" schname )
                              ( list "classname" clsname )
                              ( list "classyear" clsyear )
                            )
          ;;show ( word "authenticating " usrname " > DB reply: " status )
    ]
    [ user-message "Not connected to Database.\nAuthentication failed." ]
    
    ifelse member? "SUCCESS" status
    [ report true ]
    [ report false ]
end




to start-activity [ clsname clsyear actvname ]
  carefully[
    let status url:post ( word "http://" server_ip "/startActivity" )
             ( list
	       ( list "schoolname"   schoolname               )
	       ( list "tuname"       teachername              )
               ( list "classname"    clsname                  )
               ( list "classyear"    clsyear                  )
               ( list "activityname" actvname                 )
	       ( list "src"          "database-testing-model" )
             )
    set activityid status
    ;;show ( word "Activity started : " schoolname " " teachername " " clsname " " clsyear " " actvname " " activityid )
  ]
  [ user-message "No connection to Database.\nCan't start activity." ]
end




to blind-unauthenticated-clients
  ;; override grids for all unauthenticated clients 
  if( empty? unauthenticatedclients = false ) 
  [
    foreach unauthenticatedclients
    [
      hubnet-send-override ? grids "hidden?" [ true ]
      hubnet-send-override ? axes "hidden?" [ true ]
    ]
  ]
end




to test-upload-traffic
  post "EQUATION" "astudent" classname classyear "4" "12345qwertyuiopa;sdlfja;kdjfa;skdfj;alskdjf;alksdjf;alkiwypqwiugh;aksn;iuwh;gGW;IHEPIAWEJ;AKWNGLKA;WIUETA;OWIENF;AOISHGAPIUWEGH;AOS;FASIJ;AOWIETNFWT4QWOEUGA;SDNF;AKSHFAWE;ANSAWIERJAWFsjdf;alksdfj123456789012345678901234567890123456789012345678901234567890" true
end




to-report make-classroom-list
  let ret ( list  )
  let longstring ""
  carefully [
    set longstring url:get( word "http://" server_ip "/getAllClassroomsMatching" )                          
  ]
  [ 
    user-message "You have no Internet connection.\nPlease check connectivity.\nOr, launch the GenSing Collaborative Grapher (GCG) v1.0" 
    
  ]
 set ret split-token longstring "\n"
  set ret remove-item 0 ret
  report ret
end




to-report make-schoolteacher-list [ biglist ]
  let ret ( list  )
  foreach biglist
  [
    let temp substring-at-tokens ? "; " 0 2     ;; NOTE: assuming "; " is used as delimiter in the output generated by the database  
    set ret lput temp ret
  ]
  set ret remove-duplicates ret
  report ret
end




to-report filter-list [ schtch biglist ]
  let ret ( list  )
  foreach biglist
  [
    if( member? schtch ? )
    [
      let temp substring-at-tokens ? "; " 2 4
      set ret lput temp ret
    ]
  ]
  report ret
end




;; take a long string which has the token sprinkled across it
;; chops the long string into chunks, discards all occurences of the token
;; and returns the chunks in a list. Chunks appear in order
;; e.g. split-token "abc\ndefg\nhijklmn\n" "\n" -> [ "abc" "defg" "hijklmn" ]
;;
to-report split-token [ thestring thetoken ]
  let split ( list  )
  set split fput thestring split
  while[ member? thetoken last split ]
  [
    let head substring last split 0 ( position thetoken last split )
    let tail substring last split ( position thetoken last split + length thetoken ) (length last split )
    set split replace-item ( length split - 1 ) split head
    if( tail != "" )              ;; dont want empty string at the end
    [ set split lput tail split ]
  ]
  report split
end




;; takes a string which contains several occurences of the token
;; from left to right, retain contents of the string until the token 
;; has appeared n-th times. Discards everything to the right of that.
;; Returns original string if it doesn't contain the token
;; e.g. trim-to-first-n-tokens "ab\tcdef\tghij\t\lmn" "\t" 2 -> "ab\t\cdef"
;;
to-report trim-to-first-n-tokens [ the-string the-token the-index ]
  let ret ""
  ifelse( member? the-token the-string = false )
  [ set ret the-string ]
  [
    ;; this basically just move, each chunk at a time, from the tail to the head
    ;; keeping track of how many times the token has occurred
    ;; then return the head in the end
    let head ""
    let tail the-string
    let occurence 0
    while[ occurence < the-index and tail != "" ]
    [
      ifelse( member? the-token tail )
      [
        ifelse( head = "" )
        [ set head substring tail 0 ( position the-token tail ) ]
        [ set head ( word head the-token substring tail 0 ( position the-token tail ) ) ]
	      set tail substring tail ( ( position the-token tail ) + length the-token ) ( length tail )
	      set occurence occurence + 1
      ]
      [
        ;; can't find the-token in tail, but occurence is still < the-index
	;; put all of tail into head
        set head ( word head the-token tail )
	set tail ""
      ]
    ]
    set ret head
  ]
  report ret
end ;; end trim-to-first-n-tokens




;; Takes a string containing several occurences of the-token
;; Returns the substring between the start-ind-th occurence and the end-ind-th occurence of the token
;; Returned substring is exclusive of the-token at both ends but inclusive of the token in between
;; e.g. substring-at-tokens "abc/tdef/tghi/tjkl/topq" "/t" 2 4 -> "ghi/tjkl"
;;
to-report substring-at-tokens [ the-string the-token start-ind end-ind ]
  let ret ""
  ifelse( member? the-token the-string = false )
  [
    if( start-ind = 0 )
    [ set ret the-string ]
  ]
  [
    ;; Need two layers here, one is just a "walker" to walk through the-string
    ;; The other is what we actually "want". Both have a head and a tail
    let head-walker ""
    let tail-walker the-string
    let occurence-walker 0
    let head-wanted ""
    let tail-wanted ""
    ;; walk through the whole string, but only begin filling head-wanted
    ;; and tail-wanted when we reach start-ind
    while[ occurence-walker < end-ind and tail-walker != "" ]
    [
      ifelse( member? the-token tail-walker )
      [
        ifelse( head-walker = "" )
        [ set head-walker substring tail-walker 0 ( position the-token tail-walker ) ]
        [ set head-walker ( word head-walker the-token substring tail-walker 0 ( position the-token tail-walker ) ) ]
	
	if( occurence-walker = start-ind )
	[
	  set tail-wanted tail-walker
	  let occurence-tail start-ind
	  while[ occurence-tail < end-ind and tail-wanted != "" ]
	  [
	    ifelse( member? the-token tail-wanted )
	    [
        ifelse( head-wanted = "" )
        [ set head-wanted substring tail-wanted 0 ( position the-token tail-wanted ) ]
	      [ set head-wanted ( word head-wanted the-token substring tail-wanted 0 ( position the-token tail-wanted ) ) ]
	      set tail-wanted substring tail-wanted ( ( position the-token tail-wanted ) + length the-token ) ( length tail-wanted )
	      set occurence-tail occurence-tail + 1
	    ]
	    [
	      set head-wanted ( word head-wanted the-token tail-wanted )
	      set tail-wanted "" 
	    ]	    
	  ] ;; end while
	]
	
	set tail-walker substring tail-walker ( ( position the-token tail-walker ) + length the-token ) ( length tail-walker ) 
	set occurence-walker occurence-walker + 1
      ]	
      [
        set head-walker ( word head-walker the-token tail-walker )
	set tail-walker ""
      ]
    ] ;; end while
    set ret head-wanted
  ]
  report ret
end ;; end substring-at-tokens




to merge-csv-files
  if( file-exists? current-data-file and file-exists? current-login-file )
  [
    let l ( list "" "LOGIN DETAILS:" )
    set l memorize-file current-login-file l
    set l lput "" l
    set l lput "ACTIVITY DATA:" l
    set l memorize-file current-data-file l
    file-open current-data-file
    foreach l 
    [ file-print ? ]
    file-close-all
  ]
end



    
to-report memorize-file [ fname mem ]
  file-open fname
  while[ file-at-end? = false ]
  [
    set mem lput file-read-line mem 
  ]
  file-close
  file-delete fname
  report mem
end




to-report lower! [ a-string ]
  let ret ""
  let capital-letters "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let lower-case-letters "abcdefghijklmnopqrstuvwxyz"
  let list-from-string ( list  )
  set a-string (word "" a-string)
ifelse is-string? a-string
[ 
  set list-from-string ( n-values (length a-string) [ item ? a-string] ) 
  foreach list-from-string
  [
    if member? ? capital-letters
    [
        let capspos position ? capital-letters
        set ? item capspos lower-case-letters
    ] 
    set ret ( word ret ? )
  ]
]
[ 
  set ret "equation is invalid string" 
]  
report ret
end




to plotTeacherFunction [ targetFunction ind ]
;; before posting, turn ind into "f" + ind (ex. "f1" or "f2" )
  if( targetFunction != "" )
  [
    set targetFunction clean-equation lower! targetFunction
    let isvalid grapher:graph-teacher-function-validated (word "f" ind ) targetFunction r-default g-default b-default
    if( not isvalid ) [
      ifelse( ind = 1 ) [
        set Teacher_f1 ( word targetFunction " Is Invalid" )
      ] 
      [ ;; else, ind = 2
        set Teacher_f2( word targetFunction " Is Invalid" ) 
      ]
    ]
    let time date-and-time
    file-open current-data-file
    ;; syncPoint11
    let isvalidword ""
    ifelse( isvalid )
      [ set isvalidword "VALID" ]
      [ set isvalidword "INVALID" ]
    file-print (word "Teacher" "," time "," (word "f" ind) ","  targetFunction "," isvalidword)   ;WRITE TO TDATA FILE name, timestamp, function number, function expression, isvalidword.
    file-close-all
  ]
end




to plotTeacherPoint[ xpos ypos ]
  set numtps numtps + 1
  grapher:graph-teacher-point (word "pt" numtps) xpos ypos r-teacher g-teacher b-teacher
end
@#$#@#$#@
GRAPHICS-WINDOW
315
46
728
610
15
20
13.0
1
10
1
1
1
0
0
0
1
-15
15
-20
20
1
1
0
ticks
30.0

SLIDER
316
615
439
648
x-minimum
x-minimum
-50
0
-20
1
1
NIL
HORIZONTAL

SLIDER
605
616
728
649
x-maximum
x-maximum
0
50
20
1
1
NIL
HORIZONTAL

SLIDER
463
630
586
663
y-minimum
y-minimum
-145
0
-20
1
1
NIL
HORIZONTAL

SLIDER
460
10
583
43
y-maximum
y-maximum
0
145
20
1
1
NIL
HORIZONTAL

BUTTON
239
356
308
416
Plot f1(x)
plotTeacherFunction Teacher_f1 1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1100
10
1189
96
Send Message
set-message
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
17
10
84
74
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
239
486
308
546
PLOT
plotTeacherPoint tx ty\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
739
102
799
162
x1
0
1
0
Number

INPUTBOX
802
102
862
162
y1
0
1
0
Number

INPUTBOX
739
167
799
227
x2
0
1
0
Number

INPUTBOX
802
167
862
227
y2
-5
1
0
Number

BUTTON
867
102
1096
161
Color functions through (x1,y1) GREEN
color-selected-funcs-green
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
867
167
1098
227
Color functions through (x2,y2) RED
color-selected-funcs-red
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
115
486
172
546
tx
0
1
0
Number

INPUTBOX
176
486
233
546
ty
0
1
0
Number

OUTPUT
853
256
1192
661
18

TEXTBOX
853
236
1186
254
Identified Functions:
13
122.0
1

BUTTON
736
311
845
352
TO STUDENTS
send-info-win-to-students
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
736
267
845
312
Send_as
Send_as
"Data_Set_A" "Data_Set_B"
0

BUTTON
89
10
208
74
Save and Clear Data
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
41
218
259
251
Freeze_Points
Freeze_Points
1
1
-1000

SWITCH
41
260
259
293
Project_Points
Project_Points
0
1
-1000

SWITCH
41
138
259
171
Freeze_Functions
Freeze_Functions
0
1
-1000

MONITOR
214
10
308
75
# Students
count students
0
1
16

INPUTBOX
8
356
235
416
Teacher_f1
NIL
1
0
String

INPUTBOX
8
419
235
479
Teacher_f2
NIL
1
0
String

BUTTON
239
419
308
480
Plot f2(x)
plotTeacherFunction Teacher_f2 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
171
577
308
610
Update Window Settings
resize-window
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
39
302
259
335
Students_See_Each_Other
Students_See_Each_Other
0
1
-1000

BUTTON
736
359
846
415
SEND TO GALLERY
send-info-win-to-gallery
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
736
482
845
515
SAVE GALLERY
save-gallery\nreset-highlighting-indexes\ngrapher:clear-gallery
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
737
10
1095
95
Message_to_Students
Type a message to students here
1
0
String

BUTTON
736
442
845
475
SHOW GALLERY
grapher:restore-gallery\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
89
83
208
129
SHOW GeoGebra
grapher:restore-geogebra-frame
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
43
178
259
211
Student_Points
Student_Points
0
1
-1000

TEXTBOX
10
487
103
555
Can create multiple points.\nDelete points from GeoGebra
11
0.0
1

TEXTBOX
731
407
863
429
_____________
18
0.0
1

TEXTBOX
730
239
903
261
_____________
18
0.0
1

TEXTBOX
9
326
329
370
_________________________________
18
0.0
1

TEXTBOX
10
536
328
580
_________________________________
18
0.0
1

INPUTBOX
12
566
167
626
server_ip
localhost:9000
1
0
String

@#$#@#$#@
## WHAT IS IT?
The CNECT Collabortive Grapher is an interactive environment allowing students to create class sets of points and functions to explore mathematical topics.

## HOW IT WORKS

Please see the [CCG Help Page](file:CCG_Help/index.html) in the SST folder for help.

## NETLOGO PlugIn	

This model uses a GeoGebra plugin.  

## Funding

Funding for the creation of this model was provided by the Office of Educaitonal Research at the National Institute of Education, Singapore as part of the Generative Activities in Singapore (GenSing) project.

## CREDITS AND REFERENCES

If you mention this model in an academic publication, the citations below are for the model and for the NetLogo software respectively:

Davis, S. M., Brady, C., & Effendi, D. (2011). GenSing Collaborative Graphing. Singapore, Singapore: Learning Sciences Lab, National Institute Education.  

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 39 39 224

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

diamond
false
0
Polygon -7500403 true true 150 17 270 149 151 272 30 152

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

heart
false
0
Circle -7500403 true true 31 30 122
Circle -7500403 true true 147 32 120
Polygon -7500403 true true 51 135 151 243 250 133 264 105 169 84 108 84 44 118 44 126
Polygon -7500403 true true 46 131 150 242 49 114
Polygon -7500403 true true 44 130 150 242 38 105 36 112

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rhombus
false
0
Polygon -7500403 true true 100 51 291 50 189 221 2 222

square
false
0
Rectangle -7500403 true true 48 40 249 238

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 152 2 196 105 297 106 215 176 248 277 151 209 56 278 87 172 4 107 108 104

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 151 8 285 232 11 236

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
BUTTON
125
203
217
236
up
NIL
NIL
1
T
OBSERVER
NIL
W

BUTTON
122
277
214
310
down
NIL
NIL
1
T
OBSERVER
NIL
S

BUTTON
168
240
260
273
right
NIL
NIL
1
T
OBSERVER
NIL
D

BUTTON
72
240
164
273
left
NIL
NIL
1
T
OBSERVER
NIL
A

INPUTBOX
62
327
309
393
my-equation-1
EMPTY
1
0
String

MONITOR
10
67
155
116
Your shape:
NIL
3
1

MONITOR
10
10
1003
59
Message from Teacher
NIL
3
1

BUTTON
163
66
309
115
Change Shape
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
13
363
64
387
f1(x)=
15
13.0
1

INPUTBOX
62
397
309
461
my-equation-2
EMPTY
1
0
String

TEXTBOX
11
428
65
447
f2(x)=
15
13.0
1

TEXTBOX
14
499
71
518
f3(x)=
15
13.0
1

INPUTBOX
62
464
309
528
my-equation-3
EMPTY
1
0
String

INPUTBOX
62
532
309
598
my-equation-4
EMPTY
1
0
String

TEXTBOX
12
571
65
590
f4(x)=
15
13.0
1

VIEW
318
66
721
599
0
0
0
1
1
1
1
1
0
1
1
1
-15
15
-20
20

INPUTBOX
727
66
1004
322
Data_Set_A
<info from teacher will show here>
1
1
String

INPUTBOX
728
332
1005
599
Data_Set_B
<info from teacher will show here>
1
1
String

INPUTBOX
112
130
163
194
      x
0
1
0
Number

INPUTBOX
180
130
230
193
      y
0
1
0
Number

TEXTBOX
101
169
116
187
(
11
0.0
1

TEXTBOX
171
174
187
192
,
11
0.0
1

TEXTBOX
245
170
260
189
)
11
0.0
1

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
