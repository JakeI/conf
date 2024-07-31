#!/usr/bin/env bash

NAME="juliamono-ttf.zip"
wget -O "$NAME" https://github.com/cormullion/juliamono/blob/372b24c689942a67a2b7da7d500a8d195e382489/juliamono-ttf.zip?raw=true
unzip "$NAME"
rm "$NAME"
LOC="$HOME/.fonts/"
mv JuliaMono-* "$LOC"
fc-cache -f -v
[[ $(fc-list | grep "JuliaMono" | wc -l) > 0 ]] && \
    (echo "successfully installed JuliaMono" && exit 0) || \
    (echo "failed to install JuliaMono" && exit 1)
