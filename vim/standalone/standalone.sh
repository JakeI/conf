#!/usr/bin/env bash

cd /tmp
( \
    echo '\documentclass[preview]{standalone}' && \
    echo '\usepackage{amsmath}' && \
    echo '\usepackage{greek}' && \
    echo '\begin{document}' && \
    cat && \
    echo '\end{document}' \
) > tex-standalone-preview.tex
xelatex tex-standalone-preview.tex
