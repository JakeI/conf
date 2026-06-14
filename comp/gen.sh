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
        if (ch in ex) {
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


# WARNING: This tunrns out to be useless: Nice idea but dosne't work
# WinCompose won't actually handle <F*> keys. Windows is awful!
# This should deal with windows keyboard dead keys that cannot be turned off
# Configure keyboard to send F22 for ^ and F21 for ` and F20 for ´
# Use PowerToys Tastaur-Manager to make F20,F21,F22 "send text" with the matching char
# Handel those F keys here separably
# cat $LOC/tmp.compose | \
#     grep '<asciicircum>' | sed 's/<asciicircum>/<F22>/g' > $LOC/f22.compose
# cat $LOC/{tmp,f22}.compose | \
#     grep '<grave>' | sed 's/<grave>/<F21>/g' > $LOC/f21.compose
# cat $LOC/{tmp,f22,f21}.compose | \
#     grep '<acute>' | sed 's/<acute>/<F20>/g' > $LOC/f20.compose
cat $LOC/tmp.compose | \
    grep '<asciicircum>' | sed 's/<asciicircum>/<Up>/g' > $LOC/f22.compose
cat $LOC/{tmp,f22}.compose | \
    grep '<grave>' | sed 's/<grave>/<Left>/g' > $LOC/f21.compose
cat $LOC/{tmp,f22,f21}.compose | \
    grep '<acute>' | sed 's/<acute>/<Right>/g' > $LOC/f20.compose

# combine and normalize (= remove space and comments)
cat $LOC/{tmp,f22,f21,f20}.compose | \
    sed 's/[[:space:]][[:space:]]*/ /g; s/\(: "[^"]*"\).*/\1/' | \
    sort | uniq \
    > $LOC/XCompose

# check for dublicates 
# (technically this is obsolete now that I also check for prefix free sequences below)
# however for now I actually de-duplicate for the prefix check so those are
# actually considered different types of errors
cat $LOC/XCompose | \
    cut -d: -f1 | \
    uniq -cd \
    > $LOC/dublicates.warning
if [ -s $LOC/dublicates.warning ]
then
    printf '\033[31mWARNING: There are %s dublicate compose sequences see %s\n' \
        "$(cat $LOC/dublicates.warning | wc -l)" \
        "$LOC/dublicates.warning"
else
    rm $LOC/dublicates.warning
fi

# check if prefix free (ignoring dublicates using the `uniq` line)
cat $LOC/XCompose | \
    cut -d: -f1 | \
    sort | \
    uniq | \
    awk '
        NR > 1 && prev != "" && index($0, prev) == 1 {
            print prev, " => ", $0
        }
        { prev = $0 }
        ' \
    > "$LOC/prefixes.warning"
if [ -s $LOC/prefixes.warning ]
then
    printf '\033[31mWARNING: There are %s non prefix-free compose sequences see %s\n' \
        "$(cat $LOC/prefixes.warning | wc -l)" \
        "$LOC/prefixes.warning"
else
    rm $LOC/prefixes.warning
fi

rm $LOC/{greek,tmp,f22,f21,f20}.compose
