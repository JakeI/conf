#!/usr/bin/env bash

ghc --make combining-chars.hs \
    -package pcre-light-0.4.1.0 \
    -package pcre-heavy-1.0.0.2 \
    -package text-conversions-0.3.1 \
    -package string-conversions-0.4.0.1 \
    -package stringable-0.1.3 \
    -package utf8-string-1.0.2 \
    -package pandoc-types-1.20

# Use this for debugging
# vim combining-chars.hs && ghc --make combining-chars.hs -package pcre-light-0.4.1.0 -package pcre-heavy-1.0.0.2 -package text-conversions-0.3.1 -package string-conversions-0.4.0.1 -package stringable-0.1.3 -package utf8-string-1.0.2 -package pandoc-types-1.22 && cat test-this.json | ./combining-chars | jq --color-output | tail -n 7 | head -n 1
# with a test-this.json file generated using:
# pandoc -f markdown -t json -o test-this.json test-this.md
