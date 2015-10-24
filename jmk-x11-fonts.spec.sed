# User-Defined Macros:
# %define <name> <expansion>
%define Name		@Name@
%define Version		@Version@
%define Release		1
%define FoundryDir	@FoundryDir@
%define Prefix		/usr
Summary: Character-cell fonts for X11
Name: %{Name}
Version: %{Version}
Release: %{Release}
#Serial: 
Packager: Jim Knoble <jmknoble@pobox.com>
Copyright: GPL
Group: X11/Fonts
URL: http://www.pobox.com/~jmknoble
Source0: http://www.pobox.com/~jmknoble/fonts/%{Name}-%{Version}.tar.gz
#Patch0: 
Prefix: %{Prefix}
BuildRoot: /tmp/%{Name}-%{Version}-%{Release}-root
#Provides: 
#Requires: 
#Obsoletes: 

%description
These are character-cell fonts for use with the X Window System,
created by Jim Knoble.  The current list of fonts included in this
package are:

  Neep (formerly known as NouveauGothic)

    A pleasantly legible variation on the standard fixed fonts that
    accompany most distributions of the X Window System.  Comes in both
    normal and bold weights in small, medium, large, extra-large, and
    huge sizes, as well as an extra-small size that only comes in
    normal weight.  Comes in the following encodings:

      ISO-8859-1  (Latin1, Western European + Icelandic)
      ISO-8859-2  (Latin2, Eastern European)
      ISO-8859-9  (Latin5, Western European + Turkish)
      ISO-8859-15 (Latin9, Western European + Euro Symbol)

  Modd

    A fixed-width font with sleek, contemporary styling.  Normal and
    bold weights in a 10-point (6x11) and a 12-point (6x13) size.
    ISO-8859-1 encoding only.

These fonts were created using the xmbdfed BDF font editor
<ftp://crl.nmsu.edu/CLR/multiling/General/>.

For more information about fonts and the X Window System, see the X(1)
man page.

%prep
%setup
#%patch0 -b .orig

#function Replace() {
#  local fil="$1"
#  local sep="$2"
#  local old="$3"
#  local new="$4"
#  local suf="$5"
#  [ -z "${suf}" ] && suf='~'
#  mv -f ${fil} ${fil}${suf}
#  cat ${fil}${suf} | sed -e "s${sep}${old}${sep}${new}${sep}g" >$fil
#}

%build

make -C neep

xmkmf
make

%install
function CheckBuildRoot() {
  # do a few sanity checks on the BuildRoot
  # to make sure we don't damage a system
  case "${RPM_BUILD_ROOT}" in
    ''|' '|/|/bin|/boot|/dev|/etc|/home|/lib|/mnt|/root|/sbin|/tmp|/usr|/var)
      echo "Yikes!  Don't use '${RPM_BUILD_ROOT}' for a BuildRoot!"
      echo "The BuildRoot gets deleted when this package is rebuilt;"
      echo "something like '/tmp/build-blah' is a better choice."
      return 1
      ;;
    *)  return 0
      ;;
  esac
}
function CleanBuildRoot() {
  if CheckBuildRoot; then
    rm -rf "${RPM_BUILD_ROOT}"
  else
    exit 1
  fi
}
CleanBuildRoot

for i in \
  "" \
  %{Prefix} \
  %{Prefix}/X11R6 \
  %{Prefix}/X11R6/lib \
  %{Prefix}/X11R6/lib/X11 \
  %{Prefix}/X11R6/lib/X11/fonts \
; do
  mkdir -p "${RPM_BUILD_ROOT}${i}"
done

make DESTDIR="${RPM_BUILD_ROOT}" install

%clean
function CheckBuildRoot() {
  # do a few sanity checks on the BuildRoot
  # to make sure we don't damage a system
  case "${RPM_BUILD_ROOT}" in
    ''|' '|/|/bin|/boot|/dev|/etc|/home|/lib|/mnt|/root|/sbin|/tmp|/usr|/var)
      echo "Yikes!  Don't use '${RPM_BUILD_ROOT}' for a BuildRoot!"
      echo "The BuildRoot gets deleted when this package is rebuilt;"
      echo "something like '/tmp/build-blah' is a better choice."
      return 1
      ;;
    *)  return 0
      ;;
  esac
}
function CleanBuildRoot() {
  if CheckBuildRoot; then
    rm -rf "${RPM_BUILD_ROOT}"
  else
    exit 1
  fi
}
CleanBuildRoot

%files
%attr(-   ,root,root) %doc ChangeLog NEWS README %{Name}-%{Version}.lsm
%attr(0755,root,root) %dir %{Prefix}/X11R6/lib/X11/fonts/%{FoundryDir}
%attr(0444,root,root) %{Prefix}/X11R6/lib/X11/fonts/%{FoundryDir}/*

