#!/bin/sh
if which carthage >/dev/null; then
    /usr/local/bin/carthage copy-frameworks
else
    echo "Carthage does not exist, download from https://github.com/Carthage/Carthage"
fi
