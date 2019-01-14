#!/bin/bash

CWD="`pwd`"

declare -A CPMAP
declare -a LQUEUE

function append_file() {
	local FROMDIR="${1}"
	local FROMFILE="${2}"

	local F="${FROMDIR}/${FROMFILE}"
	local AF="`realpath ${F}`"

	if [ ${CPMAP["${AF}"]+_} ]; then
		echo ">>>	Skip	${AF}"
		return
	fi

	local T="`file --mime-type ${F} | sed 's/:/\t/g' | cut -f 2 | sed 's/\//\t/g' | cut -f 1 | sed 's/^ *//;s/ *$//'`"

	CPMAP["${AF}"]="${TOFILE}"

	echo ">>>	Append	${AF}"
}

function recurse_copy() {
	local -a SQUEUE

	local WD="${1}"
	local AF="`realpath ${WD}`"
	local TOCFILE="${2}"

	echo ">>>	Scan	${AF}	${TOCFILE}"

	#cat "${AF}/${TOCFILE}" | grep "\[*\]" | grep -v "(http" | sed 's/- //' | sed 's/\[//' | sed 's/\](/|/' | sed 's/)/|/' | while read -r l
	local SFILES=( `cat "${AF}/${TOCFILE}" | grep "\[*\]" | grep -v "(http" | sed 's/- //' | sed 's/\[//' | sed 's/\](/|/' | sed 's/)/|/'` )
	echo ">>>	SFILES ${SFILES[@]}"
	return

	for l in ${SFILES[@]}
	do
		IFS='|'
		local LN=(${l})
		unset IFS
		local F="${LN[1]}"
		local TITLE=${LN[0]}

		echo ">>>	LN	${LN[@]}"

		if [ ! -e "${AF}/${F}" ]; then
			echo ">>>	Missing	${AF}/${F}" 
			continue
		fi

		if [ -d "${AF}/${F}" ]; then
			SQUEUE+=("${F}")
		else
			local B="`basename ${F}`"
			local D="`dirname ${F}`"
			if [ "${AF}" = "`realpath ${D}`" ]; then
				append_file "${AF}/${D}" "${B}"
			else
				SQUEUE+=("${F}")
			fi
		fi
	done

	echo ">>>	SQUEUE	${SQUEUE[@]}"
	for i in "${!SQUEUE[@]}"
	do
		local F="${SQUEUE[$i]}"
		local B="`basename ${F}`"
		local D="`dirname ${F}`"
		if [ "${AF}" = "`realpath ${D}`" ]; then
			local SF=( `\ls ${AF}/${F}/*.md 2> /dev/null` )
			if [ ${#SF[@]} -gt 0 ] && [ -e "${AF}/${F}/README.md" ]; then
				recurse_copy "${AF}/${F}" "README.md"
			fi
		else
			LQUEUE+=("${AF}/${F}")
		fi
	done
	echo ">>>	LQUEUE	${LQUEUE[@]}"
}

recurse_copy "install" "README.md"
