#!/usr/bin/env bash

LOC="$HOME/conf/comp"

# greek.compose
awk '
    BEGIN {
        ex["|"] = "bar";
        ex[">"] = "greater";
        ex["<"] = "less";
        ex["\\"] = "backslash";
        ex["_"] = "underscore";
        ex["*"] = "asterisk";
        ex[":"] = "colon";
        ex[";"] = "semicolon";
        ex["+"] = "plus";
        ex["-"] = "minus";
        ex["/"] = "slash";
        ex["["] = "bracketleft";
        ex["]"] = "bracketright";
        ex["{"] = "braceleft";
        ex["}"] = "braceright";
        ex["("] = "parenleft";
        ex[")"] = "parenright";
        ex["^"] = "asciicircum";
        ex["~"] = "asciitilde";
        ex["!"] = "exclam";
        ex["?"] = "question";
        ex["."] = "period";
        ex[","] = "comma";
        ex["="] = "equal";
        ex["$"] = "dollar";
        ex["&"] = "ampersand";
        ex["%"] = "percent";
        ex["@"] = "at";
        ex["#"] = "numbersign";
        ex[" "] = "space";
        ex["\""] = "quotedbl";
        ex["'"'"'"] = "apostrophe";
        ex["`"] = "grave";
        ex["´"] = "acute";
    }

    function fix(ch) {
        if(ch ~ /[0-9a-zA-Z]/) {
            return ch;
        } else if (ch in ex) {
            return ex[ch];
        } else {
            return ch;
        }
    }

    match($0, /\\newunicodechar{(.)}.*§(..)/, a) {
        print                                       \
            "<Multi_key> <" fix(substr(a[2],1,1))   \
            "> <"           fix(substr(a[2],2,1))   \
            "> : \"" a[1] "\"";
    }' $HOME/conf/tex/greek.sty > $LOC/greek.compose

cat $LOC/{names,words,greek,user}.compose | \
    sed 's/#.*$//' | \
    sed 's/ *$//' \
    > $LOC/tmp.compose


# WARNING: This tunrns out to be useless: WinCompose won't actually handle <F*> keys. Windows is anoyhing!
# deal with windows Keyborads dead keys that cannot be turned off
# Configure Keybord to send F22 for ^ and F21 for ` and F20 for ´
# Use PowerToys Tastaur-Manager to meke F20,F21,F22 "send text" with the matching char
# Handel those F keys here separably
cat $LOC/tmp.compose | \
    grep '<asciicircum>' | sed 's/<asciicircum>/<F22>/g' > $LOC/f22.compose
cat $LOC/{tmp,f22}.compose | \
    grep '<grave>' | sed 's/<grave>/<F21>/g' > $LOC/f21.compose
cat $LOC/{tmp,f22,f21}.compose | \
    grep '<acute>' | sed 's/<acute>/<F20>/g' > $LOC/f20.compose

cat $LOC/{tmp,f22,f21,f20}.compose > $LOC/XCompose

rm $LOC/{greek,tmp,f22,f21,f20}.compose
