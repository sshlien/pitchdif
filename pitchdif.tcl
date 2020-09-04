# pitchdif.tcl
#
#!/bin/sh
# the next line restarts using wish \
exec wish8.6 "$0" "$@"

#
# An application for measuring your sensitivity to small
# pitch differences. Besides a tcl/tk interpreter the script
# requires abc2midi executable and a midi player. You use
# the cfg button to indicate the paths to these executables.
#
#
# Most global variables are in the midi array.

set midi(version) "0.175 September 04 2020"
set midi(font_family) [font actual helvetica -family]
set midi(font_size) 13
set midi(font_weight) [font actual . -weight]

set df [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
set dff [font create -family $midi(font_family) -size 11 \
            -weight $midi(font_weight)]

wm title . "pitchdef $midi(version)"

set p .pitchtone
frame $p
frame $p.1
frame $p.2
frame $p.3
pack $p
pack $p.1
pack $p.2 -anchor w
pack $p.3

set p .pitchtone.1
button $p.start -text start -width 6 -font $df -command start
button $p.repeat -text repeat -width 8 -font $df -command repeat
set w $p.exercise.exercises
menubutton $p.exercise -menu $w -text exercises -font $df
menu $w -tearoff 0
$w add command -label "none" -command {test 0} -font $df
$w add command -label "warble"   -command {test 2} -font $df
$w add command -label "high/low" -command {test 1} -font $df
$w add command -label "odd one out"   -command {test 3} -font $df
$w add command -label "tuning"   -command {test 4} -font $df
$w add command -label "chord high/low"   -command {test 5} -font $df
$w add command -label "chord odd one out"   -command {test 6} -font $df

button $p.cfg -text cfg -command {cfg} -font $df
set w .pitchtone.1.tool.tools
menubutton $p.tool -menu $w -text tools -font $df
menu $w -tearoff 0
$w add command -label console -font $df -command show_console
$w add command -label tmp.abc -font $df -command show_tmp_file
$w add command -label plot -font $df -command plot_results


button $p.help -text help -font $df -command helper
pack $p.start $p.repeat $p.exercise $p.cfg $p.tool $p.help -side left 

set p .pitchtone.2
button $p.yes -text yes -width 6 -font $df
button $p.no -text no -width 6 -font $df
button $p.know -text "don't know" -width 11 -font $df -command notknown
button $p.high -text "first is higher" -width 12 -font $df -command {response 1}
button $p.low -text "first is lower" -width 12 -font $df -command {response 0}
button $p.1 -text 1 -command {response 0} -width 5 -font $df
button $p.2 -text 2 -command {response 1} -width 5 -font $df
button $p.3 -text 3 -command {response 2} -width 5 -font $df
button $p.4 -text 4 -command {response 3} -width 5 -font $df
scale $p.tuner -length 300 -from -50 -to 50 -orient horizontal\
 -resolution 1 -width 10 -variable midi(tuning) -command set_unshift\
 -font $df
scale $p.warbler -length 250 -from 0 -to 40 -orient horizontal\
 -resolution 0.2 -width 10 -variable midi(warbledepth) -font $df

label .pitchtone.3.msg -text "" -font $df
pack .pitchtone.3.msg 

set hlp_high_low "High / Low

This test is used to measure your ability to tell whether\
the first tone is higher or lower in pitch than the next tone. After\
clicking 'Start' two tones will be played. If the first tone\
is the higher pitch than click  the button labeled high.\
If it is lower, click 'low'. If you cannot tell click 'don't know'.
"

set hlp_chord_high_low "Chord High / Low

This test is used to measure your ability to tell whether\
the first tone is higher or lower in pitch than the next tone.\
To make it more difficult (or easier), the test tones are embedded\
in a chord. Depending on how you configure the program, the chord\
tone may be either above or below the test tones.  The interval\
between the test tone and chord tone can be configured by the\
chordinterval parameter which can be positive or negative.\
If it is negative, the chord tone is played below the test tone.\n\n
After clicking 'Start' two tones will be played. If the first test tone\
is the higher pitch than click  the button labeled high.\
If it is lower, click 'low'. If you cannot tell click 'don't know'.
"

set hlp_warble "Warble

This test is used to measure the minimum pitch difference\
that you can hear. When you click 'Start' or 'Next' the\
program will play a long tone where the pitch is slowly going up\
and down. The amount of this variation can be changed using\
the slider on the bottom right. Your goal is to find the\
minimum pitch variation that you can hear. Click yes, no,\
or don't know depending whether you can hear the variation.
"

set hlp_odd "Odd one out

After clicking start, 4 tones will be played in sequence.\
The pitch of one of the tones will be slightly different.\
Click on the number of that tone.  Do this many times\
so that there is a large statistical sample.
"

set hlp_chord_odd "Chord odd one out

This is similar to Odd one out except that now the test\
tones are embedded in chords created by inserting other\
tones played concurrently. The chord tones are configured using\
the chordinterval parameter, which is explained in the help\
for chord high/low test.
"

set hlp_tune "Tuning

After clicking 'Start' you will hear two tones. The second\
tone will be slightly out of tune. Using the slider and the\
repeat button, try to get the two tones to sound the same and\
then click 'Done'. Do this many times so that there is\
a large statistical sample.
"

set hlp_welcome "Welcome

This programs has 4 exercises to measure your sensitivity to\
small pitch differences. Unfortunately, this program cannot\
run alone. It requires a tcl/tk 8.6 interpreter and two executables\
(abc2midi and TiMidity). TiMidity requires a soundfont and needs\
to be configured so it can find the soundfont. Assuming you\
have this environment, then you need to tell pitchdif.tcl\
where to find these programs. Click on the cfg button and\
specify the paths to these executables. All of this information\
will be recorded in the file pitchdif.ini that will be created\
or updated whenever you run this program, so you do not need\
to do this again.

Now you are ready to try it out. Select one of the exercises
from the menu. There is help text for each of the exercises.

To see this text again, set the exercise to none and click
help again.
"

set highlowdata {}
set chordhighlowdata {}
set oddoutdata {}
set tuningdata {}
set chordoddoutdata {}


proc helper {} {
global midi
global hlp_welcome
global hlp_tune
global hlp_odd
global hlp_chord_odd
global hlp_warble
global hlp_high_low
global hlp_chord_high_low
switch $midi(procedure) {
  0 {show_help $hlp_welcome}
  1 {show_help $hlp_high_low}
  2 {show_help $hlp_warble}
  3 {show_help $hlp_odd}
  4 {show_help $hlp_tune}
  5 {show_help $hlp_chord_high_low}
  6 {show_help $hlp_chord_odd}
  }
}

proc show_help {text} {
show_message_page $text
}




proc start {} {
global midi
.pitchtone.3.msg configure -text ""
pack forget .tools
switch $midi(procedure) {

	1 {trial1}
	2 {trial2}
	3 {trial3}
	4 {trial4}
	5 {trial5}
	6 {trial6}
   }
}

proc notknown {} {
global midi
global highlowdata
global chordhighlowdata
global oddoutdata
global chordoddoutdata
switch $midi(procedure) {
  1 {
    #puts "$midi(note) $midi(micro) $midi(answer) " 
    lappend highlowdata [list $midi(note) $midi(micro) -1 $midi(answer)]
    set nsamples [llength $highlowdata]
    if {$midi(answer) == 0} {
      .pitchtone.3.msg configure -text "sample $nsamples: the first tone is low"
      } else {
      .pitchtone.3.msg configure -text "sample $nsamples: the first tone is high"
     }
    }
  3 {
    set sh [microtone2cents $midi(shift)]
    #puts "$midi(note) $sh $midi(answer) " 
    set ans [expr $midi(answer) + 1] 
    lappend oddoutdata [list $midi(note) $sh -1 $midi(answer)]
    set nsamples [llength $oddoutdata]
    .pitchtone.3.msg configure -text "sample $nsamples: the answer is $ans"
    }
  5 {
    #puts "$midi(note) $midi(micro) $midi(answer) " 
    lappend chordhighlowdata [list $midi(note) $midi(chordinterval)  $midi(micro) -1 $midi(answer)]
    set nsamples [llength $chordhighlowdata]
    if {$midi(answer) == 0} {
      .pitchtone.3.msg configure -text "sample $nsamples: the first tone is low"
      } else {
      .pitchtone.3.msg configure -text "sample $nsamples: the first tone is high"
     }
   }
  6 {
    set sh [microtone2cents $midi(shift)]
    #puts "$midi(note) $sh $midi(answer) " 
    set ans [expr $midi(answer) + 1] 
    lappend chordoddoutdata [list $midi(note) $sh -1 $midi(answer)]
    set nsamples [llength $chordoddoutdata]
    .pitchtone.3.msg configure -text "sample $nsamples: the answer is $ans"
    }
  }
}

proc response {choice} {
global midi
global highlowdata
global chordhighlowdata
global oddoutdata
global tuningdata
global chordoddoutdata
global shift
switch $midi(procedure) {
  
  1 {if {$choice == $midi(answer)} {
       set result "correct"
       } else {
       set result "wrong"
       } 
       #puts "$midi(note) $midi(micro) $choice $midi(answer) $result" 
       lappend highlowdata [list $midi(note) $midi(micro) $choice $midi(answer)]
       set nsamples [llength $highlowdata]
       .pitchtone.3.msg configure -text "$result for sample $nsamples"
     }
  2 {
    set midi(warbledepth) $midi(tuning)
    puts "$midi(note) $midi(warbledepth) $choice"
    }
  3 {
       set sh [microtone2cents $midi(shift)]
       lappend oddoutdata [list $midi(note) $sh $choice $midi(answer)]
       set nsamples [llength $oddoutdata]
        if {$choice == $midi(answer)} {
         .pitchtone.3.msg configure -text "good for sample $nsamples"
         } else {
         set ans [expr $midi(answer) + 1]
         .pitchtone.3.msg configure -text "sample: $nsamples the answer is $ans"
         } 
    }
  4 {
# finished tuning new example
    .pitchtone.1.start configure -text start -command start
    if {[info exist midi(unshift)]} {
       set sh [microtone2cents $midi(shift)]
       set ush [microtone2cents $midi(unshift)]
       #puts "sh = $sh ush = $ush"
       set dif [expr $ush - $sh]
       lappend tuningdata [list $midi(note) $dif]
       set nsamples [llength $tuningdata]
       if {$dif > 0} {
	       set msg "high by $dif cents for sample $nsamples"
       } elseif {$dif == 0} {
               set msg "perfect match for sample $nsamples"
       } else {
	       set dif [expr abs($dif)]
	       set msg "low by $dif cents for sample $nsamples"
       }
       .pitchtone.3.msg configure -text $msg
    } else {
# play again with unshift value
    repeat	    
    }	  
  } 
  5 {if {$choice == $midi(answer)} {
       set result "correct"
       } else {
       set result "wrong"
       } 
       #puts "$midi(note) $midi(micro) $choice $midi(answer) $result" 
       lappend chordhighlowdata [list $midi(note) $midi(chordinterval) $midi(micro) $choice $midi(answer)]
       set nsamples [llength $chordhighlowdata]
       .pitchtone.3.msg configure -text "$result for sample $nsamples"
     }
  6 {
       set sh [microtone2cents $midi(shift)]
       lappend chordoddoutdata [list $midi(note) $midi(chordinterval) $sh $choice $midi(answer)]
       set nsamples [llength $chordoddoutdata]
        if {$choice == $midi(answer)} {
         .pitchtone.3.msg configure -text "good for sample $nsamples"
         } else {
         set ans [expr $midi(answer) + 1]
         .pitchtone.3.msg configure -text "sample: $nsamples the answer is $ans"
         } 
    }
 }
}	

proc microtone2cents {shift} {
 scan $shift "%c%d/100" sg sh
 if {$sg == 95} {set sh [expr -$sh]}
# 95 is the value of character _
 return $sh
 }



set template1 {
X:1
T: pitch discrim
M: 4/4
L: 1/4
K: C
Q: 1/4 = $tempo
%%MIDI program $prog
$note z |$shift$note|
}

set template2 {
X:1
T: warble
M: 8/4
L: 1/4
K: G
Q: 1/4 = $tempo
%%MIDI program $prog
%%MIDI bendstringex $s -$s -$s $s $s -$s -$s $s $s -$s -$s $s $s -$s -$s $s $s -$s -$s
!bend! $note 
}

set template3 {
X:1
T: pitch discrim
M: 3/4
L: 1/8
K: C
Q: 1/4 = $tempo
%%MIDI program $prog
 $sh0$note z2|
 $sh1$note z2|
 $sh2$note z2|
 $sh3$note z2|
}

set template4 {
X:1
T: pitch discrim
M: 4/4
L: 1/4
K: C
Q: 1/4 = $tempo
%%MIDI program $prog
$shift$note z | $unshift$note|
}

set template5 {
X:1
T: pitch discrim
M: 4/4
L: 1/4
K: C
Q: 1/4 = $tempo
V:1
%%MIDI program $prog
$note z |$shift$note|
V:2
%%MIDI program $prog
$altnote z | $altnote |
}

set template6 {
X:1
T: pitch discrim
M: 3/4
L: 1/8
K: C
Q: 1/4 = $tempo
V:1
%%MIDI program $prog
 $sh0$note z2|
 $sh1$note z2|
 $sh2$note z2|
 $sh3$note z2|
V:2
%%MIDI program $prog
 $altnote z2|
 $altnote z2|
 $altnote z2|
 $altnote z2|
}

set console_data ""


proc out_and_play {abcfile} {
global midi
global console_data
set outhandle [open tmp.abc w]
puts $outhandle $abcfile
close $outhandle
set cmd1 "exec $midi(abc2midi) tmp.abc"
catch {eval $cmd1} out1
set cmd2 "exec $midi(midiplayer) tmp1.mid "
catch {eval $cmd2} out2
append console_data $cmd1
append console_data $out1
append console_data \n$cmd2
append console_data \n$out2
append console_data "\n"
}

proc show_console {} {
global midi
global console_data
if {![winfo exist .tools]} {tools_init}
if {[winfo ismapped .tools] == 0} {pack .tools}
set p .tools
pack forget $p.can
pack $p.t
$p.t delete 1.0 end
$p.t insert end $console_data
}

proc show_tmp_file {} {
global midi
if {![winfo exist .tools]} {tools_init}
if {[winfo ismapped .tools] == 0} {pack .tools}
set p .tools
pack forget $p.can
pack $p.t
$p.t delete 1.0 end
if {[info exist midi(abcfile)]} {
   $p.t insert end $midi(abcfile)
   } else {
   $p.t insert end "First run an exercise"
   }
}


proc randomshift {} {
global midi
set maxshift $midi(maxshift)
set minshift $midi(minshift)
set micro [expr int(rand()*($maxshift - $minshift))]
set micro [expr $micro + int($minshift)]
set sgn [expr rand()]
if {$sgn < 0.5} {
  set shift _$micro/100
  } else {
  set shift ^$micro/100
  }
return $shift
}

proc trial {} {
global midi
switch $midi(procedure) {
    1 {trial1}
    2 {trial2}
    3 {trial3}
    4 {trial4}
    }
}

proc trial1 {} {
global template1
global midi
set maxshift $midi(maxshift)
set minshift $midi(minshift)
set micro [expr int(rand()*($maxshift - $minshift))]
set micro [expr $micro + int($minshift)]
set midi(micro) $micro
set sgn [expr rand()]
if {$sgn < 0.5} {
  set shift _$micro/100
  set midi(answer) 1
  } else {
  set shift ^$micro/100
  set midi(answer) 0
  }
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)3 
# substitute values of shift, tempo, prog, and note into
# template and return in abcfile
set midi(abcfile) [subst $template1]
out_and_play $midi(abcfile)
}

proc trial2 {} {
global template2
global midi
set s [expr int($midi(warbledepth)*40.96)]
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)8 
# substitute values of tempo, prog, note and s into
# template and return the result in abcfile
set midi(abcfile) [subst $template2]
#puts $abcfile
out_and_play $midi(abcfile)
}

proc trial3 {} {
global template3
global midi
set shift [randomshift]
set midi(shift) $shift
for {set i 0} {$i < 4} {incr i} {
  set sh$i $shift
  }
set t [expr int(rand() * 4)]
set midi(answer) $t
set sh$t ""
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)4 
# substitute values of tempo, prog, note and s into
# template and return the result in abcfile
set midi(abcfile) [subst $template3]
#puts $abcfile
out_and_play $midi(abcfile)
}

proc trial4 {} {
global midi
global template4
set midi(shift) [randomshift]
.pitchtone.1.start configure -text done -command {response 4}
.pitchtone.3.msg configure -text ""
set tuning $midi(tuning)
set_unshift $tuning
set shift $midi(shift)
set unshift $midi(unshift)
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)4 
# substitute values of tempo, prog, note and s into
# template and return the result in abcfile
set midi(abcfile) [subst $template4]
#puts $abcfile
repeat
}

proc trial5 {} {
global template5
global midi
set maxshift $midi(maxshift)
set minshift $midi(minshift)
set micro [expr int(rand()*($maxshift - $minshift))]
set micro [expr $micro + int($minshift)]
set midi(micro) $micro
set sgn [expr rand()]
if {$sgn < 0.5} {
  set shift _$micro/100
  set midi(answer) 1
  } else {
  set shift ^$micro/100
  set midi(answer) 0
  }
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)3 
set altnote [transpose_note $note $midi(chordinterval) 0]
append altnote 3
# substitute values of shift, tempo, prog, and note into
# template and return in abcfile
set midi(abcfile) [subst $template5]
out_and_play $midi(abcfile)
.pitchtone.3.msg configure -text "one of the tones is higher by $micro cents"
}

proc trial6 {} {
global template6
global midi
set shift [randomshift]
set midi(shift) $shift
for {set i 0} {$i < 4} {incr i} {
  set sh$i $shift
  }
set t [expr int(rand() * 4)]
set midi(answer) $t
set sh$t ""
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)4 
set altnote [transpose_note $note $midi(chordinterval) 0]
append altnote 4
# substitute values of tempo, prog, note and s into
# template and return the result in abcfile
set midi(abcfile) [subst $template6]
#puts $abcfile
out_and_play $midi(abcfile)
}



proc set_unshift {tuning} {
global midi
if {$tuning >= 0} {
  set unshift ^$tuning/100
  } else {
  set unshift _[expr -$tuning]/100
  }
set midi(unshift) $unshift
}

proc update_abcfile_for_tuning {} {
global midi
global template4
set shift $midi(shift)
set unshift $midi(unshift)
set tempo $midi(tempo)
set prog $midi(program)
set note $midi(note)4 
# substitute values of tempo, prog, note and s into
# template and return the result in abcfile
set midi(abcfile) [subst $template4]
}

proc repeat {} {
global midi
if {$midi(procedure) == 4} update_abcfile_for_tuning
out_and_play $midi(abcfile)
}

proc cfg {} {
global midi
if {[winfo exist .cfg]} return
toplevel .cfg
button .cfg.abc2midi -text abc2midi -command {setpath abc2midi}
entry .cfg.abc2midi_path -width 30 -textvariable midi(abc2midi)
grid .cfg.abc2midi .cfg.abc2midi_path
button .cfg.midiplayer -text "midi player" -command {setpath midiplayer}
entry .cfg.midiplayer_path -width 30 -textvariable midi(midiplayer)
grid .cfg.midiplayer .cfg.midiplayer_path
label .cfg.pitch -text "pitch in ABC notation"
entry .cfg.pitch_value -width 30 -textvariable midi(note)
grid .cfg.pitch .cfg.pitch_value
label .cfg.prog -text "midi program (0-127)"
entry .cfg.prog_value -width 30 -textvariable midi(program)
grid .cfg.prog .cfg.prog_value
label .cfg.tempo -text "tempo in bpm"
entry .cfg.tempo_value -width 30 -textvariable midi(tempo)
grid .cfg.tempo .cfg.tempo_value
label .cfg.maxshift -text "maximum shift (cents)"
entry .cfg.shift_max -width 30 -textvariable midi(maxshift)
grid .cfg.maxshift .cfg.shift_max
label .cfg.minshift -text "minimum shift (cents)"
entry .cfg.shift_min -width 30 -textvariable midi(minshift)
grid .cfg.minshift .cfg.shift_min
label .cfg.intervallab -text "chord interval (semitones)"
entry .cfg.intervalvalue -width 30 -textvariable midi(chordinterval)
grid .cfg.intervallab .cfg.intervalvalue
button .cfg.datadir -text "data folder" -command {setpath datadir}
entry .cfg.datadirpath -width 30 -textvariable midi(datadir)
grid .cfg.datadir .cfg.datadirpath
}

proc test {sel} {
global midi
set midi(procedure) $sel
set midi(answer) -1
set midi(micro) 0
set p .pitchtone.2
if {[winfo exist .cfg]} {
  switch $sel {
  0 {.cfg.procmenu configure -text "none"}
  1 {.cfg.procmenu configure -text "high / low test"}
  2 {.cfg.procmenu configure -text "warble yes/no test"}
  3 {.cfg.procmenu configure -text "odd one out test"}
  4 {.cfg.procmenu configure -text "tuning"}
  5 {.cfg.procmenu configure -text "high / low test"}
  6 {.cfg.procmenu configure -text "chord odd one out test"}
  }
}

pack forget  $p.1 $p.2 $p.3 $p.4 $p.know $p.yes $p.no $p.high $p.low $p.tuner $p.warbler
switch $sel {
  1 {
    pack $p.high $p.low $p.know -side left -anchor w
    }
  2 {
    pack $p.yes $p.no $p.warbler -side left -anchor w
    }
  3 {
    pack  $p.1 $p.2 $p.3 $p.4 $p.know -side left -anchor w
    }
  4 {
    pack  $p.tuner -side left -anchor w
    $p.tuner configure -state normal -from -50 -to 50
    }
  5 {
    pack $p.high $p.low $p.know -side left -anchor w
    }
  6 {
    pack  $p.1 $p.2 $p.3 $p.4 $p.know -side left -anchor w
    }
  }
}

proc setpath {path_var} {
    global midi
    set filedir [file dirname $midi($path_var)]
    set openfile [tk_getOpenFile -initialdir $filedir]
    if {[string length $openfile] > 0} {
        set midi($path_var) $openfile
        update
    }
}

proc show_message_page {text} {
    if {![winfo exist .tools]} {tools_init}
    if {[winfo ismapped .tools] == 0} {pack .tools}
    set p .tools
    pack forget $p.can
    pack $p.t
    $p.t delete 1.0 end
    $p.t insert end $text
}

proc save_data {} {
global midi
global oddoutdata
global highlowdata
global chordhighlowdata
global chordoddoutdata
global tuningdata
global chordoddoutdata
if {![file exist pitchdata]} {file mkdir pitchdata}

if {[llength $oddoutdata] > 0} {
  set filepath [file join $midi(datadir) oddout.dat]
  set outhandle [open $filepath w]
  foreach data $oddoutdata {
	puts $outhandle $data
    }
close $outhandle
}

if {[llength $chordoddoutdata] > 0} {
  set filepath [file join $midi(datadir) chordoddout.dat]
  set outhandle [open $filepath w]
  foreach data $chordoddoutdata {
	puts $outhandle $data
    }
close $outhandle
}

if {[llength $highlowdata] > 0} {
  set filepath [file join $midi(datadir) highlow.dat]
  set outhandle [open $filepath w]
  foreach data $highlowdata {
	puts $outhandle $data
    }
close $outhandle
}

if {[llength $chordhighlowdata] > 0} {
  set filepath [file join $midi(datadir) chordhighlow.dat]
  set outhandle [open $filepath w]
  foreach data $chordhighlowdata {
	puts $outhandle $data
    }
close $outhandle
}

if {[llength $tuningdata] > 0} {
  set filepath [file join $midi(datadir) tuning.dat]
  set outhandle [open $filepath w]
  foreach data $tuningdata {
	puts $outhandle $data
   }
  close $outhandle
}

}

proc load_data {} {
global midi
global oddoutdata
global highlowdata
global chordhighlowdata
global chordoddoutdata
global tuningdata
set filepath [file join $midi(datadir) oddout.dat]
if {[file exist $filepath]} {
   set inhandle [open $filepath r]
   while {[gets $inhandle line] >= 0} {
	   lappend oddoutdata $line
         }
   close $inhandle
   }
set filepath [file join $midi(datadir) chordoddout.dat]
if {[file exist $filepath]} {
   set inhandle [open $filepath r]
   while {[gets $inhandle line] >= 0} {
	   lappend chordoddoutdata $line
         }
   close $inhandle
   }
set filepath [file join $midi(datadir) highlow.dat]
if {[file exist $filepath]} {
   set inhandle [open $filepath r]
   while {[gets $inhandle line] >= 0} {
	   lappend highlowdata $line
         }
   close $inhandle
   }
set filepath [file join $midi(datadir) tuning.dat]
if {[file exist $filepath]} {
   set inhandle [open $filepath r]
   while {[gets $inhandle line] >= 0} {
	   lappend tuningdata $line
         }
   close $inhandle
   }
set filepath [file join $midi(datadir) chordhighlow.dat]
if {[file exist $filepath]} {
   set inhandle [open $filepath r]
   while {[gets $inhandle line] >= 0} {
	   lappend chordhighlowdata $line
         }
   close $inhandle
   }
#puts $oddoutdata
#puts $highlowdata
#puts $tuningdata
}


proc plot_results {} {
global midi
if {![winfo exist .tools]} {tools_init}
if {[winfo ismapped .tools] == 0} {pack .tools}
pack forget .tools.ysbar
pack forget .tools.t
pack .tools.can
set pitchc .tools.can
switch $midi(procedure) {
  1 {plot_highlowdata}
  3 {plot_oddoutdata}
  4 {plot_tuning}
  5 {plot_chordhighlowdata}
  6 {plot_chordoddoutdata}
  }
}

proc plot_tuning {} {
global midi
global font df
global tuningdata
set max 0
array unset misstune
foreach record $tuningdata {
  set offtune [lindex $record 1]
  if {[info exist misstune($offtune)]} {
     set misstune($offtune) [expr $misstune($offtune) + 1]
     } else {
     set misstune($offtune) 1
     }
  if {$misstune($offtune) > $max} {set max $misstune($offtune)}
  }

set toplevel [expr $max +5]

  if {![winfo exist .tools]} {tools_init}
  set pitchc .tools.can

  $pitchc delete all

  $pitchc create text  200 10 -text "tuning" -font $df
  $pitchc create rectangle 40 30 420 170 -outline black\
           -width 2 -fill white
  Graph::alter_transformation 40 420 170 30  -25.0 25.0 0.0 $toplevel
  Graph::draw_y_ticks $pitchc 0.0 13 2 1 %2.0f
  Graph::draw_x_ticks $pitchc -18.0 20.0 3.0 2 0 %2.0f

  set tuneplot ""
  for {set i -25} {$i < 25} {incr i} {
    if {[info exist misstune($i)]} {
       lappend tuneplot $i
       lappend tuneplot $misstune($i)
       }
    }

  Graph::draw_impulses_from_list $pitchc $tuneplot blue
}


proc plot_oddoutdata {} {
global midi
global df
global oddoutdata
array unset wrong
array unset right

set max 0
foreach record $oddoutdata {
  set choice [lindex $record 3]
  set answer [lindex $record 2]
  set cents  [lindex $record 1]	
  if {$choice == $answer} {
        if {[info exist right($cents)]} {
	  set right($cents) [expr $right($cents) + 1]
          } else {
	  set right($cents) 1
          }
	if {$right($cents) > $max} {set max $right($cents)}

        } else {
        if {[info exist wrong($cents)]} {
          set wrong($cents) [expr $wrong($cents) + 1]
          } else {
          set wrong($cents) 1
          }
	if {$wrong($cents) > $max} {set max $wrong($cents)}
        } 
     }

    if {![winfo exist .tools]} {tools_init}
    set pitchc .tools.can

    $pitchc delete all

    $pitchc create text  200 10 -text "odd out" -font $df
    set topcount [expr $max + 5]
    $pitchc create rectangle 40 30 420 170 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 40 420 170 30  -$midi(maxshift) $midi(maxshift) 0.0 $topcount
    Graph::draw_y_ticks $pitchc 0.0 $topcount 2 1 %2.0f
    Graph::draw_x_ticks $pitchc -$midi(maxshift) $midi(maxshift) 3.0 2 0 %2.0f

  set rightplotdata ""
  set wrongplotdata ""
  for {set i -35} {$i < 35} {incr i} {
    #puts "$i $right($i) $wrong($i)"
    lappend rightplotdata $i
    lappend wrongplotdata [expr $i + 0.2]
    if {[info exist right($i)]} {
      lappend rightplotdata $right($i)    
      } else {
      lappend rightplotdata 0
      }
    if {[info exist wrong($i)]} {
      lappend wrongplotdata $wrong($i)
      } else {
      lappend wrongplotdata 0
    }
  }
 Graph::draw_impulses_from_list $pitchc $rightplotdata blue
 Graph::draw_impulses_from_list $pitchc $wrongplotdata red 
 } 

proc plot_highlowdata {} {
global midi
global df
global highlowdata

set max 0
array unset wrong
array unset right

foreach record $highlowdata {
	set choice [lindex $record 3]
        set answer [lindex $record 2]
        set cents  [lindex $record 1]	
	if {$choice == $answer} {
          if {[info exist right($cents)]} {
		set right($cents) [expr $right($cents) + 1]
	        } else {
		set right($cents)  1
	        }
          if {$right($cents) > $max} {set max $right($cents)}
       } else {
            if {[info exist wrong($cents)]} {
                set wrong($cents) [expr $wrong($cents) + 1]
            } else {
                set wrong($cents) 1
		}
            if {$wrong($cents) > $max} {set max $wrong($cents)}
	    } 
        }

set pitchc .tools.can

$pitchc delete all
$pitchc create text 200 10 -text "high/low" -font $df

set topcount [expr $max + 5]
$pitchc create rectangle 40 30 420 170 -outline black\
            -width 2 -fill white
Graph::alter_transformation 40 420 170 30  0.0 $midi(maxshift) 0.0 $topcount
Graph::draw_x_ticks $pitchc 0.0 $midi(maxshift) 3.0 2 0 %2.0f
Graph::draw_y_ticks $pitchc 0.0 $topcount 2 1 %2.0f

  set rightplotdata ""
  set wrongplotdata ""
  for {set i 0} {$i < 21} {incr i} {
    #puts "$i $right($i) $wrong($i)"
    lappend rightplotdata $i
    lappend wrongplotdata [expr $i + 0.2]
    if {[info exist right($i)]} {
       lappend rightplotdata $right($i)    
       } else {
       lappend rightplotdata 0
       }    
    if {[info exist wrong($i)]} {
       lappend wrongplotdata $wrong($i)
       } else {
       lappend wrongplotdata 0
       }
    }
 Graph::draw_impulses_from_list $pitchc $rightplotdata blue
 Graph::draw_impulses_from_list $pitchc $wrongplotdata red 
}

proc plot_chordhighlowdata {} {
global midi
global df
global chordhighlowdata

set max 0
array unset wrong
array unset right

foreach record $chordhighlowdata {
	set choice [lindex $record 4]
        set answer [lindex $record 3]
        set cents  [lindex $record 2]	
	if {$choice == $answer} {
          if {[info exist right($cents)]} {
		set right($cents) [expr $right($cents) + 1]
	        } else {
		set right($cents)  1
	        }
          if {$right($cents) > $max} {set max $right($cents)}
        } else {
          if {[info exist wrong($cents)]} {
                set wrong($cents) [expr $wrong($cents) + 1]
            } else {
                set wrong($cents) 1
		}
          if {$wrong($cents) > $max} {set max $wrong($cents)}
          } 
    }

set pitchc .tools.can

$pitchc delete all
$pitchc create text 200 10 -text "chord high/low" -font $df

set topcount [expr $max + 5]
$pitchc create rectangle 40 30 420 170 -outline black\
            -width 2 -fill white
Graph::alter_transformation 40 420 170 30  0.0 $midi(maxshift) 0.0 $topcount
Graph::draw_x_ticks $pitchc 0.0 $midi(maxshift) 3.0 2 0 %2.0f
Graph::draw_y_ticks $pitchc 0.0 $topcount 2 1 %2.0f

  set rightplotdata ""
  set wrongplotdata ""
  for {set i 0} {$i < 30} {incr i} {
    lappend rightplotdata $i
    lappend wrongplotdata [expr $i + 0.2]
    if {[info exist right($i)]} {
       lappend rightplotdata $right($i)    
       } else {
       lappend rightplotdata  0   
       }
    if {[info exist wrong($i)]} {
       lappend wrongplotdata $wrong($i)
       } else {
       lappend wrongplotdata 0
       }
    }
 Graph::draw_impulses_from_list $pitchc $rightplotdata blue
 Graph::draw_impulses_from_list $pitchc $wrongplotdata red 
}


proc plot_chordoddoutdata {} {
global midi
global df
global chordoddoutdata
array unset wrong
array unset right

set max 0
foreach record $chordoddoutdata {
  set choice [lindex $record 4]
  set answer [lindex $record 3]
  set cents  [lindex $record 2]	
  if {$choice == $answer} {
          if {[info exist right($cents)]} {
		set right($cents) [expr $right($cents) + 1]
	        } else {
		set right($cents)  1
	        }
	if {$right($cents) > $max} {set max $right($cents)}
   } else {
          if {[info exist wrong($cents)]} {
                set wrong($cents) [expr $wrong($cents) + 1]
            } else {
                set wrong($cents) 1
		}
	if {$wrong($cents) > $max} {set max $wrong($cents)}
    } 

    if {![winfo exist .tools]} {tools_init}
    set pitchc .tools.can

    $pitchc delete all

    $pitchc create text  200 10 -text "chord odd out" -font $df
    set topcount [expr $max + 5]
    $pitchc create rectangle 40 30 420 170 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 40 420 170 30  -$midi(maxshift) $midi(maxshift) 0.0 $topcount
    Graph::draw_y_ticks $pitchc 0.0 $topcount 2 1 %2.0f
    Graph::draw_x_ticks $pitchc -$midi(maxshift) $midi(maxshift) 3.0 2 0 %2.0f

  set rightplotdata ""
  set wrongplotdata ""
  for {set i -35} {$i < 35} {incr i} {
    #puts "$i $right($i) $wrong($i)"
    lappend rightplotdata $i
    lappend wrongplotdata [expr $i + 0.2]
    if {[info exist right($i)]} {
       lappend rightplotdata $right($i)    
       } else {
       lappend rightplotdata  0   
       }
    if {[info exist wrong($i)]} {
       lappend wrongplotdata $wrong($i)
       } else {
       lappend wrongplotdata 0
       }
    }
 Graph::draw_impulses_from_list $pitchc $rightplotdata blue
 Graph::draw_impulses_from_list $pitchc $wrongplotdata red 
 } 
}




proc tools_init {} {
global df
global midi
frame .tools
pack .tools
frame .tools.plot
text .tools.t -height 15 -width 40 -wrap word -font $df -yscrollcommand {
            .tools.ysbar set}
scrollbar .tools.ysbar -orient vertical -command {.tools.t yview}
pack .tools.ysbar -side right -fill y -in .tools
pack .tools.t -in .tools -expand true -fill both
.tools.t tag configure grey -background grey80
canvas .tools.can -width 450 -height 200
}

set sharpnotes {c ^c d ^d e f ^f g ^g a ^a b}
set flatnotes {c _d d _e e f _g g _a a _b b}

proc count_octaves {note} {
# count number of "'" or "," in the string note
set pos 0
set n 0
set loc [string first "'" $note $pos]	
while {$loc > 0} {
	incr n
	set pos $loc
	incr pos
        set loc [string first "'" $note $pos]	
        }
if {$n > 0} {return $n}

set pos 0
set loc [string first "," $note $pos]	
while {$loc > 0} {
	incr n -1
	set pos $loc
	incr pos
        set loc [string first "'" $note $pos]	
        }
if {$n < 0} {return $n}
return 0
}

proc note2midipitch {note} {
global sharpnotes
global flatnotes
set add 0
if {[string index $note 0] == "^" || [string index $note 0] == "_"} {
	set anote [string index $note 1]
   } else {
	set anote [string index $note 0]
   }
set lower [string is lower $anote]
set anote [string tolower $anote]
set loc [lsearch -nocase $sharpnotes $anote]
if {$loc < 0} {
  set loc [lsearch -nocase $flatnotes $anote]
  }
if {$lower} {set loc [expr $loc + 12]}
set octaves [count_octaves $note] 
set midipitch [expr $loc + $octaves*12 +60]
if {[string index $note 0] == "^"} {incr midipitch}
if {[string index $note 0] == "_"} {incr midipitch -1}
return $midipitch
}

proc midipitch2note {pitch useflats} {
global sharpnotes
global flatnotes
set val [expr $pitch % 12]
if {$useflats} {set note [lindex $flatnotes $val]
        } else {
               set note [lindex $sharpnotes $val]
               }
if {$pitch < 72} {set note [string toupper $note]}
set octave [expr $pitch/12]
switch $octave {
     1 {append note ",,,,"}
     2 {append note ",,,"}
     3 {append note ",,"}
     4 {append note ","}
     7 {append note "'"}
     8 {append note "''"}
     9 {append note "'''"}
    10 {append note "''''"}
    }
return $note
}


proc transpose_note {note shift useflats} {
set midival  [note2midipitch $note] 
set newmidival [expr $midival + $shift]
set newnote [midipitch2note $newmidival $useflats]
#puts "$note $shift $useflats $midival $newmidival $newnote"
return $newnote
}




###   Graph ### support functions

namespace eval Graph {
    
    variable x_scale
    variable y_scale
    variable x_shift
    variable  y_shift
    variable left_edge
    variable bottom_edge
    variable top_edge
    variable right_edge
    
    
    
    namespace export set_xmapping
    proc set_xmapping {left right xleft xright} {
        variable x_scale
        variable x_shift
        variable left_edge
        variable right_edge
        set left_edge $left
        set right_edge $right
        set x_scale [expr double($right - $left) / double($xright - $xleft)]
        set x_shift [expr $left - $xleft*$x_scale]
    }
    
    namespace export set_ymapping
    proc set_ymapping {bottom top ybot ytop} {
        variable y_scale
        variable  y_shift
        variable bottom_edge
        variable top_edge
        set bottom_edge $bottom
        set top_edge $top
        set y_scale [expr double($top - $bottom) / double($ytop - $ybot)]
        set y_shift [expr $bottom - $ybot*$y_scale]
    }
    
    
    namespace export save_transform
    proc save_transform { } {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        list $x_scale $y_scale $x_shift $y_shift
    }
    
    
    namespace export restore_transform
    proc restore_transform {xfm} {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        foreach {x_scale y_scale x_shift y_shift} $xfm {}
    }
    
    
    namespace export alter_transformation
    proc alter_transformation {left right bottom top xleft xright ybot ytop} {
        set_xmapping $left $right $xleft $xright
        set_ymapping $bottom $top $ybot $ytop
    }
    
    namespace export ixpos
    proc ixpos xval {
        variable x_scale
        variable x_shift
        return [expr $x_shift + $xval*$x_scale]
    }
    
    namespace export iypos
    proc iypos yval {
        variable y_scale
        variable y_shift
        return [expr $y_shift + $yval*$y_scale]
    }
    
    
    namespace export draw_x_ticks
    proc draw_x_ticks {can xstart xend xstep nskip labindex fmt} {
        global dff
        variable bottom_edge
        set xticks {}
        set i 0
        for {set x $xstart} {$x < $xend} {set x [expr $x + $xstep]} {
            set ix [ixpos $x]
            set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                    [expr $bottom_edge - 5]]]
            if {[expr $i % $nskip] == $labindex} {
                set str [format $fmt $x]
                set xticks [concat $xticks [$can create text $ix \
                        [expr $bottom_edge + 20] -text $str -font $dff]]
                set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                        [expr $bottom_edge - 10]]]
            }
            incr i
        }
        set xticks
    }


    
    namespace export draw_y_ticks
    proc draw_y_ticks {can ystart yend ystep nskip fmt} {
        global dff
	variable top_edge
	variable left_edge
        set i 0
        set yticks {}
        for {set y $ystart} {$y < $yend} {set y [expr $y + $ystep]} {
            set iy [iypos $y]
	    if {$iy < $top_edge} break
            set yticks [concat $yticks [$can create line  $left_edge \
                    $iy [expr $left_edge + 5] $iy]]
            if {[expr $i % $nskip] == 0} {
                set str [format $fmt $y]
                set yticks [concat $yticks [$can create text \
                        [expr $left_edge - 23] $iy -text $str -font $dff]]
                set yticks [concat $yticks [$can create line \
                        $left_edge $iy [expr $left_edge + 10] $iy]]
            }
            incr i
        }
        set yticks
    }
    
    
    namespace export draw_graph_from_arrays
    proc draw_graph_from_arrays {can xvals yvals npoints} {
        upvar $xvals xdata
        upvar $yvals ydata
        set points {}
        for {set i 0} {$i < $npoints} {incr i} {
            set ix [ixpos $xdata($i)]
            set iy [iypos $ydata($i)]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    
    namespace export draw_graph_from_list
    proc draw_graph_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        set points {}
        foreach {xdata ydata} $datalist {
            set ix [ixpos $xdata]
            set iy [iypos $ydata]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    namespace export draw_impulses_from_list
    proc draw_impulses_from_list {can datalist color} {
        #can canvas
        #datalist {x y x y x y ...}
        foreach {xdata ydata} $datalist {
            if {$ydata != 0.0} {
                set ix [ixpos $xdata]
                set iy [iypos $ydata]
                $can create line $ix [iypos 0] $ix $iy -fill $color -width 2
            }
        }
    }
} ;# end of namespace declaration

namespace import Graph::*


# save all options, current abc file
proc write_ini {} {
    global midi
    set handle [open pitchdif.ini w]
    foreach item [lsort [array names midi]] {
        puts $handle "$item $midi($item)"
    }
    close $handle
}

proc read_ini {} {
    global midi
    if {[file exist pitchdif.ini] == 0} return
    set handle [open pitchdif.ini r]
    #tk_messageBox -message "reading $infile"  -type ok
    while {[gets $handle line] >= 0} {
        set error_return [catch {set n [llength $line]} error_out]
        if {$error_return} continue
        set param [lindex $line 0]
	set value [lindex $line 1]
	if {[info exist midi($param)]} {
          set midi($param) $value
          }
        }
    }

proc pitchdif_init {} {
    global midi 
    global tcl_platform
    set midi(midiplayer) timidity
    set midi(abc2midi) abc2midi
    set midi(program) 79
    set midi(tempo) 60
    set midi(note) c
    set midi(maxshift) 25.0
    set midi(minshift) 0.0
    set midi(warbledepth) 20.0
    set midi(procedure) 0
    set midi(chordinterval) -7
    set midi(datadir) pitchdata
    }


pitchdif_init
read_ini
test $midi(procedure)
load_data

wm protocol . WM_DELETE_WINDOW {
    write_ini 
    save_data
    exit
    }

