#!/bin/sh

########################################################################
## cat-bdf-fonts.sh:  a script to concatenate the contents of the given
##                    BDF font into one BDF font.
## created   1998-10-10 00:28 Jim Knoble <jmknoble@pobox.com>
## autodate: 1999-Aug-17 00:46
########################################################################

if [ -n "${DEBUG}" ]; then
    set -x
fi

function PrintHelp() {
    cat <<EndOfHelp
    
  Usage: $0 [-o <outfile> [-b]] [-p <font>] \\
         [-a <add-style>] [-r <registry>] [-e <encoding>] \\
         <font> [<font> ...]

  Concatenate the given BDF-format fonts to standard output.
  
  Options:
  
    -o <outfile>    Concatenate to <outfile> instead of stdout.
    
    -b              Make a backup of <outfile> in <outfile>~.
    
    -p <font>       Include the preamble of <font> as the preamble for
                    the output font.  If not specified, use the preamble
                    from the first font given on the command line.

    -n <name>       Set the value of the FAMILY_NAME field in the
                    output font to <name>.

    -a <add-style>  Set the value of the ADD_STYLE_NAME field in the
                    output font to <add-style>.

    -r <registry>   Set the value of the CHARSET_REGISTRY field in the
                    output font to <registry>.

    -e <encoding>   Set the value of the CHARSET_ENCODING field in the
                    output font to <encoding>.

EndOfHelp
}

########################################################################
## Some useful variables and functions
SuffixBackup="~"
SuffixBdf=".bdf"
OutputFile="font${SuffixBdf}"
PreambleFont=""
MakeBackup=0

CharPattern="^(STARTCHAR|ENCODING|SWIDTH|DWIDTH|BBX|BITMAP|ENDCHAR|[0-9A-F][0-9A-F]*$)"
EndPattern="ENDFONT"

GetBdfPreamble() {
    egrep -v "${CharPattern}" | grep -v "${EndPattern}"
}
GetBdfChars() {
    egrep "${CharPattern}"
}
## Assign a value to a font property
## syntax:  cat <bdffile> | FontProp <num-preceding> <name> <value>
## For example:  cat blah.bdf | FontProp 12 CHARSET_REGISTRY ISO8859
FontProp() {
    local n=$1
    local name=$2
    local val="$3"
    sed -e 's/^FONT[[:space:]][[:space:]]*\(\(-[^-]*\)\{'"${n}"'\}\)-[^-]*\(.*\)$/FONT \1-'"${val}"'\3/' \
        -e 's/^'"${name}"'[[:space:]][[:space:]]*".*".*$/'"${name}"' "'"${val}"'"/'
}
MakeFamilyName() {
    FontProp 1 FAMILY_NAME "$1"
}
MakeAddStyle() {
    FontProp 5 ADD_STYLE_NAME "$1"
}
MakeRegistry() {
    FontProp 12 CHARSET_REGISTRY "$1"
}
MakeEncoding() {
    FontProp 13 CHARSET_ENCODING "$1"
}

########################################################################
## Process command-line options
while [ -n "$*" ]; do
    case "$1" in
        -h|--help)
            PrintHelp
            exit 1
            ;;
        -b|--backup)
            shift
	    MakeBackup=1
	    ;;
        -o|--output)
            shift
	    OutputFile="$1"
	    shift
	    ;;
        -p|--preamble)
	    shift
	    PreambleFont="$1"
	    shift
	    ;;
        -a|--add-style)
	    shift
	    AddStyle="$1"
	    shift
	    ;;
        -n|--name)
	    shift
	    Name="$1"
	    shift
	    ;;
        -r|--registry)
	    shift
	    CharsetRegistry="$1"
	    shift
	    ;;
        -e|--encoding)
	    shift
	    CharsetEncoding="$1"
	    shift
	    ;;
        *)
	    break
	    ;;
    esac
done

if [ -z "$*" ]; then
    echo "`basename $0`: No BDF fonts specified."
    exit 1
fi

if [ -z "${PreambleFont}" ]; then
    PreambleFont="$1"
fi
BackupFile="${OutputFile}${SuffixBackup}"

########################################################################
## Create the preamble
PropFilters=""
if [ -n "${Name}" ]; then
    PropFilters="${PropFilters} | MakeFamilyName '${Name}'"
fi
if [ -n "${AddStyle}" ]; then
    PropFilters="${PropFilters} | MakeAddStyle '${AddStyle}'"
fi
if [ -n "${CharsetRegistry}" ]; then
    PropFilters="${PropFilters} | MakeRegistry '${CharsetRegistry}'"
fi
if [ -n "${CharsetEncoding}" ]; then
    PropFilters="${PropFilters} | MakeEncoding '${CharsetEncoding}'"
fi

TmpFile="`mktemp tmpfont.XXXXXX`" || exit 1
eval "cat '${PreambleFont}' | GetBdfPreamble ${PropFilters} >'${TmpFile}'"

## Now add the characters from the fonts in order
for FontName in "$@"; do
    cat "${FontName}" | GetBdfChars >>"${TmpFile}"
done
echo ENDFONT >>"${TmpFile}"

## Finally, figure out how many characters are in the font
NumChars=`echo -n \`cat "${TmpFile}" | grep '^ENCODING' | wc -l\``

if [ ${MakeBackup} -gt 0 -a -e "${OutputFile}" ]; then
    cp -pf "${OutputFile}" "${BackupFile}"
fi

cat "${TmpFile}" | \
    sed -e 's/^CHARS[[:space:]][[:space:]]*.*$/CHARS '"${NumChars}"'/' \
    >${OutputFile}
rm -f "${TmpFile}"

## -------- End of file --------
