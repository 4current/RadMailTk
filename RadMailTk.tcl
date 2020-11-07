#!/usr/bin/env wish

wm title . "RadMailTk"

set sysInfo(log_dir) "$::env(HOME)/Dropbox/ham/Winlink/logs"
set sysInfo(radio) "313"
set sysInfo(cat_dev) "/dev/ttyCAT"
set sysInfo(cat_baud) "19200"
set sysInfo(cat_ptt) "/dev/ttyPTT"
set sysInfo(ptt_ctrl) "DTR"
set sysInfo(ardop_dir) "$::env(HOME)/Dropbox/ham/Winlink/ardop"
set sysInfo(ardop_port) "8515"
set sysInfo(winmor_port) "8500"


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

  set status [exec sudo systemctl --property=ActiveState --value show rigctld]
  if {$status == "active"} {
    set svcInfo(rigctld-running) 1
  } elseif {$status == "inactive"} {
    set svcInfo(rigctld-running) 0
  }
  if {[info exists svcInfo($svc-ind)]} {
    update_indicator $svc
  }
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

  set pids ""
  set lres [split [exec wmctrl -l] "\n"]
  puts $lres
  if {[lsearch -regexp $lres "Pat - Mailbox"] > 0} {
    puts "found Pat - Mailbox"
    set svcInfo($svc-running) 1
  } else {
    set svcInfo($svc-running) 0
  }
  update_indicator $svc

}

proc toggle_rigctld {svc} {
  global svcInfo

  if {$svcInfo($svc-running)} {
    exec sudo systemctl stop rigctld
  } else {
    exec sudo systemctl start rigctld
  }
  after 100 "poll_rigctld $svc"

#  exec rigctld -m$sysInfo(radio) -r$sysInfo(cat_dev) -s $sysInfo(cat_baud) \
#    -p$sysInfo(ptt_dev) -p$sysInfo(ptt_ctrl)
}

proc toggle_winmor {svc} {
  # Start Winmor TNC
  # echo " --- Starting Winmor TNC ---"
  # export WINEDEBUG=err,fixme-all
  # export WINEPREFIX=$HOME/prefix32
  # wine $WINEPREFIX/drive_c/RMS/Winmor\ TNC/Winmor\ TNC.exe &
  # sleep 2
  # ;;

  # wmctrl -c WINMOR
  # pid=$(ps -A |awk '/Winmor TNC.exe/ {print $1}')
  # if [[ "$pid" -ne "" ]]; then
  #  kill -9 $pid
  # fi
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
    exec pat -l ardop http &
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

$menu add command -label "rigctld" -command toggle
$menu add command -label "ardopc" -command exit
$menu add command -label "ardop_gui" -command exit
$menu add command -label "WINMOR_TNC" -command exit

set menu [add_mbutton .mbar ops "Operations" left]
$menu add command -label "Launch Browser" -command launch_browser
$menu add command -label "Connect" -command "pat_connect ardop:///kq4et?freq=3587.5"

set menu [add_mbutton .mbar msg "Messages" left]
$menu add command -label "Read" -command exit
$menu add command -label "Compose" -command exit

set menu [add_mbutton .mbar hlp "Help" right]
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
    pack $f -fill x -expand yes

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
pack .ctrl_pnl -side left -expand yes -fill y

set svcs "rigctld ardopc ardop_gui pat browser"
foreach svc "$svcs" {
  set svcInfo($svc-running) 0
  set svcInfo($svc-cmd) toggle_$svc
}

make_indicators .ctrl_pnl "$svcs"
foreach svc "$svcs" {
  poll_$svc $svc
}

labelframe .f2 -text "RMS List"
pack .f2 -side left -expand yes -fill y

frame .f2.f3 -width "3i" -relief sunken
pack .f2.f3
