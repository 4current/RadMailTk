#!/usr/bin/env wish

global cmd_out

proc run_sh cmd {
   exec mailion $cmd &
}

proc ask_pat band {
   set result {}
   set lines [split [exec pat rmslist -m winmor -b $band -s] '\r\n']
   foreach line $lines {
     if {[string length $line] > 0} {
       set words [regexp -all -inline {\S+} $line]
       lappend result [ join [list\
         [lindex $words 0]\
         [lindex $words 2]\
         [lindex $words 5]\
         [lindex $words 6]\
         [lindex $words 8]
       ] " "]
     }
   }
   set cmd_out $result
   return $result
}

labelframe .f1 -text Commands
labelframe .f2 -text "RMS List"
pack .f1 .f2 -side left -expand yes -fill y

button .f1.a -text winmor -command "run_sh start_winmor"
button .f1.b -text ardop -command "run_sh start_ardop"
button .f1.c -text stop -command "run_sh stop"
button .f1.e -text stop -command "ask_pat 80m"
button .f1.d -text exit -command exit
pack .f1.a .f1.b .f1.c .f1.d -expand yes -fill x

frame .f2.f3 -width "3i" -relief sunken
pack .f2.f3

# Show list of stations

set rms [lrange [ask_pat "80m"] 0 10]
label .f2.l1 -text [join $rms '\n']
pack .f2.l1
