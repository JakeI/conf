#!/usr/bin/env bash

LINKS=$(cat <<EOF
ln zsh/zshrc                         $HOME/.zshrc
ln vim/vimrc                         $HOME/.vimrc
ln vim/UltiSnips                     $HOME/.vim/UltiSnips
ln vim/colors                        $HOME/.vim/colors
ln vim/init.vim                      $HOME/.config/nvim/init.vim
ln vim/standalone                    $HOME/bin/standalone
ln comp/XCompose                     $HOME/.XCompose
ln keys/remap                        $HOME/bin/remap-all
ln bin/ocr                           $HOME/bin/ocr
ln bin/multicrop                     $HOME/bin/multicrop
ln bin/ascii2box.pl                  $HOME/bin/ascii2box.pl
ln bin/pageedripgrap                 $HOME/bin/pageedripgrap
ln bin/pdfpagelist                   $HOME/bin/pdfpagelist
ln bin/Ansel-675c000-x86_64.AppImage $HOME/bin/ansel.AppImage
ln bin/anonymize-pdf                 $HOME/bin/anonymize-pdf
ln bin/modern-latexmk                $HOME/bin/modern-latexmk
ln bin/pplatex                       $HOME/bin/pplatex
ln desktop/photos.ansel.app.desktop  $HOME/.local/share/applications/photos.ansel.app.desktop
ln desktop/feh.desktop               $HOME/.local/share/applications/feh.desktop
ln pandoc                            $HOME/.pandoc
ln tex                               $HOME/.tex
ln tex/cheat.cls                     $HOME/texmf/tex/latex/local/cheat.cls
ln tex/greek.sty                     $HOME/texmf/tex/latex/local/greek.sty
ln tex/code.sty                      $HOME/texmf/tex/latex/local/code.sty
ln tex/jlcode.sty                    $HOME/texmf/tex/latex/local/jlcode.sty
ln tex/tweet.sty                     $HOME/texmf/tex/latex/local/tweet.sty
ln tex/emoji-fallback.sty            $HOME/texmf/tex/latex/local/emoji-fallback.sty
ln tex/overarrows.sty                $HOME/texmf/tex/latex/local/overarrows.sty
ln tmux/tmux.conf                    $HOME/.tmux.conf
ln ipython/fzf-ipython.py            $HOME/.ipython/profile_default/startup/fzf-ipython.py
ln ipython/ipython_config.py         $HOME/.ipython/profile_default/ipython_config.py
ln jupyter/jupyter_console_config.py $HOME/.jupyter/jupyter_console_config.py
ln gams/gams                         $HOME/bin/gams
ln gams/gdx                          $HOME/bin/gdx
ln gams/gdx2sqlite                   $HOME/bin/gdx2sqlite
ln gams/gdxdiff                      $HOME/bin/gdxdiff
ln gams/gdxdump                      $HOME/bin/gdxdump
ln gams/gamsmodel2tex                $HOME/bin/gamsmodel2tex
ln host/update                       $HOME/bin/hosts/update
ln git/gitconfig                     $HOME/.gitconfig
rw $HOME/curr/task                   $HOME/.task
ln gdb/gdbinit                       $HOME/.gdbinit
ln keys/kmonad.service               $HOME/.config/systemd/user/kmonad.service
ln gaomon                            $HOME/bin/gaomon
ln fonts                             $HOME/.fonts
ln nix/nix.conf                      $HOME/.config/nix/nix.conf
ln kitty/kitty.conf                  $HOME/.config/kitty/kitty.conf
ln pdf/zathurarc                     $HOME/.config/zathura/zathurarc
ln vscode/keybindings.json           $HOME/.config/Code/User/keybindings.json
ln vscode/settings.json              $HOME/.config/Code/User/settings.json
ln vscode/snippets                   $HOME/.config/Code/User/snippets
ln nb/nbrc                           $HOME/.nbrc
ln emacs/emacs.d                     $HOME/.emacs.d
ln emacs/spacemacs                   $HOME/.spacemacs
ln zellij/config.kdl                 $HOME/.config/zellij/config.kdl
EOF
)

mkdir -p $HOME/bin/hosts
mkdir -p $HOME/texmf/tex/latex/local
mkdir -p $HOME/.config/kmonad
mkdir -p $HOME/.config/nvim
mkdir -p $HOME/.vim
mkdir -p $HOME/bin
mkdir -p $HOME/.ipython/profile_default/startup
mkdir -p $HOME/.jupyter
mkdir -p $HOME/.config/systemd/user
mkdir -p $HOME/.config/nix
mkdir -p $HOME/.config/kitty
mkdir -p $HOME/.config/zathura
mkdir -p $HOME/.config/Code/User
mkdir -p $HOME/.config/Code/User/snippets
mkdir -p $HOME/.config/zellij


SCRIPT=$(realpath "$0")
CONFIGDIR=$(dirname "$SCRIPT")
LOGFILE="$CONFIGDIR/install.log"

echo "Attempt to link config files"
echo "" >> $LOGFILE
date    >> $LOGFILE

maybe_link () {
    if [[ ! $1 =~ gams/ || "$(uname -m)" =~ x86_64 ]]
    then
        (test "$2" -ef "$3"                  && echo 'already setup'            ) || \
        (test -f "$3"                        && echo 'skip because file exists' ) || \
        ((test "$1" = "ln" || test "$1" = "rw")                                      \
                && ln -s "$2" "$3"           && echo 'successfully linked'      ) || \
        (test "$1" = "cp" && cp    "$2" "$3" && echo 'successfully copied'      )
    fi
}

handle_links () {
    echo "source;destination;message"; 
    echo "$LINKS" | while IFS= read -r line
    do
        opt="$(echo $line | awk '{ print $1 }')"
        dir="$(test $opt = 'rw' && echo "" || echo $CONFIGDIR/ )"
        src="$dir$(echo $line | awk '{ print $2 }')"
        dst="$(echo $line | awk '{ print $3 }')"
        msg="$(maybe_link $opt $src $dst)"
        echo "$src;$dst;$msg"
    done
}

format () {
    # column -t -s ';' -o ' | '
    column -t -s ';'
}

handle_links | format | tee -a "$LOGFILE"

install_binary () {
    which "$1" > /dev/null
    if [ ! "$?" -eq 0 ]
    then
        echo " === Running install for '$1' ==="
        eval "$2"
        echo " === Finished install for '$1' ==="
    fi
}

install_binary "combining-chars" "~/.pandoc/filters/combining-chars/update.sh"
