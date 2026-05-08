#!/bin/bash
# Copyright 2026 - Onno VK6FLAB cq@vk6flab.com

# This script allows a user to enter text into a file named after the current
# date and optionally commit the result to git.

# The user can optionally configure an editor.

# You can install this by making a symbolic link to this script and the
# notes directory will stay where this actual script is, preventing your
# path from being polluted with notes.
local_notes_root="$(dirname "$(readlink -f "$0")")"

# We need both the date and time
now=$(date -u +'%F %T')

# Set the current note name to the current date.
fileName="${local_notes_root}/notes/${now% *}.md"

# Set the current text heading to a time-stamp and username.
headingText="# ${now#* } - $(whoami)"

function readUserNote() {
# Add text to the myText variable
	echo -e "Enter your note and finish with Ctrl-D on an empty line.\n"

	readarray -t myText
}

function saveUserNote() {
# Append the supplied text to the current note.
	(
		echo "${headingText}"
		echo
		printf '%s\n' "${myText[@]}"
		echo
		echo
	) >> "${fileName}"
}

function commitUserNote() {
# If git is enabled, then this will commit to the current repository.
	if [ -f "${local_notes_root}/.git_enabled" ]
	then
		(
			cd "${local_notes_root}/" || exit 1
			git add .
			git commit -m "${now} - $(whoami): ${myText[0]}"
			git push
		)
	fi
}

function showHelp() {
# Display user help.
	cat <<-EOH
		
		$0 [command] [notes]

		This script allows you to take notes and store them in date
		stamped files within a notes directory. The intent is for the
		notes to be inside a git repository that will be synchronised
		each time a note is saved.
		
		Commands:
		help, -h, --help	Show this information
		., add			Add a note to the current day's file
		git			Enable/Disable git commit and push
		edit			Enable/Disable editor
		u, update		Update the latest note in your preferred
					 editor.

	EOH
}

function toggleEdit() {
# Toggle editor by adding or removing '.editor_enabled' file.
	read -r -p "Enter full path to your preferred editor (leave empty to disable): " myEditor
	if [ -z "${myEditor}" ]
	then
		rm -f "${local_notes_root}/.editor_enabled"
		echo "Disabled: editor"
	else
		echo "${myEditor} \"\$@\"" > "${local_notes_root}/.editor_enabled"
		cat <<-EOM
		Editor set to: $(cat "${local_notes_root}/.editor_enabled")

		Run the command again to change or disable the editor.
		EOM
	fi
}

function toggleGit() {
# Toggle git update by adding or removing '.git_enabled' file.
	if [ -f "${local_notes_root}/.git_enabled" ]
	then
		rm -f "${local_notes_root}/.git_enabled"
		echo "Disabled: git commit and push."
	else
		touch "${local_notes_root}/.git_enabled"
		cat <<-EOM
		Enabled: automatic git commit and push.

		To disable, run '$0 git' command again.
		EOM
	fi
}

function updateNote() {
# If a user editor has been set, launch it with the current note.
	if [ -f "${local_notes_root}/.editor_enabled" ]
	then
		bash "${local_notes_root}/.editor_enabled" "${fileName}"
	else
		echo "Editor disabled."
	fi
}

if [ "$#" -gt 1 ]
then
# The command line contains the text
	myText=("$*")
elif [ "$#" -eq 0 ]
then
# Ask the user for the text
	readUserNote
fi

if [ "${myText}" ]
then
# If there is text, save and commit
	saveUserNote
	commitUserNote
	exit 0
fi

case "$1" in
# If exactly one parameter is supplied, then process it.
	"help" | "-h" | "--help")
		showHelp
		;;
	"." | "add")
		readUserNote
		;;
	"git")
		toggleGit
		;;
	"edit")
		toggleEdit
		;;
	"u" | "update")
		updateNote
		;;
esac
