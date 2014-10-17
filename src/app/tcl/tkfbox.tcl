# tkfbox.tcl --
#
#	Implements the "TK" standard file selection dialog box. This
#	dialog box is used on the Unix platforms whenever the tk_strictMotif
#	flag is not set.
#
#	The "TK" standard file selection dialog box is similar to the
#	file selection dialog box on Win95(TM). The user can navigate
#	the directories by clicking on the folder icons or by
#	selecting the "Directory" option menu. The user can select
#	files by clicking on the file icons or by entering a filename
#	in the "Filename:" entry.
#
# RCS: @(#) $Id: tkfbox.tcl,v 1.51 2005/04/12 20:33:13 hobbs Exp $
#
# Copyright (c) 1994-1998 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

#----------------------------------------------------------------------
#
#		      I C O N   L I S T
#
# This is a pseudo-widget that implements the icon list inside the 
# ::tk::dialog::file:: dialog box.
#
#----------------------------------------------------------------------

# ::tk::IconList --
#
#	Creates an IconList widget.
#
proc ::tk::IconList {w args} {
    IconList_Config $w $args
    IconList_Create $w
}

proc ::tk::IconList_Index {w i} {
    upvar #0 ::tk::$w data ::tk::$w:itemList itemList
    if {![info exists data(list)]} {
	set data(list) {}
    }
    switch -regexp -- $i {
	"^-?[0-9]+$" {
	    if { $i < 0 } {
		set i 0
	    }
	    if { $i >= [llength $data(list)] } {
		set i [expr {[llength $data(list)] - 1}]
	    }
	    return $i
	}
	"^active$" {
	    return $data(index,active)
	}
	"^anchor$" {
	    return $data(index,anchor)
	}
	"^end$" {
	    return [llength $data(list)]
	}
	"@-?[0-9]+,-?[0-9]+" {
	    foreach {x y} [scan $i "@%d,%d"] {
		break
	    }
	    set item [$data(canvas) find closest \
		    [$data(canvas) canvasx $x] [$data(canvas) canvasy $y]]
	    return [lindex [$data(canvas) itemcget $item -tags] 1]
	}
    }
}

proc ::tk::IconList_Selection {w op args} {
    upvar ::tk::$w data
    switch -exact -- $op {
	"anchor" {
	    if { [llength $args] == 1 } {
		set data(index,anchor) [tk::IconList_Index $w [lindex $args 0]]
	    } else {
		return $data(index,anchor)
	    }
	}
	"clear" {
	    if { [llength $args] == 2 } {
		foreach {first last} $args {
		    break
		}
	    } elseif { [llength $args] == 1 } {
		set first [set last [lindex $args 0]]
	    } else {
		error "wrong # args: should be [lindex [info level 0] 0] path\
			clear first ?last?"
	    }
	    set first [IconList_Index $w $first]
	    set last [IconList_Index $w $last]
	    if { $first > $last } {
		set tmp $first
		set first $last
		set last $tmp
	    }
	    set ind 0
	    foreach item $data(selection) {
		if { $item >= $first } {
		    set first $ind
		    break
		}
		incr ind
	    }
	    set ind [expr {[llength $data(selection)] - 1}]
	    for {} {$ind >= 0} {incr ind -1} {
		set item [lindex $data(selection) $ind]
		if { $item <= $last } {
		    set last $ind
		    break
		}
	    }

	    if { $first > $last } {
		return
	    }
	    set data(selection) [lreplace $data(selection) $first $last]
	    event generate $w <<ListboxSelect>>
	    IconList_DrawSelection $w
	}
	"includes" {
	    set index [lsearch -exact $data(selection) [lindex $args 0]]
	    return [expr {$index != -1}]
	}
	"set" {
	    if { [llength $args] == 2 } {
		foreach {first last} $args {
		    break
		}
	    } elseif { [llength $args] == 1 } {
		set last [set first [lindex $args 0]]
	    } else {
		error "wrong # args: should be [lindex [info level 0] 0] path\
			set first ?last?"
	    }

	    set first [IconList_Index $w $first]
	    set last [IconList_Index $w $last]
	    if { $first > $last } {
		set tmp $first
		set first $last
		set last $tmp
	    }
	    for {set i $first} {$i <= $last} {incr i} {
		lappend data(selection) $i
	    }
	    set data(selection) [lsort -integer -unique $data(selection)]
	    event generate $w <<ListboxSelect>>
	    IconList_DrawSelection $w
	}
    }
}

proc ::tk::IconList_Curselection {w} {
    upvar ::tk::$w data
    return $data(selection)
}

proc ::tk::IconList_DrawSelection {w} {
    upvar ::tk::$w data
    upvar ::tk::$w:itemList itemList

    $data(canvas) delete selection
    foreach item $data(selection) {
	set rTag [lindex [lindex $data(list) $item] 2]
	foreach {iTag tTag text serial} $itemList($rTag) {
	    break
	}

	set bbox [$data(canvas) bbox $tTag]
	set new_bbox [list [expr {[lindex $bbox 0] - 2}] [expr {[lindex $bbox 1] - 1}] \
		 [expr {[lindex $bbox 2] + 1}] [expr {[lindex $bbox 3] + 1}]]
	
        $data(canvas) create rect $new_bbox -fill \#d8e2eb -outline \#678db2 \
		-tags selection
    }
    $data(canvas) lower selection
    return
}

proc ::tk::IconList_Get {w item} {
    upvar ::tk::$w data
    upvar ::tk::$w:itemList itemList
    set rTag [lindex [lindex $data(list) $item] 2]
    foreach {iTag tTag text serial} $itemList($rTag) {
	break
    }
    return $text
}

# ::tk::IconList_Config --
#
#	Configure the widget variables of IconList, according to the command
#	line arguments.
#
proc ::tk::IconList_Config {w argList} {

    # 1: the configuration specs
    #
    set specs {
	{-command "" "" ""}
	{-multiple "" "" "0"}
    }

    # 2: parse the arguments
    #
    tclParseConfigSpec ::tk::$w $specs "" $argList
}

# ::tk::IconList_Create --
#
#	Creates an IconList widget by assembling a canvas widget and a
#	scrollbar widget. Sets all the bindings necessary for the IconList's
#	operations.
#
proc ::tk::IconList_Create {w} {
    upvar ::tk::$w data

    frame $w -bd 0
    set data(sbar)   [ttk::scrollbar $w.sbar -orient horizontal -takefocus 0]
    set data(canvas) [canvas $w.canvas -bd 0 -relief flat \
	    -width 650 -height 250 -takefocus 1 -bg white]
    pack $data(sbar) -side bottom -fill x 
    pack $data(canvas) -expand yes -fill both

    $data(sbar) config -command [list $data(canvas) xview]
    $data(canvas) config -xscrollcommand [list $data(sbar) set]

    # Initializes the max icon/text width and height and other variables
    #
    set data(maxIW) 1
    set data(maxIH) 1
    set data(maxTW) 1
    set data(maxTH) 1
    set data(numItems) 0
    set data(curItem)  {}
    set data(noScroll) 1
    set data(selection) {}
    set data(index,anchor) ""
    set fg [option get $data(canvas) foreground Foreground]
    if {$fg eq ""} {
	set data(fill) black
    } else {
	set data(fill) $fg
    }

    # Creates the event bindings.
    #
    bind $data(canvas) <Configure>	[list tk::IconList_Arrange $w]

    bind $data(canvas) <1>		[list tk::IconList_Btn1 $w %x %y]
    bind $data(canvas) <B1-Motion>	[list tk::IconList_Motion1 $w %x %y]
    bind $data(canvas) <B1-Leave>	[list tk::IconList_Leave1 $w %x %y]
    bind $data(canvas) <Control-1>	[list tk::IconList_CtrlBtn1 $w %x %y]
    bind $data(canvas) <Shift-1>	[list tk::IconList_ShiftBtn1 $w %x %y]
    bind $data(canvas) <B1-Enter>	[list tk::CancelRepeat]
    bind $data(canvas) <ButtonRelease-1> [list tk::CancelRepeat]
    bind $data(canvas) <Double-ButtonRelease-1> \
	    [list tk::IconList_Double1 $w %x %y]

    bind $data(canvas) <Control-B1-Motion> {;}
    bind $data(canvas) <Shift-B1-Motion> \
	    [list tk::IconList_ShiftMotion1 $w %x %y]

    bind $data(canvas) <Up>		[list tk::IconList_UpDown $w -1]
    bind $data(canvas) <Down>		[list tk::IconList_UpDown $w  1]
    bind $data(canvas) <Left>		[list tk::IconList_LeftRight $w -1]
    bind $data(canvas) <Right>		[list tk::IconList_LeftRight $w  1]
    bind $data(canvas) <Return>		[list tk::IconList_ReturnKey $w]
    bind $data(canvas) <KeyPress>	[list tk::IconList_KeyPress $w %A]
    bind $data(canvas) <Control-KeyPress> ";"
    bind $data(canvas) <Alt-KeyPress>	";"

    bind $data(canvas) <FocusIn>	[list tk::IconList_FocusIn $w]
    bind $data(canvas) <FocusOut>	[list tk::IconList_FocusOut $w]

    return $w
}

# ::tk::IconList_AutoScan --
#
# This procedure is invoked when the mouse leaves an entry window
# with button 1 down.  It scrolls the window up, down, left, or
# right, depending on where the mouse left the window, and reschedules
# itself as an "after" command so that the window continues to scroll until
# the mouse moves back into the window or the mouse button is released.
#
# Arguments:
# w -		The IconList window.
#
proc ::tk::IconList_AutoScan {w} {
    upvar ::tk::$w data
    variable ::tk::Priv

    if {![winfo exists $w]} return
    set x $Priv(x)
    set y $Priv(y)

    if {$data(noScroll)} {
	return
    }
    if {$x >= [winfo width $data(canvas)]} {
	$data(canvas) xview scroll 1 units
    } elseif {$x < 0} {
	$data(canvas) xview scroll -1 units
    } elseif {$y >= [winfo height $data(canvas)]} {
	# do nothing
    } elseif {$y < 0} {
	# do nothing
    } else {
	return
    }

    IconList_Motion1 $w $x $y
    set Priv(afterId) [after 50 [list tk::IconList_AutoScan $w]]
}

# Deletes all the items inside the canvas subwidget and reset the IconList's
# state.
#
proc ::tk::IconList_DeleteAll {w} {
    upvar ::tk::$w data
    upvar ::tk::$w:itemList itemList

    $data(canvas) delete all
    catch {unset data(selected)}
    catch {unset data(rect)}
    catch {unset data(list)}
    catch {unset itemList}
    set data(maxIW) 1
    set data(maxIH) 1
    set data(maxTW) 1
    set data(maxTH) 1
    set data(numItems) 0
    set data(curItem)  {}
    set data(noScroll) 1
    set data(selection) {}
    set data(index,anchor) ""
    $data(sbar) set 0.0 1.0
    $data(canvas) xview moveto 0
}

# Adds an icon into the IconList with the designated image and text
#
proc ::tk::IconList_Add {w image items} {
    upvar ::tk::$w data
    upvar ::tk::$w:itemList itemList
    upvar ::tk::$w:textList textList

    foreach text $items {
	set iTag [$data(canvas) create image 0 0 -image $image -anchor nw \
		-tags [list icon $data(numItems) item$data(numItems)]]
	set tTag [$data(canvas) create text  0 0 -text  $text  -anchor nw \
		-font $data(font) -fill $data(fill) \
		-tags [list text $data(numItems) item$data(numItems)]]
	set rTag [$data(canvas) create rect  0 0 0 0 -fill "" -outline "" \
		-tags [list rect $data(numItems) item$data(numItems)]]
	
	foreach {x1 y1 x2 y2} [$data(canvas) bbox $iTag] {
	    break
	}
	set iW [expr {$x2 - $x1}]
	set iH [expr {$y2 - $y1}]
	if {$data(maxIW) < $iW} {
	    set data(maxIW) $iW
	}
	if {$data(maxIH) < $iH} {
	    set data(maxIH) $iH
	}
    
	foreach {x1 y1 x2 y2} [$data(canvas) bbox $tTag] {
	    break
	}
	set tW [expr {$x2 - $x1}]
	set tH [expr {$y2 - $y1}]
	if {$data(maxTW) < $tW} {
	    set data(maxTW) $tW
	}
	if {$data(maxTH) < $tH} {
	    set data(maxTH) $tH
	}
    
	lappend data(list) [list $iTag $tTag $rTag $iW $iH $tW \
		$tH $data(numItems)]
	set itemList($rTag) [list $iTag $tTag $text $data(numItems)]
	set textList($data(numItems)) [string tolower $text]
	incr data(numItems)
    }
}

# Places the icons in a column-major arrangement.
#
proc ::tk::IconList_Arrange {w} {
    upvar ::tk::$w data

    if {![info exists data(list)]} {
	if {[info exists data(canvas)] && [winfo exists $data(canvas)]} {
	    set data(noScroll) 1
	    $data(sbar) config -command ""
	}
	return
    }

    set W [winfo width  $data(canvas)]
    set H [winfo height $data(canvas)]
    set pad [expr {[$data(canvas) cget -highlightthickness] + \
	    [$data(canvas) cget -bd]}]
    if {$pad < 2} {
	set pad 2
    }

    incr W -[expr {$pad*2}]
    incr H -[expr {$pad*2}]

    set dx [expr {$data(maxIW) + $data(maxTW) + 8}]
    if {$data(maxTH) > $data(maxIH)} {
	set dy $data(maxTH)
    } else {
	set dy $data(maxIH)
    }
    incr dy 2
    set shift [expr {$data(maxIW) + 4}]

    set x [expr {$pad * 2}]
    set y [expr {$pad * 1}] ; # Why * 1 ?
    set usedColumn 0
    foreach sublist $data(list) {
	set usedColumn 1
	foreach {iTag tTag rTag iW iH tW tH} $sublist {
	    break
	}

	set i_dy [expr {($dy - $iH)/2}]
	set t_dy [expr {($dy - $tH)/2}]

	$data(canvas) coords $iTag $x                    [expr {$y + $i_dy}]
	$data(canvas) coords $tTag [expr {$x + $shift}]  [expr {$y + $t_dy}]
	$data(canvas) coords $rTag $x $y [expr {$x+$dx}] [expr {$y+$dy}]

	incr y $dy
	if {($y + $dy) > $H} {
	    set y [expr {$pad * 1}] ; # *1 ?
	    incr x $dx
	    set usedColumn 0
	}
    }

    if {$usedColumn} {
	set sW [expr {$x + $dx}]
    } else {
	set sW $x
    }

    if {$sW < $W} {
	$data(canvas) config -scrollregion [list $pad $pad $sW $H]
	$data(sbar) config -command ""
	$data(canvas) xview moveto 0
	set data(noScroll) 1
    } else {
	$data(canvas) config -scrollregion [list $pad $pad $sW $H]
	$data(sbar) config -command [list $data(canvas) xview]
	set data(noScroll) 0
    }

    set data(itemsPerColumn) [expr {($H-$pad)/$dy}]
    if {$data(itemsPerColumn) < 1} {
	set data(itemsPerColumn) 1
    }

    if {$data(curItem) != ""} {
	IconList_Select $w [lindex [lindex $data(list) $data(curItem)] 2] 0
    }
    IconList_DrawSelection $w
}

# Gets called when the user invokes the IconList (usually by double-clicking
# or pressing the Return key).
#
proc ::tk::IconList_Invoke {w} {
    upvar ::tk::$w data

    if {$data(-command) != "" && [llength $data(selection)]} {
	uplevel #0 $data(-command)
    }
}

# ::tk::IconList_See --
#
#	If the item is not (completely) visible, scroll the canvas so that
#	it becomes visible.
proc ::tk::IconList_See {w rTag} {
    upvar ::tk::$w data
    upvar ::tk::$w:itemList itemList

    if {$data(noScroll)} {
	return
    }
    set sRegion [$data(canvas) cget -scrollregion]
    if {[string equal $sRegion {}]} {
	return
    }

    if { $rTag < 0 || $rTag >= [llength $data(list)] } {
	return
    }

    set bbox [$data(canvas) bbox item$rTag]
    set pad [expr {[$data(canvas) cget -highlightthickness] + \
	    [$data(canvas) cget -bd]}]

    set x1 [lindex $bbox 0]
    set x2 [lindex $bbox 2]
    incr x1 -[expr {$pad * 2}]
    incr x2 -[expr {$pad * 1}] ; # *1 ?

    set cW [expr {[winfo width $data(canvas)] - $pad*2}]

    set scrollW [expr {[lindex $sRegion 2]-[lindex $sRegion 0]+1}]
    set dispX [expr {int([lindex [$data(canvas) xview] 0]*$scrollW)}]
    set oldDispX $dispX

    # check if out of the right edge
    #
    if {($x2 - $dispX) >= $cW} {
	set dispX [expr {$x2 - $cW}]
    }
    # check if out of the left edge
    #
    if {($x1 - $dispX) < 0} {
	set dispX $x1
    }

    if {$oldDispX != $dispX} {
	set fraction [expr {double($dispX)/double($scrollW)}]
	$data(canvas) xview moveto $fraction
    }
}

proc ::tk::IconList_Btn1 {w x y} {
    upvar ::tk::$w data

    focus $data(canvas)
    set i [IconList_Index $w @$x,$y]
    if {$i eq ""} return
    IconList_Selection $w clear 0 end
    IconList_Selection $w set $i
    IconList_Selection $w anchor $i
}

proc ::tk::IconList_CtrlBtn1 {w x y} {
    upvar ::tk::$w data
    
    if { $data(-multiple) } {
	focus $data(canvas)
	set i [IconList_Index $w @$x,$y]
	if {$i eq ""} return
	if { [IconList_Selection $w includes $i] } {
	    IconList_Selection $w clear $i
	} else {
	    IconList_Selection $w set $i
	    IconList_Selection $w anchor $i
	}
    }
}

proc ::tk::IconList_ShiftBtn1 {w x y} {
    upvar ::tk::$w data
    
    if { $data(-multiple) } {
	focus $data(canvas)
	set i [IconList_Index $w @$x,$y]
	if {$i eq ""} return
	set a [IconList_Index $w anchor]
	if { [string equal $a ""] } {
	    set a $i
	}
	IconList_Selection $w clear 0 end
	IconList_Selection $w set $a $i
    }
}

# Gets called on button-1 motions
#
proc ::tk::IconList_Motion1 {w x y} {
    variable ::tk::Priv
    set Priv(x) $x
    set Priv(y) $y
    set i [IconList_Index $w @$x,$y]
    if {$i eq ""} return
    IconList_Selection $w clear 0 end
    IconList_Selection $w set $i
}

proc ::tk::IconList_ShiftMotion1 {w x y} {
    upvar ::tk::$w data
    variable ::tk::Priv
    set Priv(x) $x
    set Priv(y) $y
    set i [IconList_Index $w @$x,$y]
    if {$i eq ""} return
    IconList_Selection $w clear 0 end
    IconList_Selection $w set anchor $i
}

proc ::tk::IconList_Double1 {w x y} {
    upvar ::tk::$w data

    if {[llength $data(selection)]} {
	IconList_Invoke $w
    }
}

proc ::tk::IconList_ReturnKey {w} {
    IconList_Invoke $w
}

proc ::tk::IconList_Leave1 {w x y} {
    variable ::tk::Priv

    set Priv(x) $x
    set Priv(y) $y
    IconList_AutoScan $w
}

proc ::tk::IconList_FocusIn {w} {
    upvar ::tk::$w data

    if {![info exists data(list)]} {
	return
    }

    if {[llength $data(selection)]} {
	IconList_DrawSelection $w
    }
}

proc ::tk::IconList_FocusOut {w} {
    IconList_Selection $w clear 0 end
}

# ::tk::IconList_UpDown --
#
# Moves the active element up or down by one element
#
# Arguments:
# w -		The IconList widget.
# amount -	+1 to move down one item, -1 to move back one item.
#
proc ::tk::IconList_UpDown {w amount} {
    upvar ::tk::$w data

    if {![info exists data(list)]} {
	return
    }

    set curr [tk::IconList_Curselection $w]
    if { [llength $curr] == 0 } {
	set i 0
    } else {
	set i [tk::IconList_Index $w anchor]
	if {$i eq ""} return
	incr i $amount
    }
    IconList_Selection $w clear 0 end
    IconList_Selection $w set $i
    IconList_Selection $w anchor $i
    IconList_See $w $i
}

# ::tk::IconList_LeftRight --
#
# Moves the active element left or right by one column
#
# Arguments:
# w -		The IconList widget.
# amount -	+1 to move right one column, -1 to move left one column.
#
proc ::tk::IconList_LeftRight {w amount} {
    upvar ::tk::$w data

    if {![info exists data(list)]} {
	return
    }

    set curr [IconList_Curselection $w]
    if { [llength $curr] == 0 } {
	set i 0
    } else {
	set i [IconList_Index $w anchor]
	if {$i eq ""} return
	incr i [expr {$amount*$data(itemsPerColumn)}]
    }
    IconList_Selection $w clear 0 end
    IconList_Selection $w set $i
    IconList_Selection $w anchor $i
    IconList_See $w $i
}

#----------------------------------------------------------------------
#		Accelerator key bindings
#----------------------------------------------------------------------

# ::tk::IconList_KeyPress --
#
#	Gets called when user enters an arbitrary key in the listbox.
#
proc ::tk::IconList_KeyPress {w key} {
    variable ::tk::Priv

    append Priv(ILAccel,$w) $key
    IconList_Goto $w $Priv(ILAccel,$w)
    catch {
	after cancel $Priv(ILAccel,$w,afterId)
    }
    set Priv(ILAccel,$w,afterId) [after 500 [list tk::IconList_Reset $w]]
}

proc ::tk::IconList_Goto {w text} {
    upvar ::tk::$w data
    upvar ::tk::$w:textList textList
    
    if {![info exists data(list)]} {
	return
    }

    if {[string equal {} $text]} {
	return
    }

    if {$data(curItem) eq "" || $data(curItem) == 0} {
	set start  0
    } else {
	set start  $data(curItem)
    }

    set text [string tolower $text]
    set theIndex -1
    set less 0
    set len [string length $text]
    set len0 [expr {$len-1}]
    set i $start

    # Search forward until we find a filename whose prefix is an exact match
    # with $text
    while {1} {
	set sub [string range $textList($i) 0 $len0]
	if {[string equal $text $sub]} {
	    set theIndex $i
	    break
	}
	incr i
	if {$i == $data(numItems)} {
	    set i 0
	}
	if {$i == $start} {
	    break
	}
    }

    if {$theIndex > -1} {
	IconList_Selection $w clear 0 end
	IconList_Selection $w set $theIndex
	IconList_Selection $w anchor $theIndex
	IconList_See $w $theIndex
    }
}

proc ::tk::IconList_Reset {w} {
    variable ::tk::Priv

    catch {unset Priv(ILAccel,$w)}
}

#----------------------------------------------------------------------
#
#		      F I L E   D I A L O G
#
#----------------------------------------------------------------------

namespace eval ::tk::dialog {}
namespace eval ::tk::dialog::file {
    namespace import -force ::tk::msgcat::*
    set ::tk::dialog::file::showHiddenBtn 1
    set ::tk::dialog::file::showHiddenVar 0
}

# ::tk::dialog::file:: --
#
#	Implements the TK file selection dialog. This dialog is used when
#	the tk_strictMotif flag is set to false. This procedure shouldn't
#	be called directly. Call tk_getOpenFile or tk_getSaveFile instead.
#
# Arguments:
#	type		"open" or "save"
#	args		Options parsed by the procedure.
#

proc ::tk::dialog::file:: {type args} {
    variable ::tk::Priv
    set dataName __tk_filedialog
    upvar ::tk::dialog::file::$dataName data

    ::tk::dialog::file::Config $dataName $type $args

    if {[string equal $data(-parent) .]} {
        set w .$dataName
    } else {
        set w $data(-parent).$dataName
    }

    # (re)create the dialog box if necessary
    #
    if {![winfo exists $w]} {
	::tk::dialog::file::Create $w TkFDialog
    } elseif {[winfo class $w] ne "TkFDialog"} {
	destroy $w
	::tk::dialog::file::Create $w TkFDialog
    } else {
	set data(upBtn) $w.f0.f1.up
	set data(dirMenuBtn) $w.f0.f1.menu
	#set data(dirMenu) $w.f0.f1.menu.menu
	set data(icons) $w.f0.f3.icons
	set data(ent) $w.f0.f2.ent
	set data(typeMenuLab) $w.f0.f2.lab2
	set data(typeMenuBtn) $w.f0.f2.menu
	set data(typeMenu) $data(typeMenuBtn).m
	set data(okBtn) $w.f0.f2.ok
	set data(cancelBtn) $w.f0.f2.cancel
	set data(hiddenBtn) $w.f0.f2.hidden
	::tk::dialog::file::SetSelectMode $w $data(-multiple)
    }
    if {$::tk::dialog::file::showHiddenBtn} {
	$data(hiddenBtn) configure -state normal
	grid $data(hiddenBtn)
    } else {
	$data(hiddenBtn) configure -state disabled
	grid remove $data(hiddenBtn)
    }

    # Make sure subseqent uses of this dialog are independent [Bug 845189]
    catch {unset data(extUsed)}

    # Dialog boxes should be transient with respect to their parent,
    # so that they will always stay on top of their parent window.  However,
    # some window managers will create the window as withdrawn if the parent
    # window is withdrawn or iconified.  Combined with the grab we put on the
    # window, this can hang the entire application.  Therefore we only make
    # the dialog transient if the parent is viewable.

    if {[winfo viewable [winfo toplevel $data(-parent)]]} {
	wm transient $w $data(-parent)
    }

    # Add traces on the selectPath variable
    #

    trace variable data(selectPath) w "::tk::dialog::file::SetPath $w"
    $data(dirMenuBtn) configure \
	    -textvariable ::tk::dialog::file::${dataName}(selectPath)

    # Initialize the file types menu
    #
    if {[llength $data(-filetypes)]} {
	$data(typeMenu) delete 0 end
	foreach type $data(-filetypes) {
	    set title  [lindex $type 0]
	    set filter [lindex $type 1]
	    $data(typeMenu) add command -label $title \
		-command [list ::tk::dialog::file::SetFilter $w $type]
	}
	::tk::dialog::file::SetFilter $w [lindex $data(-filetypes) 0]
	$data(typeMenuBtn) config -state normal
	$data(typeMenuLab) config -state normal
    } else {
	set data(filter) "*"
	$data(typeMenuBtn) config -state disabled -takefocus 0
	$data(typeMenuLab) config -state disabled
    }
    ::tk::dialog::file::UpdateWhenIdle $w

    # Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    ::tk::PlaceWindow $w widget $data(-parent)
    wm title $w $data(-title)

    # Set a grab and claim the focus too.

    ::tk::SetFocusGrab $w $data(ent)
    $data(ent) delete 0 end
    $data(ent) insert 0 $data(selectFile)
    $data(ent) selection range 0 end
    $data(ent) icursor end

    # Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    vwait ::tk::Priv(selectFilePath)

    ::tk::RestoreFocusGrab $w $data(ent) withdraw

    # Cleanup traces on selectPath variable
    #

    foreach trace [trace vinfo data(selectPath)] {
	trace vdelete data(selectPath) [lindex $trace 0] [lindex $trace 1]
    }
    $data(dirMenuBtn) configure -textvariable {}

    return $Priv(selectFilePath)
}

# ::tk::dialog::file::Config --
#
#	Configures the TK filedialog according to the argument list
#
proc ::tk::dialog::file::Config {dataName type argList} {
    upvar ::tk::dialog::file::$dataName data

    set data(type) $type

    # 0: Delete all variable that were set on data(selectPath) the
    # last time the file dialog is used. The traces may cause troubles
    # if the dialog is now used with a different -parent option.

    foreach trace [trace vinfo data(selectPath)] {
	trace vdelete data(selectPath) [lindex $trace 0] [lindex $trace 1]
    }

    # 1: the configuration specs
    #
    set specs {
	{-defaultextension "" "" ""}
	{-filetypes "" "" ""}
	{-initialdir "" "" ""}
	{-initialfile "" "" ""}
	{-parent "" "" "."}
	{-title "" "" ""}
    }

    # The "-multiple" option is only available for the "open" file dialog.
    #
    if { [string equal $type "open"] } {
	lappend specs {-multiple "" "" "0"}
    }

    # 2: default values depending on the type of the dialog
    #
    if {![info exists data(selectPath)]} {
	# first time the dialog has been popped up
	set data(selectPath) [pwd]
	set data(selectFile) ""
    }

    # 3: parse the arguments
    #
    tclParseConfigSpec ::tk::dialog::file::$dataName $specs "" $argList

    if {$data(-title) eq ""} {
	if {[string equal $type "open"]} {
	    set data(-title) "[mc "Open"]"
	} else {
	    set data(-title) "[mc "Save As"]"
	}
    }

    # 4: set the default directory and selection according to the -initial
    #    settings
    #
    if {$data(-initialdir) != ""} {
	# Ensure that initialdir is an absolute path name.
	if {[file isdirectory $data(-initialdir)]} {
	    set old [pwd]
	    cd $data(-initialdir)
	    set data(selectPath) [pwd]
	    cd $old
	} else {
	    set data(selectPath) [pwd]
	}
    }
    set data(selectFile) $data(-initialfile)

    # 5. Parse the -filetypes option
    #
    set data(-filetypes) [::tk::FDGetFileTypes $data(-filetypes)]

    if {![winfo exists $data(-parent)]} {
	error "bad window path name \"$data(-parent)\""
    }

    # Set -multiple to a one or zero value (not other boolean types
    # like "yes") so we can use it in tests more easily.
    if {![string compare $type save]} {
	set data(-multiple) 0
    } elseif {$data(-multiple)} { 
	set data(-multiple) 1 
    } else {
	set data(-multiple) 0
    }
}

proc ::tk::dialog::file::Create {w class} {
    set dataName [lindex [split $w .] end]
    upvar ::tk::dialog::file::$dataName data
    variable ::tk::Priv
    global tk_library

    toplevel $w -class $class

    # f1: the frame with the directory option menu
    #
    set f0 [ttk::frame $w.f0 -style FlatFrame -borderwidth 8]
    set f1 [ttk::frame $f0.f1 -style FlatFrame]
    set f3 [ttk::frame $f0.f3 -style RoundedFrame -borderwidth 5]
    bind [::tk::AmpWidget label $f1.lab -text "[mc "&Directory:"]" ] \
	<<AltUnderlined>> [list focus $f1.menu]


    set data(upBtn) [ttk::button $f1.up -style Toolbutton]
    set data(dirMenuBtn) $f1.menu
    set data(dirMenuBtn) [ttk::combobox $f1.menu -state readonly -style ComboNormal \
	-cursor top_left_arrow -values [format %s(selectPath) ::tk::dialog::file::$dataName]]

    if {![info exists Priv(updirImage)]} {
	set Priv(updirImage) [image create bitmap -data {
#define updir_width 28
#define updir_height 16
static char updir_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x80, 0x1f, 0x00, 0x00, 0x40, 0x20, 0x00, 0x00,
   0x20, 0x40, 0x00, 0x00, 0xf0, 0xff, 0xff, 0x01, 0x10, 0x00, 0x00, 0x01,
   0x10, 0x02, 0x00, 0x01, 0x10, 0x07, 0x00, 0x01, 0x90, 0x0f, 0x00, 0x01,
   0x10, 0x02, 0x00, 0x01, 0x10, 0x02, 0x00, 0x01, 0x10, 0x02, 0x00, 0x01,
   0x10, 0xfe, 0x07, 0x01, 0x10, 0x00, 0x00, 0x01, 0x10, 0x00, 0x00, 0x01,
   0xf0, 0xff, 0xff, 0x01};}]
    }
    #$data(upBtn) config -image $Priv(updirImage)
    $data(upBtn) config -image "tk_up"

    $f1.menu config -takefocus 1 
    # -highlightthickness 2

    pack $data(upBtn) -side left -padx 4 -fill both
    pack $f1.lab -side left -padx 4 -fill both
    pack $f1.menu -expand yes -fill both -padx 4

    # data(icons): the IconList that list the files and directories.
    #
    if { [string equal $class TkFDialog] } {
	if { $data(-multiple) } {
	    set fNameCaption [mc "File &names:"]
	} else {
	    set fNameCaption [mc "File &name:"]
	}
	set fTypeCaption [mc "Files of &type:"]
	set iconListCommand [list ::tk::dialog::file::OkCmd $w]
    } else {
	set fNameCaption [mc "&Selection:"]
	set iconListCommand [list ::tk::dialog::file::chooseDir::DblClick $w]
    }
    set data(icons) [::tk::IconList $f3.icons \
	    -command	$iconListCommand \
	    -multiple	$data(-multiple)]
    bind $data(icons) <<ListboxSelect>> \
	    [list ::tk::dialog::file::ListBrowse $w]

    # f2: the frame with the OK button, cancel button, "file name" field
    #     and file types field.
    #
    set f2 [ttk::frame $f0.f2 -style FlatFrame]
    bind [::tk::AmpWidget label $f2.lab -text $fNameCaption -anchor e -pady 0]\
	    <<AltUnderlined>> [list focus $f2.ent]
    set data(ent) [ttk::entry $f2.ent]

    # The font to use for the icons. The default Canvas font on Unix
    # is just deviant.
    set ::tk::$f3.icons(font) [$data(ent) cget -font]

    # Make the file types bits only if this is a File Dialog
    if { [string equal $class TkFDialog] } {
	set data(typeMenuLab) [::tk::AmpWidget label $f2.lab2 \
		-text $fTypeCaption -anchor e -pady [$f2.lab cget -pady]]
	#set data(typeMenuBtn) [menubutton $f2.menu -indicatoron 1 -menu $f2.menu.m]
	set data(typeMenuBtn) [ttk::menubutton $f2.menu -style TComboSmall -menu $f2.menu.m]
	set data(typeMenu) [menu $data(typeMenuBtn).m -tearoff 0]
	#$data(typeMenuBtn) config -takefocus 1 -highlightthickness 2 -relief raised -bd 2 -anchor w
        bind $data(typeMenuLab) <<AltUnderlined>> [list \
		focus $data(typeMenuBtn)]
    }

    # The hidden button is displayed when ::tk::dialog::file::showHiddenBtn
    # is true.  Create it disabled so the binding doesn't trigger if it
    # isn't shown.
    if {$class eq "TkFDialog"} {
	set text [mc "Show &Hidden Files and Directories"]
    } else {
	set text [mc "Show &Hidden Directories"]
    }
    set data(hiddenBtn) [::tk::AmpWidget ttk::checkbutton $f2.hidden \
	    -text $text -state disabled \
	    -variable ::tk::dialog::file::showHiddenVar \
	    -command [list ::tk::dialog::file::UpdateWhenIdle $w]]

    # the okBtn is created after the typeMenu so that the keyboard traversal
    # is in the right order, and add binding so that we find out when the
    # dialog is destroyed by the user (added here instead of to the overall
    # window so no confusion about how much <Destroy> gets called; exactly
    # once will do). [Bug 987169] -pady 3

    set data(okBtn)     [::tk::AmpWidget ttk::button $f2.ok \
	    -text [mc "&OK"]     -default active]
    bind $data(okBtn) <Destroy> [list ::tk::dialog::file::Destroyed $w]
    set data(cancelBtn) [::tk::AmpWidget ttk::button $f2.cancel \
	    -text [mc "&Cancel"] -default normal]

    # grid the widgets in f2
    #
    grid $f2.lab $f2.ent $data(okBtn) -padx 4 -pady 5 -sticky ew
    grid configure $f2.ent -padx 2 -pady 5
    if { [string equal $class TkFDialog] } {
	grid $data(typeMenuLab) $data(typeMenuBtn) $data(cancelBtn) \
		-padx 4 -sticky ew
	grid configure $data(typeMenuBtn) -padx 2
	grid $data(hiddenBtn) -columnspan 2 -padx 65 -pady 5 -sticky ew
    } else {
	grid $data(hiddenBtn) - $data(cancelBtn) -padx 4 -pady 5 -sticky ew
    }
    grid columnconfigure $f2 1 -weight 1

    # Pack all the frames together. We are done with widget construction.
    #
    pack $f0 -side top -fill both -expand yes
    pack $f1 -side top -fill x 
    pack $f2 -side bottom -fill x
    pack $f3 -expand yes -fill both -padx 4 -pady 4
    pack $data(icons) -expand yes -fill both

    # Set up the event handlers that are common to Directory and File Dialogs
    #

    wm protocol $w WM_DELETE_WINDOW [list ::tk::dialog::file::CancelCmd $w]
    $data(upBtn)     config -command [list ::tk::dialog::file::UpDirCmd $w]
    $data(cancelBtn) config -command [list ::tk::dialog::file::CancelCmd $w]
    bind $w <KeyPress-Escape> [list tk::ButtonInvoke $data(cancelBtn)]
    bind $w <Alt-Key> [list tk::AltKeyInDialog $w %A]

    # Set up event handlers specific to File or Directory Dialogs
    #
    if { [string equal $class TkFDialog] } {
	bind $data(ent) <Return> [list ::tk::dialog::file::ActivateEnt $w]
	$data(okBtn)     config -command [list ::tk::dialog::file::OkCmd $w]
	bind $w <Alt-t> [format {
	    if {[string equal [%s cget -state] "normal"]} {
		focus %s
	    }
	} $data(typeMenuBtn) $data(typeMenuBtn)]
    } else {
	set okCmd [list ::tk::dialog::file::chooseDir::OkCmd $w]
	bind $data(ent) <Return> $okCmd
	$data(okBtn) config -command $okCmd
	bind $w <Alt-s> [list focus $data(ent)]
	bind $w <Alt-o> [list tk::ButtonInvoke $data(okBtn)]
    }
    bind $w <Alt-h> [list $data(hiddenBtn) invoke]

    # Build the focus group for all the entries
    #
    ::tk::FocusGroup_Create $w
    ::tk::FocusGroup_BindIn $w  $data(ent) [list ::tk::dialog::file::EntFocusIn $w]
    ::tk::FocusGroup_BindOut $w $data(ent) [list ::tk::dialog::file::EntFocusOut $w]
}

# ::tk::dialog::file::SetSelectMode --
#
#	Set the select mode of the dialog to single select or multi-select.
#
# Arguments:
#	w		The dialog path.
#	multi		1 if the dialog is multi-select; 0 otherwise.
#
# Results:
#	None.

proc ::tk::dialog::file::SetSelectMode {w multi} {
    set dataName __tk_filedialog
    upvar ::tk::dialog::file::$dataName data
    if { $multi } {
	set fNameCaption "[mc {File &names:}]"
    } else {
	set fNameCaption "[mc {File &name:}]"
    }
    set iconListCommand [list ::tk::dialog::file::OkCmd $w]
    ::tk::SetAmpText $w.f0.f2.lab $fNameCaption 
    ::tk::IconList_Config $data(icons) \
	    [list -multiple $multi -command $iconListCommand]
    return
}

# ::tk::dialog::file::UpdateWhenIdle --
#
#	Creates an idle event handler which updates the dialog in idle
#	time. This is important because loading the directory may take a long
#	time and we don't want to load the same directory for multiple times
#	due to multiple concurrent events.
#
proc ::tk::dialog::file::UpdateWhenIdle {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    if {[info exists data(updateId)]} {
	return
    } else {
	set data(updateId) [after idle [list ::tk::dialog::file::Update $w]]
    }
}

# ::tk::dialog::file::Update --
#
#	Loads the files and directories into the IconList widget. Also
#	sets up the directory option menu for quick access to parent
#	directories.
#
proc ::tk::dialog::file::Update {w} {

    # This proc may be called within an idle handler. Make sure that the
    # window has not been destroyed before this proc is called
    if {![winfo exists $w]} {
	return
    }
    set class [winfo class $w]
    if {($class ne "TkFDialog") && ($class ne "TkChooseDir")} {
	return
    }

    set dataName [winfo name $w]
    upvar ::tk::dialog::file::$dataName data
    variable ::tk::Priv
    global tk_library
    catch {unset data(updateId)}

    if {![info exists Priv(folderImage)]} {
	set Priv(folderImage) [image create photo -data {
R0lGODlhEAAMAKEAAAD//wAAAPD/gAAAACH5BAEAAAAALAAAAAAQAAwAAAIghINhyycvVFsB
QtmS3rjaH1Hg141WaT5ouprt2HHcUgAAOw==}]
	set Priv(fileImage)   [image create photo -data {
R0lGODlhDAAMAKEAALLA3AAAAP//8wAAACH5BAEAAAAALAAAAAAMAAwAAAIgRI4Ha+IfWHsO
rSASvJTGhnhcV3EJlo3kh53ltF5nAhQAOw==}]
    }
    #set folder $Priv(folderImage)
    #set file   $Priv(fileImage)
    set folder "mime_folder_22"
    set file "mime_file_22"

    set appPWD [pwd]
    if {[catch {
	cd $data(selectPath)
    }]} {
	# We cannot change directory to $data(selectPath). $data(selectPath)
	# should have been checked before ::tk::dialog::file::Update is called, so
	# we normally won't come to here. Anyways, give an error and abort
	# action.
	tk_messageBox -type ok -parent $w -icon warning -message \
	    [mc "Cannot change to the directory \"%1\$s\".\nPermission denied." $data(selectPath)]
	cd $appPWD
	return
    }

    # Turn on the busy cursor. BUG?? We haven't disabled X events, though,
    # so the user may still click and cause havoc ...
    #
    set entCursor [$data(ent) cget -cursor]
    set dlgCursor [$w         cget -cursor]
    $data(ent) config -cursor watch
    $w         config -cursor watch
    update idletasks

    ::tk::IconList_DeleteAll $data(icons)

    set showHidden $::tk::dialog::file::showHiddenVar

    # Make the dir list
    # Using -directory [pwd] is better in some VFS cases.
    set cmd [list glob -tails -directory [pwd] -type d -nocomplain *]
    if {$showHidden} { lappend cmd .* }
    set dirs [lsort -dictionary -unique [eval $cmd]]
    set dirList {}
    foreach d $dirs {
	if {$d eq "." || $d eq ".."} {
	    continue
	}
	lappend dirList $d
    }
    ::tk::IconList_Add $data(icons) $folder $dirList

    if {$class eq "TkFDialog"} {
	# Make the file list if this is a File Dialog, selecting all
	# but 'd'irectory type files.
	#
	set cmd [list glob -tails -directory [pwd] \
		     -type {f b c l p s} -nocomplain]
	if {[string equal $data(filter) *]} {
	    lappend cmd *
	    if {$showHidden} { lappend cmd .* }
	} else {
	    eval [list lappend cmd] $data(filter)
	}
	set fileList [lsort -dictionary -unique [eval $cmd]]
	::tk::IconList_Add $data(icons) $file $fileList
    }

    ::tk::IconList_Arrange $data(icons)

    # Update the Directory: option menu
    #
    set list ""
    set dir ""
    foreach subdir [file split $data(selectPath)] {
	set dir [file join $dir $subdir]
	lappend list $dir
    }

 #   $data(dirMenu) delete 0 end
    set var [format %s(selectPath) ::tk::dialog::file::$dataName]
    $data(dirMenuBtn) config -values $list
#    foreach path $list {
#	$data(dirMenu) add command -label $path -command [list set $var $path]
#    }

    # Restore the PWD to the application's PWD
    #
    cd $appPWD

    if { [string equal $class TkFDialog] } {
	# Restore the Open/Save Button if this is a File Dialog
	#
	if {[string equal $data(type) open]} {
	    ::tk::SetAmpText $data(okBtn) [mc "&Open"]
	} else {
	    ::tk::SetAmpText $data(okBtn) [mc "&Save"]
	}
    }

    # turn off the busy cursor.
    #
    $data(ent) config -cursor $entCursor
    $w         config -cursor $dlgCursor
}

# ::tk::dialog::file::SetPathSilently --
#
# 	Sets data(selectPath) without invoking the trace procedure
#
proc ::tk::dialog::file::SetPathSilently {w path} {
    upvar ::tk::dialog::file::[winfo name $w] data
    
    trace vdelete  data(selectPath) w [list ::tk::dialog::file::SetPath $w]
    set data(selectPath) $path
    trace variable data(selectPath) w [list ::tk::dialog::file::SetPath $w]
}


# This proc gets called whenever data(selectPath) is set
#
proc ::tk::dialog::file::SetPath {w name1 name2 op} {
    if {[winfo exists $w]} {
	upvar ::tk::dialog::file::[winfo name $w] data
	::tk::dialog::file::UpdateWhenIdle $w
	# On directory dialogs, we keep the entry in sync with the currentdir.
	if { [string equal [winfo class $w] TkChooseDir] } {
	    $data(ent) delete 0 end
	    $data(ent) insert end $data(selectPath)
	}
    }
}

# This proc gets called whenever data(filter) is set
#
proc ::tk::dialog::file::SetFilter {w type} {
    upvar ::tk::dialog::file::[winfo name $w] data
    upvar ::tk::$data(icons) icons

    set data(filter) [lindex $type 1]
    $data(typeMenuBtn) config -text [lindex $type 0] 
# -indicatoron 1

    # If we aren't using a default extension, use the one suppled
    # by the filter.
    if {![info exists data(extUsed)]} {
	if {[string length $data(-defaultextension)]} {
	    set data(extUsed) 1
	} else {
	    set data(extUsed) 0
	}
    }

    if {!$data(extUsed)} {
	# Get the first extension in the list that matches {^\*\.\w+$}
	# and remove all * from the filter.
	set index [lsearch -regexp $data(filter) {^\*\.\w+$}]
	if {$index >= 0} {
	    set data(-defaultextension) \
		    [string trimleft [lindex $data(filter) $index] "*"]
	} else {
	    # Couldn't find anything!  Reset to a safe default...
	    set data(-defaultextension) ""
	}
    }

    $icons(sbar) set 0.0 0.0
    
    ::tk::dialog::file::UpdateWhenIdle $w
}

# tk::dialog::file::ResolveFile --
#
#	Interpret the user's text input in a file selection dialog.
#	Performs:
#
#	(1) ~ substitution
#	(2) resolve all instances of . and ..
#	(3) check for non-existent files/directories
#	(4) check for chdir permissions
#	(5) conversion of environment variable references to their
#	    contents (once only)
#
# Arguments:
#	context:  the current directory you are in
#	text:	  the text entered by the user
#	defaultext: the default extension to add to files with no extension
#	expandEnv: whether to expand environment variables (yes by default)
#
# Return vaue:
#	[list $flag $directory $file]
#
#	 flag = OK	: valid input
#	      = PATTERN	: valid directory/pattern
#	      = PATH	: the directory does not exist
#	      = FILE	: the directory exists by the file doesn't
#			  exist
#	      = CHDIR	: Cannot change to the directory
#	      = ERROR	: Invalid entry
#
#	 directory      : valid only if flag = OK or PATTERN or FILE
#	 file           : valid only if flag = OK or PATTERN
#
#	directory may not be the same as context, because text may contain
#	a subdirectory name
#
proc ::tk::dialog::file::ResolveFile {context text defaultext {expandEnv 1}} {
    set appPWD [pwd]

    set path [::tk::dialog::file::JoinFile $context $text]

    # If the file has no extension, append the default.  Be careful not
    # to do this for directories, otherwise typing a dirname in the box
    # will give back "dirname.extension" instead of trying to change dir.
    if {
	![file isdirectory $path] && ([file ext $path] eq "") &&
	![string match {$*} [file tail $path]]
    } then {
	set path "$path$defaultext"
    }

    if {[catch {file exists $path}]} {
	# This "if" block can be safely removed if the following code
	# stop generating errors.
	#
	#	file exists ~nonsuchuser
	#
	return [list ERROR $path ""]
    }

    if {[file exists $path]} {
	if {[file isdirectory $path]} {
	    if {[catch {cd $path}]} {
		return [list CHDIR $path ""]
	    }
	    set directory [pwd]
	    set file ""
	    set flag OK
	    cd $appPWD
	} else {
	    if {[catch {cd [file dirname $path]}]} {
		return [list CHDIR [file dirname $path] ""]
	    }
	    set directory [pwd]
	    set file [file tail $path]
	    set flag OK
	    cd $appPWD
	}
    } else {
	set dirname [file dirname $path]
	if {[file exists $dirname]} {
	    if {[catch {cd $dirname}]} {
		return [list CHDIR $dirname ""]
	    }
	    set directory [pwd]
	    cd $appPWD
	    set file [file tail $path]
	    # It's nothing else, so check to see if it is an env-reference
	    if {$expandEnv && [string match {$*} $file]} {
		set var [string range $file 1 end]
		if {[info exist ::env($var)]} {
		    return [ResolveFile $context $::env($var) $defaultext 0]
		}
	    }
	    if {[regexp {[*?]} $file]} {
		set flag PATTERN
	    } else {
		set flag FILE
	    }
	} else {
	    set directory $dirname
	    set file [file tail $path]
	    set flag PATH
	    # It's nothing else, so check to see if it is an env-reference
	    if {$expandEnv && [string match {$*} $file]} {
		set var [string range $file 1 end]
		if {[info exist ::env($var)]} {
		    return [ResolveFile $context $::env($var) $defaultext 0]
		}
	    }
	}
    }

    return [list $flag $directory $file]
}


# Gets called when the entry box gets keyboard focus. We clear the selection
# from the icon list . This way the user can be certain that the input in the 
# entry box is the selection.
#
proc ::tk::dialog::file::EntFocusIn {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    if {[string compare [$data(ent) get] ""]} {
	$data(ent) selection range 0 end
	$data(ent) icursor end
    } else {
	$data(ent) selection clear
    }

    if { [string equal [winfo class $w] TkFDialog] } {
	# If this is a File Dialog, make sure the buttons are labeled right.
	if {[string equal $data(type) open]} {
	    ::tk::SetAmpText $data(okBtn) [mc "&Open"]
	} else {
	    ::tk::SetAmpText $data(okBtn) [mc "&Save"]
	}
    }
}

proc ::tk::dialog::file::EntFocusOut {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    $data(ent) selection clear
}


# Gets called when user presses Return in the "File name" entry.
#
proc ::tk::dialog::file::ActivateEnt {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    set text [$data(ent) get]
    if {$data(-multiple)} {
	# For the multiple case we have to be careful to get the file
	# names as a true list, watching out for a single file with a
	# space in the name.  Thus we query the IconList directly.

	set selIcos [::tk::IconList_Curselection $data(icons)]
	set data(selectFile) ""
	if {[llength $selIcos] == 0 && $text ne ""} {
	    # This assumes the user typed something in without selecting
	    # files - so assume they only type in a single filename.
	    ::tk::dialog::file::VerifyFileName $w $text
	} else {
	    foreach item $selIcos {
		::tk::dialog::file::VerifyFileName $w \
		    [::tk::IconList_Get $data(icons) $item]
	    }
	}
    } else {
	::tk::dialog::file::VerifyFileName $w $text
    }
}

# Verification procedure
#
proc ::tk::dialog::file::VerifyFileName {w filename} {
    upvar ::tk::dialog::file::[winfo name $w] data

    set list [::tk::dialog::file::ResolveFile $data(selectPath) $filename \
	    $data(-defaultextension)]
    foreach {flag path file} $list {
	break
    }

    switch -- $flag {
	OK {
	    if {[string equal $file ""]} {
		# user has entered an existing (sub)directory
		set data(selectPath) $path
		$data(ent) delete 0 end
	    } else {
		::tk::dialog::file::SetPathSilently $w $path
		if {$data(-multiple)} {
		    lappend data(selectFile) $file
		} else {
		    set data(selectFile) $file
		}
		::tk::dialog::file::Done $w
	    }
	}
	PATTERN {
	    set data(selectPath) $path
	    set data(filter) $file
	}
	FILE {
	    if {[string equal $data(type) open]} {
		tk_messageBox -icon warning -type ok -parent $w \
		    -message "[mc "File \"%1\$s\"  does not exist." [file join $path $file]]"
		$data(ent) selection range 0 end
		$data(ent) icursor end
	    } else {
		::tk::dialog::file::SetPathSilently $w $path
		if {$data(-multiple)} {
		    lappend data(selectFile) $file
		} else {
		    set data(selectFile) $file
		}
		::tk::dialog::file::Done $w
	    }
	}
	PATH {
	    tk_messageBox -icon warning -type ok -parent $w \
		-message "[mc "Directory \"%1\$s\" does not exist." $path]"
	    $data(ent) selection range 0 end
	    $data(ent) icursor end
	}
	CHDIR {
	    tk_messageBox -type ok -parent $w -message \
	       "[mc "Cannot change to the directory \"%1\$s\".\nPermission denied." $path]"\
		-icon warning
	    $data(ent) selection range 0 end
	    $data(ent) icursor end
	}
	ERROR {
	    tk_messageBox -type ok -parent $w -message \
	       "[mc "Invalid file name \"%1\$s\"." $path]"\
		-icon warning
	    $data(ent) selection range 0 end
	    $data(ent) icursor end
	}
    }
}

# Gets called when user presses the Alt-s or Alt-o keys.
#
proc ::tk::dialog::file::InvokeBtn {w key} {
    upvar ::tk::dialog::file::[winfo name $w] data

    if {[string equal [$data(okBtn) cget -text] $key]} {
	::tk::ButtonInvoke $data(okBtn)
    }
}

# Gets called when user presses the "parent directory" button
#
proc ::tk::dialog::file::UpDirCmd {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    if {[string compare $data(selectPath) "/"]} {
	set data(selectPath) [file dirname $data(selectPath)]
    }
}

# Join a file name to a path name. The "file join" command will break
# if the filename begins with ~
#
proc ::tk::dialog::file::JoinFile {path file} {
    if {[string match {~*} $file] && [file exists $path/$file]} {
	return [file join $path ./$file]
    } else {
	return [file join $path $file]
    }
}

# Gets called when user presses the "OK" button
#
proc ::tk::dialog::file::OkCmd {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    set filenames {}
    foreach item [::tk::IconList_Curselection $data(icons)] {
	lappend filenames [::tk::IconList_Get $data(icons) $item]
    }

    if {([llength $filenames] && !$data(-multiple)) || \
	    ($data(-multiple) && ([llength $filenames] == 1))} {
	set filename [lindex $filenames 0]
	set file [::tk::dialog::file::JoinFile $data(selectPath) $filename]
	if {[file isdirectory $file]} {
	    ::tk::dialog::file::ListInvoke $w [list $filename]
	    return
	}
    }

    ::tk::dialog::file::ActivateEnt $w
}

# Gets called when user presses the "Cancel" button
#
proc ::tk::dialog::file::CancelCmd {w} {
    upvar ::tk::dialog::file::[winfo name $w] data
    variable ::tk::Priv

    bind $data(okBtn) <Destroy> {}
    set Priv(selectFilePath) ""
}

# Gets called when user destroys the dialog directly [Bug 987169]
#
proc ::tk::dialog::file::Destroyed {w} {
    upvar ::tk::dialog::file::[winfo name $w] data
    variable ::tk::Priv

    set Priv(selectFilePath) ""
}

# Gets called when user browses the IconList widget (dragging mouse, arrow
# keys, etc)
#
proc ::tk::dialog::file::ListBrowse {w} {
    upvar ::tk::dialog::file::[winfo name $w] data

    set text {}
    foreach item [::tk::IconList_Curselection $data(icons)] {
	lappend text [::tk::IconList_Get $data(icons) $item]
    }
    if {[llength $text] == 0} {
	return
    }
    if { [llength $text] > 1 } {
	set newtext {}
	foreach file $text {
	    set fullfile [::tk::dialog::file::JoinFile $data(selectPath) $file]
	    if { ![file isdirectory $fullfile] } {
		lappend newtext $file
	    }
	}
	set text $newtext
	set isDir 0
    } else {
	set text [lindex $text 0]
	set file [::tk::dialog::file::JoinFile $data(selectPath) $text]
	set isDir [file isdirectory $file]
    }
    if {!$isDir} {
	$data(ent) delete 0 end
	$data(ent) insert 0 $text

	if { [string equal [winfo class $w] TkFDialog] } {
	    if {[string equal $data(type) open]} {
		::tk::SetAmpText $data(okBtn) [mc "&Open"]
	    } else {
		::tk::SetAmpText $data(okBtn) [mc "&Save"]
	    }
	}
    } else {
	if { [string equal [winfo class $w] TkFDialog] } {
	    ::tk::SetAmpText $data(okBtn) [mc "&Open"]
	}
    }
}

# Gets called when user invokes the IconList widget (double-click, 
# Return key, etc)
#
proc ::tk::dialog::file::ListInvoke {w filenames} {
    upvar ::tk::dialog::file::[winfo name $w] data

    if {[llength $filenames] == 0} {
	return
    }

    set file [::tk::dialog::file::JoinFile $data(selectPath) \
	    [lindex $filenames 0]]
    
    set class [winfo class $w]
    if {[string equal $class TkChooseDir] || [file isdirectory $file]} {
	set appPWD [pwd]
	if {[catch {cd $file}]} {
	    tk_messageBox -type ok -parent $w -message \
	       "[mc "Cannot change to the directory \"%1\$s\".\nPermission denied." $file]"\
		-icon warning
	} else {
	    cd $appPWD
	    set data(selectPath) $file
	}
    } else {
	if {$data(-multiple)} {
	    set data(selectFile) $filenames
	} else {
	    set data(selectFile) $file
	}
	::tk::dialog::file::Done $w
    }
}

# ::tk::dialog::file::Done --
#
#	Gets called when user has input a valid filename.  Pops up a
#	dialog box to confirm selection when necessary. Sets the
#	tk::Priv(selectFilePath) variable, which will break the "vwait"
#	loop in ::tk::dialog::file:: and return the selected filename to the
#	script that calls tk_getOpenFile or tk_getSaveFile
#
proc ::tk::dialog::file::Done {w {selectFilePath ""}} {
    upvar ::tk::dialog::file::[winfo name $w] data
    variable ::tk::Priv

    if {[string equal $selectFilePath ""]} {
	if {$data(-multiple)} {
	    set selectFilePath {}
	    foreach f $data(selectFile) {
		lappend selectFilePath [::tk::dialog::file::JoinFile \
		    $data(selectPath) $f]
	    }
	} else {
	    set selectFilePath [::tk::dialog::file::JoinFile \
		    $data(selectPath) $data(selectFile)]
	}
	
	set Priv(selectFile)     $data(selectFile)
	set Priv(selectPath)     $data(selectPath)

	if {[string equal $data(type) save]} {
	    if {[file exists $selectFilePath]} {
	    set reply [tk_messageBox -icon warning -type yesno\
		    -parent $w -message \
			"[mc "File \"%1\$s\" already exists.\nDo you want to overwrite it?" $selectFilePath]"]
	    if {[string equal $reply "no"]} {
		return
		}
	    }
	}
    }
    bind $data(okBtn) <Destroy> {}
    set Priv(selectFilePath) $selectFilePath
}