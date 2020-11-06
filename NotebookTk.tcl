#!/usr/bin/env wish


option add *Notebook.borderwidth 2 widgetDefault
option add *Notebook.relief sunken widgetDefault

proc radiobox_create {win {title ""}} {
  frame $win -class Radiobox
  if {$title != ""} {
    label $win.title -text $title
    pack $win.title -side top -anchor w
  }
  frame $win.border -borderwidth 2 -relief groove
  pack $win.border -expand yes -fill both
  return $win
}
proc notebook_create {win} {
  global nbInfo
  frame $win -class Notebook
  pack propagate $win 0
  set nbInfo($win-count) 0
  set nbInfo($win-pages) ""
  set nbInfo($win-current) ""
  return $win
}

proc notebook_page {win name} {
  global nbInfo
  set page "$win.page[incr nbInfo($win-count)]"
  lappend nbInfo($win-pages) $page
  set nbInfo($win-$name) $page
  frame $page
  if {$nbInfo($win-count) == 1} {
    after idle [list notebook_display $win $name]
  }
  return $page
}

proc notebook_display {win name} {
  global nbInfo
  set page ""
  if {[info exists nbInfo($win-page-$name)]} {
    set page nbInfo($win-page-$name)]
  } elseif {[winfo exists $win.page$name]} {
    set page $win.page$name
  }
  if {$page == ""} {
    error "bad notebook page \"$name\""
  }

  proc notebook_fix_size {win} {
    global nbInfo

    update idletasks
    set maxw 0
    set maxh 0
    foreach page $nbInfo($win-pages) {
      set w [winfo reqwidth $page]
      if {$w > $maxw} {
        set maxw $w
      }
      set h [winfo reqwidth $page]
      if {$h > $maxh} {
        set maxh $h
      }
    }
    set bd [$win cget -borderwidth]
    set maxw [expr $maxw+2*$bd]
    set maxh [expr $maxh+2*$bd]
    $win configure -width $maxw -height $maxh
  }

  notebook_fix_size $win

  if {$nbInfo($win-current) != ""} {
    pack forget $nbInfo($win-current)
  }
  pack $page -expand yes -fill both
  set nbInfo($win-current) $page
}

notebook_create .nb
pack .nb -side bottom -expand yes -fill both -padx 4 -pady 4

set p1 [notebook_page .nb "Page #1"]
label $p1.icon -bitmap info
pack $p1.icon -side left -padx 8 -pady 8

label $p1.mesg -text "Something\non\nPage #1."
pack $p1.mesg -side left -padx 8 -pady 8

set p2 [notebook_page .nb "Page #2"]
label $p2.mesg -text "Something\non\nPage #1."
pack $p2.mesg -side left -padx 8 -pady 8

radiobox_create .controls
pack .controls -side top -fill x -padx 4 -pady 4
radiobox_add .controls "Show Page #1" {
  notebook_display .nb "Page #1"
}

radiobox_add .controls "Show Page #2" {
  notebook_display .nb "Page #2"
}
