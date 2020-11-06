#!/usr/bin/env wish

# ---------- Confirmation Dialog ------------------
frame .top
label .top.icon -bitmap questhead
label .top.mesg -text "Do you really want to quit?"
pack .top.icon -side left
pack .top.mesg -side right -expand yes

frame .sep -height 2 -borderwidth 1 -relief sunken

frame .controls
button .controls.ok -text "OK" -command exit
button .controls.cancel -text "Cancel" -command pack_help
button .controls.help -text "Help" -command hide_help
pack .controls.ok -side left -padx 4 -expand yes
pack .controls.cancel -side left -padx 4 -expand yes

pack .top -fill both -padx 8 -pady 8 -expand yes
pack .sep -fill x -pady 4
pack .controls -fill x -pady 4

# -------- Make Help disappear
proc hide_help {} {
  pack forget .controls.help
}

# -------- Make Help reappear
proc pack_help {} {
  pack .controls.help -side left -padx 4 -expand yes
}
