#!/bin/bash

#Version 1.4 - Added traps
#Date 6/5/14
#Tim Snow

# Exit if no arguments are given
if [[ -z "$1" ]] ;then
        error syntax ;exit 1
fi

cleanup() 
{
	# remove tmp
	# logger
	# exit
}
trap cleanup SIGKILL SIGINT EXIT

setvars() 
{
	SAVEIFS=$IFS
	IFS=${IFS/ /} 
	TABLE=/root/bin/filetable.txt
	LOG=/root/bin/fileinspector.log
	TEMPFILE=$(mktemp /root/bin/fi.XXXXXXXXX)
	RENAMEDIRS=f
	VERBOSE=f
	DEL=#@#
}

revertIFS() { IFS=$SAVEIFS ;}

message() { echo "$1 ---> $2" ;}

error() 
{ 
	case "$1" in
		notype) echo "No extension is provided for file/type: ${2}  ${3}"  >&2 ;;
		invalid) echo "Invalid file/directory: $2" >&2 ;;
		movefail) echo "Failed to move file: $2" >&2 ;;
		syntax) echo "Usage: `basename $0` [OPTION]... [FILE/DIRECTORY]..." >&2 ;;
	esac
}

addext ()
{
	if [[ -d "$1" ]] ;then
		FILES=$(find "$1")
		for FILE in $FILES
		do
			if [[ -f $FILE ]] ;then
				rename "$1"
			elif [[ -d $FILE ]] ;then
				:
			else
				error invalid "$1"
			fi
		done
	elif [[ -f "$1" ]] ;then
		rename "$1"
	else
		error invalid "$1"
	fi
}

# takes a file or directory and searches filetable to add correct extensions
addextDIRS () 
{
	if [[ -f "$1" ]] ;then
		rename "$1"
	elif [[ -d "$1" ]] ;then
		cd "$1"
		FILES=$(ls)
		for FILE in $FILES
		do	addextDIRS "$FILE"	;done
		cd ..
		rename "$1"
	else
		error invalid "$1"
	fi
}

# rename file based on type
rename ()
{
	if [[ "$1" -eq "" ]] ;then 
		return 
	fi
	TYPE=$(file -b --mime-type "$1")
	EXT="${EXTENSIONS[$TYPE]}"
    	#EXT=$(grep $TYPE "$TABLE" | awk -F${DEL} '{print $2}')
          	if ! [[ -z $EXT ]] ;then
                        RENAME="${1%%.*}.${EXT}"
                        mv "$1" "$RENAME" 2> /dev/null
			if [[ $? -eq 0 ]] ;then
				echo "Renamed file/directory: ${1}--->${RENAME}  ${TYPE}" >> "$LOG"
				if [[ $VERBOSE = t ]] ;then
					message "$1" "$RENAME"
				fi
			fi
		else
			error notype "$1" $TYPE
		fi
}

setvars
# Handle options
while getopts :df:l:rv OPT
do
	case $OPT in
		d) set -x ;;
		f) TABLE="${PWD}/${OPTARG}" ;;
		l) LOG="${PWD}/${OPTARG}" ;;
		r) RENAMEDIRS=t ;;
		v) VERBOSE=t ;;
		*) trap - EXIT ;exit 1 ;;
	esac
done
shift $(($OPTIND -1))

# Create associative array matching filetypes to extensions
declare -A EXTENSIONS
while read -r LINE
do
	if [[ $LINE =~ ${DEL} ]] ;then
		EXTENSIONS[${LINE%%\#*}]=${LINE##*\#}
	fi
done < "$TABLE"

echo "`basename $0` run at: $(date)" >> "$LOG"
# main loop; run faster code if not renaming directories
if [[ RENAMEDIRS = t ]] ;then 
	for ARG in "$@"
	do 	addextDIRS "${ARG%/}"	;done
else
	for ARG in "$@"
	do	addext "${ARG}"		;done	
fi

revertIFS
