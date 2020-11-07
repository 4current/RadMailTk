#!/usr/bin/env wish

wm title . "RadMailTk"

set sysInfo(log_dir) "$::env(HOME)/Dropbox/ham/Winlink/logs"
set sysInfo(radio) "313"
set sysInfo(cat_dev) "/dev/ttyCAT"
set sysInfo(cat_baud) "19200"
set sysInfo(ptt_dev) "/dev/ttyPTT"
set sysInfo(ptt_ctrl) "DTR"
set sysInfo(ardop_dir) "$::env(HOME)/Dropbox/ham/Winlink/ardop"
set sysInfo(ardop_port) "8515"
set sysInfo(winmor_port) "8500"
set sysInfo(winmor_exe) "$::env(HOME)/prefix32/drive_c/RMS/Winmor\ TNC/Winmor\ TNC.exe"
set sysInfo(proto) ardop
set sysInfo(ardop-svcs) "rigctld ardopc ardop_gui pat browser"
set sysInfo(winmor-svcs) "rigctld winmor ardopc ardop_gui pat browser"

proc set_proto {proto} {
  set sysInfo(proto) $proto
}
proc poll_proc {svc proc_name} {
  global svcInfo

  set pids ""
  if {[catch {exec ps -C $proc_name -o pid=} results]} {
    set svcInfo($svc-running) 0
  } else {
    set svcInfo($svc-running) 1
  }

  update_indicator $svc
}

proc poll_rigctld {svc} {
  global svcInfo

#  --- This section is for daemon control ---
#  set status [exec sudo systemctl --property=ActiveState --value show rigctld]
#  if {$status == "active"} {
#    set svcInfo(rigctld-running) 1
#  } elseif {$status == "inactive"} {
#    set svcInfo(rigctld-running) 0
#  }
#  if {[info exists svcInfo($svc-ind)]} {
#    update_indicator $svc
#  }

  poll_proc $svc rigctld
}

proc poll_ardopc {svc} {
  poll_proc $svc ardopc
}

proc poll_ardop_gui {svc} {
  poll_proc $svc ARDOP_GUI
}

proc poll_pat {svc} {
  poll_proc $svc pat
}

proc poll_browser {svc} {
  global svcInfo

  set lres [split [exec wmctrl -l] "\n"]
  puts $lres
  if {[lsearch -regexp $lres "Pat - Mailbox"] > 0} {
    set svcInfo($svc-running) 1
  } else {
    set svcInfo($svc-running) 0
  }
  update_indicator $svc

}

proc poll_winmor {svc} {
  global svcInfo
  set lres [split [exec wmctrl -l] "\n"]
  puts "$lres"
  puts [lsearch -regexp $lres "WINMOR"]
  if {[lsearch -regexp $lres "WINMOR"] > 0} {
    set svcInfo($svc-running) 1
  } else {
    set svcInfo($svc-running) 0
  }
  update_indicator $svc

}

proc toggle_rigctld {svc} {
  global svcInfo
  global sysInfo

  if {$svcInfo($svc-running)} {
    # exec sudo systemctl stop rigctld
    exec pkill rigctld
  } else {
    # exec sudo systemctl start rigctld
    exec rigctld -m $sysInfo(radio) \
     -r $sysInfo(cat_dev) -s $sysInfo(cat_baud) \
     -p $sysInfo(ptt_dev) -P $sysInfo(ptt_ctrl) &
  }
  after 100 "poll_rigctld $svc"

}

proc toggle_winmor {svc} {
  global svcInfo
  global sysInfo

  if {$svcInfo($svc-running)} {
    puts "Running  wmctrl -c WINMOR"
    catch {exec -ignorestderr wmctrl -c WINMOR} res opts
  } else {
    puts "Running  wine $sysInfo(winmor_exe)"
    set ::env(WINEDEBUG) "err,fixme-all"
    set ::env(WINEPREFIX) "/home/rich/prefix32"
    catch {exec -ignorestderr wine $sysInfo(winmor_exe) &} res opts
  }
  after 2500 "poll_winmor $svc"
}

proc toggle_browser {svc} {
  global svcInfo
  global sysInfo

  if {$svcInfo($svc-running)} {
    catch {exec wmctrl -c "Pat - Mailbox" 2>/dev/null} res opts
  } else {
    exec firefox --new-window http://localhost:8080 &
  }
  after 1500 "poll_browser $svc"
}


proc toggle_ardopc {svc} {
  global svcInfo
  global sysInfo

  if {$svcInfo($svc-running)} {
      catch {exec pkill -x ardopc 2>/dev/null} res opts
    } else {
      exec $sysInfo(ardop_dir)/ardopc $sysInfo(ardop_port) \
           ARDOP ARDOP -l sysInfo(log_dir) &
  }
  after 100 "poll_ardopc $svc"
}

proc toggle_ardop_gui {svc} {
  global svcInfo
  global sysInfo

  if {$svcInfo($svc-running)} {
    catch {exec pkill -x ARDOP_GUI 2>/dev/null} res opts
  } else {
    exec $sysInfo(ardop_dir)/ARDOP_GUI &
  }
  after 100 "poll_ardop_gui $svc"
}

proc toggle_pat {svc} {
  global svcInfo
  global sysInfo

  if {$svcInfo($svc-running)} {
    catch {exec pkill -x pat  2>/dev/null} res opts
  } else {
    exec pat -l ardop,winmor http &
  }
  after 200 "poll_pat $svc"
}

proc get_rms_list {mode band} {
  return [split [exec pat rmslist -m$mode -b$band -s] '\r\n']
}

proc launch_browser {} {
  exec firefox --new-window http://localhost:8080 &
}

proc pat_connect {url} {
  exec pat connect $url &
}

proc add_mbutton {mbar opt name side} {
  global mbInfo
  set mbInfo($name) $mbar.$opt
  set menu $mbInfo($name).m
  menubutton $mbInfo($name) -text $name -menu $menu
  pack $mbInfo($name) -side $side
  menu $menu
  return $menu
}

frame .mbar -borderwidth 1 -relief raised
pack .mbar -fill x

set menu [add_mbutton .mbar sys "System" left]
$menu configure -tearoff 0
set psel [menu $menu.psel]
$psel configure -tearoff 0
$psel add command -label "ardop" -command "set sysInfo(proto) ardop"
$psel add command -label "winmor" -command "set sysInfo(proto) winmor"
$menu add cascade -label "Protocol" -menu $psel

set menu [add_mbutton .mbar ops "Operations" left]
$menu configure -tearoff 0
$menu add command -label "Launch Browser" -command launch_browser
$menu add command -label "Connect" -command "pat_connect ardop:///kq4et?freq=3587.5"

set menu [add_mbutton .mbar msg "Messages" left]
$menu configure -tearoff 0
$menu add command -label "Read" -command exit
$menu add command -label "Compose" -command exit

set menu [add_mbutton .mbar hlp "Help" right]
$menu configure -tearoff 0
$menu add command -label "Clear" -command exit

proc do_toggle {svc} {
  global svcInfo

  if {$svcInfo($svc-running)} {
    set svcInfo($svc-running) 0
  } else {
    set svcInfo($svc-running) 1
  }
  if {[winfo exists $svcInfo($svc-ind)]} {
     update_indicator $svc
  }
}

proc make_indicators {parent svcNames} {
  global svcInfo

  foreach svc $svcNames {
    set f $parent.$svc
    set svcInfo($svc-button) $f.b
    set svcInfo($svc-ind) $f.i
    frame $f
    pack $f -fill x -anchor w

    button $svcInfo($svc-button) -text $svc -command "$svcInfo($svc-cmd) $svc" \
      -font -*-lucida-medium-r-normal-sans-*-120-* -padx 1 -pady 1

    label $svcInfo($svc-ind) -text " " -background red
    pack $svcInfo($svc-button) -side left -anchor w -fill x -expand yes
    pack $svcInfo($svc-ind) -side right -anchor e -fill y -pady 1
  }
}

proc update_indicator {svc} {
  global svcInfo
  if {$svcInfo($svc-running)} {
    $svcInfo($svc-ind) configure -background green
  } else {
    $svcInfo($svc-ind) configure -background red
  }
}

labelframe .ctrl_pnl
pack .ctrl_pnl -side left -fill y

set sysInfo(proto) winmor

foreach svc "$sysInfo($sysInfo(proto)-svcs)" {
  set svcInfo($svc-running) 0
  set svcInfo($svc-cmd) toggle_$svc
}

make_indicators .ctrl_pnl "$sysInfo($sysInfo(proto)-svcs)"
foreach svc "$sysInfo($sysInfo(proto)-svcs)" {
  poll_$svc $svc
}

labelframe .f2 -text "RMS List"
pack .f2 -side left -expand yes -fill y -anchor w

frame .f2.f3 -width "3i" -relief sunken
pack .f2.f3
