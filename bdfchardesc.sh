#!/bin/sh
#
# bdfchardesc.sh: write character descriptions to bdf fonts
# created 1999-01-02 03:50 jmk
# autodate: 1999-01-12 01:11

if [ -n "${DEBUG}" ]; then
    set -x
fi

VERBOSE=1

CAT="cat"
AWK="awk"
GREP="grep"
MV="mv -f"
RM="rm -f"
SED="sed"
SORT="sort"
TR="tr"

DEFAULT_ENCODING="iso8859-1"

BLANK_PATTERN='^[[:space:]]*$'
COMMENT_PATTERN='^[[:space:]]*#'
DESC_FIELD_SEPARATOR='[[:space:]]*=[[:space:]]*'
OUTFILE_SUFFIX=".new"

########################################################################
function SayLvl() {
    local lvl="$1"
    shift
    if [ ${VERBOSE} -gt ${lvl} ]; then
        echo "$@"
    fi
}
function Say() {
    SayLvl 0 "$@"
}
function Say1() {
    SayLvl 1 "$@"
}
function Do() {
    Say1 '#' "$@"
    "$@"
}

########################################################################
function Backup() {
    for i in "$@"; do
        if [ -e "${i}" ]; then
            ${RM} "${i}~"
            ${MV} "${i}" "${i}~"
        fi
    done
}

########################################################################
function ToLower() {
    local s="$1"
    
    echo "${s}" | ${TR} [:upper:] [:lower:]
}
function ToUpper() {
    local s="$1"
    
    echo "${s}" | ${TR} [:lower:] [:upper:]
}

########################################################################
function CatDescTable() {
    local tbl="$1"
    
    ${CAT} "${tbl}" | \
    ${GREP} -v "${BLANK_PATTERN}" | \
    ${GREP} -v "${COMMENT_PATTERN}" | \
    ${SORT}
}
function DescriptionForChar() {
    local tbl="$1"
    local charcode="$2"
    
    CatDescTable "${tbl}" | \
    ${GREP} "^${charcode}\>" | \
    ${AWK} -F "${DESC_FIELD_SEPARATOR}" '{ print $2 }'
}

########################################################################
function DescribeFont() {
    local tbl="$1"
    local infile="$2"
    local outfile="$3"
    local line
    local keyword
    local value
    local extra
    local chardesc
    
    ${CAT} "${infile}" | \
    (
        while read line; do
            case "${line}" in
                STARTCHAR*)
                    if read keyword value extra; then
                        if [ "${keyword}" != "ENCODING" ]; then
                            echo -n "${inputfile}: bad input: " >&2
			    echo -n "expected 'ENCODING', got '${keyword}'" >&2
			    echo >&2
                            break
			fi
			Say -n " ${value}" >&5
			chardesc="`DescriptionForChar \"${tbl}\" \"${value}\"`"
			echo "STARTCHAR ${chardesc}"
			echo -n "${keyword} ${value}"
			if [ -n "${extra}" ]; then
			    echo -n " ${extra}"
			fi
			echo
                    fi
                    ;;
                *)
		    echo "${line}"
                    ;;
            esac
        done
    ) \
    >"${outfile}"
}
function DoFontDescriptions() {
    local tbl="$1"
    local outfilesuffix="$2"
    shift
    shift
    local infile
    local outfile
    local numfonts=0
    
    Say "Adding character descriptions ..."
    for i in "$@"; do
        Say -n "Processing ${i} ..."
        infile="${i}"
	outfile="${i}${outfilesuffix}"
	numfonts=$[${numfonts} + 1]
	Backup "${outfile}"
	DescribeFont "${tbl}" "${infile}" "${outfile}" 5>&1
	Say
    done
    Say "${numfonts} fonts."
}

########################################################################
ENCODING=""
DESC_TABLE=""

while [ -n "$*" ]; do
    case "$1" in
        -e|--encoding)
	    shift
	    ENCODING="$1"
	    ;;
        -t|--table)
	    shift
	    DESC_TABLE="$1"
	    ;;
        -q|--quiet)
            VERBOSE=0
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        -*)
            echo "$0: Unknown option '$1'"
            exit 1
            ;;
        *)
	    break
	    ;;
    esac
    shift
done

if [ $# -eq 0 ]; then
    echo "$0: Please specify a BDF font to add character descriptions to."
    exit 1
fi

if [ -z "${ENCODING}" ]; then
    ENCODING="${DEFAULT_ENCODING}"
fi
if [ -z "${DESC_TABLE}" ]; then
    DESC_TABLE="descriptions.${ENCODING}.tbl"
fi
if [ ! -f "${DESC_TABLE}" ]; then
    echo "$0: Cannot find character description table '${DESC_TABLE}'"
    exit 1
fi

DoFontDescriptions "${DESC_TABLE}" "${OUTFILE_SUFFIX}" "$@"

exit $?
