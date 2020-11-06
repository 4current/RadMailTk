#!/usr/bin/env wish

wm title . "DrawTk"
option add *sketchpad.background white startupFile

# ---------- Balloon Help System -------------------
option add *Balloonhelp.background white widgetDefault
option add *Balloonhelp.foreground black widgetDefault
option add *Balloonhelp.info.wraplength 3i widgetDefault
option add *Balloonhelp.info.justify left widgetDefault
option add *Balloonhelp.info.font \
  -*-lucida-medium-r-normal-sans-*-120-* widgetDefault
toplevel .balloonhelp -class Balloonhelp \
  -background black -borderwidth 1 -relief flat
# label .balloonhelp.arrow -anchor nw \
#  -bitmap @[file join $env(EFFTCL_LIBRARY) images arrow.xbm]
# pack .balloonhelp.arrow -side left -fill y
label .balloonhelp.info
pack .balloonhelp.info -side left -fill y
wm overrideredirect .balloonhelp 1
wm withdraw .balloonhelp

proc balloonhelp_control {state} {
  global bhInfo
  if {$state} {
    set bhInfo(active) 1
  } else {
    balloonhelp_cancel
    set bhInfo(active) 0
  }
}

proc balloonhelp_for {win mesg} {
  global bhInfo
  set bhInfo($win) $mesg
  bind $win <Enter> {balloonhelp_pending %W}
  bind $win <Leave> {balloonhelp_cancel}
}

proc balloonhelp_pending {win} {
  global bhInfo
  balloonhelp_cancel
  set bhInfo(pending) [after 1500 [list balloonhelp_show $win]]
}

proc balloonhelp_cancel {} {
  global bhInfo
  if {[info exists bhInfo(pending)]} {
    after cancel $bhInfo(pending)
    unset bhInfo(pending)
  }
}

proc balloonhelp_show {win} {
  global bhInfo
  if {$bhInfo(active)} {
    .balloonhelp.info configure -text $bhInfo($win)
    set x [expr [winfo rootx $win]+10]
    set y [expr [winfo rooty $win]+[winfo height $win]]
    wm geometry .balloonhelp +$x+$y
    wm deiconify .balloonhelp
    raise .balloonhelp
  }
  unset bhInfo(pending)
}

set bhInfo(active) 1

# ---------- End Balloon Help ---------------------------


# ---------- Create Menubar and Command Options -----------
frame .mbar -borderwidth 1 -relief raised
pack .mbar -fill x
menubutton .mbar.file -text "File" -menu .mbar.file.m
pack .mbar.file -side left
menu .mbar.file.m
.mbar.file.m add command -label "Exit" -command exit

menubutton .mbar.edit -text "Edit" -menu .mbar.edit.m
pack .mbar.edit -side left
menu .mbar.edit.m
.mbar.edit.m add command -label "Clear" -command {.sketchpad delete all}

menubutton .mbar.help -text "Help" -menu .mbar.help.m
pack .mbar.help -side right
menu .mbar.help.m
.mbar.help.m add command -label "Hide Balloon Help" -command {
  set mesg [.mbar.help.m entrycget 1 -label]
  if {[string match "Hide*" $mesg]} {
    balloonhelp_control 0
    .mbar.help.m entryconfigure 1 -label "Show Balloon Help"
  } else {
    balloonhelp_control 1
    .mbar.help.m entryconfigure 1 -label "Hide Balloon Help"
  }
}


# --------- Create drawing frame, style options ---------
frame .style -borderwidth 1 -relief sunken
pack .style -fill x

proc cmenu_create {win title cmd} {
  menubutton $win -text $title -menu $win.m

  menu $win.m
  $win.m add command -label "Black" -command "$cmd black"
  $win.m add command -label "Blue" -command "$cmd blue"
  $win.m add command -label "Red" -command "$cmd red"
  $win.m add command -label "Green" -command "$cmd green"
  $win.m add command -label "Yellow" -command "$cmd yellow"
}


cmenu_create .style.color "Color" {set color}
pack .style.color -side left

cmenu_create .style.bg "Background" {.sketchpad configure -bg}
pack .style.bg -side left

# ---------- Create canvas -----------
canvas .sketchpad
pack .sketchpad

# ---------- Build coords behavior ----
label .style.readout
pack .style.readout -side right

proc sketch_coords {x y} {
  set size [winfo fpixels .sketchpad 1i]
  set x [expr $x/$size]
  set y [expr $y/$size]
  .style.readout configure \
    -text [format "x: %6.2fi  y: %6.2fi" $x $y]
}

bind .sketchpad <Motion> {sketch_coords %x %y}

# ----------- Drawing functionality ---------
proc colormenu_get {win} {
  return "black"
}

proc sketch_box_add {x y} {
  set x0 [expr $x - 3]
  set x1 [expr $x + 3]
  set y0 [expr $y - 3]
  set y1 [expr $y + 3]
  set color [colormenu_get .style.color]

  .sketchpad create rectangle $x0 $y0 $x1 $y1 \
    -outline "" -fill $color
}

bind .sketchpad <ButtonPress-1> {sketch_box_add %x %y}
bind .sketchpad <B1-Motion> {sketch_box_add %x %y}

balloonhelp_for .style.color {Pen color: Selects the drawing color for the canvas}
balloonhelp_for .style.readout {Pen Location: Shows the location of the pointer on the drawing canvas (in inches)}
balloonhelp_for .sketchpad {Drawing Canvas: Click and drag with the left mouse button to draw in this area}
