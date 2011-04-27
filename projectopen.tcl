#!/usr/bin/env tclsh

###########################################################################################
#
# Configuration
#

set ignore_regex {^(?!(.*\.(git.*|hg.*|svn.*|exe|dll|obj|o|so|a|lib|png|jpg|gif|8)$))}
set project_files {.git Gemfile .hg}

###########################################################################################
#
# Supporting methods
#

proc find_project {base_dir} {
	set dir [file normalize $base_dir]
	set paths [file split $dir]
	
	while {[llength $paths] > 1} {
		foreach project_file $::project_files {
			if { [file exists $dir/$project_file] } {
				return $dir
			}
		}
		
		set paths [lrange $paths 0 end-1]
		set dir [file join {*}$paths]
	}
	
	return $base_dir
}

proc file_selected {} {
	puts -nonewline [file nativename [file normalize [lindex $::filtered [.files curselection]]]]
	exit
}

###########################################################################################
#
# Application code
#

# Change to the base directory
if { $argc > 0 } {
	# An active file was supplied on the command line, use it as the starting directory
	# to traverse back looking for the project file.
	
	cd [find_project [file dirname [lindex $argv 0]]]
} else {
	# No active file was supplied on the command line, use the CWD as the starting directory

	cd [find_project .]
}

package require Tk

wm title . "Open File"
wm minsize . 550 400

set ::files [lsearch -all -inline -regex [exec -- find -type f] $ignore_regex]
set ::filtered $::files
set ::filter {}
set ::selected_file {}
	
entry .filter -textvariable ::filter 
bind .filter <KeyRelease> {
	set filter_text *[join [split $::filter {}] *]*
	set ::filtered [lsearch -all -inline -glob $::files $filter_text]
	return 1
}
bind .filter <Down> {
	.files selection set 0
	focus .files
}

listbox .files -listvariable ::filtered
bind .files <Return> file_selected
bind .files <Double-Button-1> file_selected
pack .filter -side top -fill x
pack .files -side top -expand y -fill both

focus .filter

wm protocol . WM_DELETE_WINDOW { 
	# Window was simply closed, let Minimum Profit know that no file was selected
	puts -nonewline {<NONE>} 
	exit
}
