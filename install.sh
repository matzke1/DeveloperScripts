#!/bin/bash -e

DEV_ROOT="$(pwd)"

#
# Scripts
#
mkdir -p $HOME/bin
(
    cd $HOME/bin
    ln -sf $DEV_ROOT/scripts/args-adjust .
    ln -sf $DEV_ROOT/scripts/command-name .
    ln -sf $DEV_ROOT/scripts/mv-lower .
    ln -sf $DEV_ROOT/scripts/mv-renumber .
    ln -sf $DEV_ROOT/scripts/path-adjust .
    ln -sf $DEV_ROOT/scripts/prune .
    ln -sf $DEV_ROOT/scripts/randargs .
    ln -sf $DEV_ROOT/scripts/raw2jpg .
    ln -sf $DEV_ROOT/scripts/rg-clone .
    ln -sf $DEV_ROOT/scripts/rg-findfile .
    ln -sf $DEV_ROOT/scripts/rg-search .
)

#
# ROSE development tools
#
mkdir -p $HOME/bin
(
    cd $HOME/bin
    ln -sf $DEV_ROOT/rose-devel-tools/rmc .
    ln -sf $DEV_ROOT/rose-devel-tools/install-boost .
    ln -sf $DEV_ROOT/rose-devel-tools/install-wt .
    ln -sf $DEV_ROOT/rose-devel-tools/install-yaml .
)

#
# ROSE tools (old versions)
#
mkdir -p $HOME/bin/rosegit-bin
(
    cd $HOME/bin/rosegit-bin
    ln -sf $DEV_ROOT/rosegit/config .
    ln -sf $DEV_ROOT/rosegit/rg-config .
    ln -sf $DEV_ROOT/rosegit/rg-env .
    ln -sf $DEV_ROOT/rosegit/rg-filter-make-error .
    ln -sf $DEV_ROOT/rosegit/rg-make .
    ln -sf $DEV_ROOT/rosegit/rg-src .
    ln -sf $DEV_ROOT/rosegit/rosegit-functions.sh .
)

#
# Emacs
#
(
    cd $HOME
    ln -sf $DEV_ROOT/xemacs/dot.emacs .emacs
    mkdir -p .emacs.d/lisp
    cd .emacs.d/lisp
    ln -s $DEV_ROOT/xemacs/pilf.el .
    
    echo "Copy the following directories to this machine:"
    echo "    $HOME/.emacs.d/lisp/cc-mode"
    echo "    $HOME/cedet"
    read -p "Press ENTER when finished. "
)

#
# Bash
#
(
    cd $HOME
    ln -sf --backup $DEV_ROOT/bash/bash_env .bash_env
    ln -sf --backup $DEV_ROOT/bash/bash_logout .bash_logout
    ln -sf --backup $DEV_ROOT/bash/bash_profile .bash_profile
    ln -sf --backup $DEV_ROOT/bash/bashrc .bashrc
    ln -sf --backup $DEV_ROOT/bash/environment .environment
)
