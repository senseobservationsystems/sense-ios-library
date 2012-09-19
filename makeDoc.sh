#!/bin/sh
#  Build the doxygen documentation for the project and load the docset into Xcode.

DOXYGEN="/Applications/Doxygen.app/Contents/Resources/doxygen"

if ! [ -f doxygen.config ]; then
	echo "doxygen.config not found. Exiting..."
	exit
fi

$DOXYGEN doxygen.config
#  make will invoke docsetutil. Take a look at the Makefile to see how this is done.
make -C doc/html/ uninstall
make -C doc/html/ install

#tell xcode to load the new documentation
osascript -e 'tell application "Xcode"' -e 'load documentation set with path "/Users/pim/Library/Developer/Shared/Documentation/DocSets/"' -e 'end tell'
exit 0
