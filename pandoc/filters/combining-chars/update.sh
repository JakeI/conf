#!/usr/bin/env bash

LOC="$HOME/.pandoc/filters/combining-chars"
$LOC/build.sh && $LOC/clean.sh && $LOC/install.sh
