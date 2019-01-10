#!/bin/bash

## sudo apt install ruby-dev
## sudo gem install gimli

BUILDDIR="_build"
CWD="`pwd`"
FIDX=0

declare -A CPMAP

mkdir -p "${BUILDDIR}"
rm -rf "${BUILDDIR}/*"

function copy_file() {
	FROMDIR="${1}"
	FROMFILE="${2}"

	F="${FROMDIR}/${FROMFILE}"
	AF="`realpath ${F}`"

	if [ ${CPMAP["${AF}"]+_} ]; then
		echo "-- Skip copy ${F}"
		return
	fi

	T="`file --mime-type ${F} | sed 's/:/\t/g' | cut -f 2 | sed 's/\//\t/g' | cut -f 1 | sed 's/^ *//;s/ *$//'`"

	TODIR="${BUILDDIR}"
	if [ "text" != "${T}" ]; then
		TODIR="${BUILDDIR}/${FROMDIR}"
	fi
	
	if [ ! -e "${TODIR}" ]; then
		mkdir -p "${TODIR}"
	fi

	FPREFIX="`printf "%05d" ${FIDX}`"
	TOFILE="${TODIR}/${FPREFIX}_${FROMFILE}"

	CPMAP["${AF}"]="${TOFILE}"
	FIDX=$(( FIDX + 1 ))

	echo "Copy ${F} >> ${TOFILE}"
	cp "${F}" "${TOFILE}"
}

function recurse_copy() {
	WD="${1}"
	TOCFILE="${2}"

	echo ">>>>>>>>> ${WD}"

	pushd "${WD}" > /dev/null	
	copy_file "." "${TOCFILE}"

	cat "${TOCFILE}" | grep "\[*\]" | grep -v "(http" | sed 's/- //' | sed 's/\[//' | sed 's/\](/|/' | sed 's/)/|/' | while read -r l
	do
		IFS='|'
		LN=(${l})
		unset IFS
		F="${LN[1]}"
		TITLE=${LN[0]}

		if [ ! -e "${F}" ]; then
			echo ">> File ${F} is missing[${3}]"
			continue
		fi

		B="`basename ${F}`"
		D="`dirname ${F}`"
		if [ ! -d "${F}" ]; then
			copy_file "${D}" "${B}"
			continue
		fi

		SF=( `\ls ${F}/*.md 2> /dev/null` )
		if [ ${#SF[@]} -gt 0 ] && [ -e "${F}/README.md" ]; then
			recurse_copy "${F}" "README.md"
		fi

	done
	popd > /dev/null
}

recurse_copy "." "TOC.md"
