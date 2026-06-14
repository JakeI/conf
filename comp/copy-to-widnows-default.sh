#!/usr/bin/env bash

WINHOME="$(wslpath $(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null) | tr -d '\r')"
echo "Copyting XCompese to $WINHOME/.XCompose"
echo "You still need to click reload in the WinCompose GUI"
cp XCompose $WINHOME/.XCompose

