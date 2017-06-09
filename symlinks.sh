#!/bin/bash

# Variables
dir=~/Dropbox/Settings/dotfiles
files=".bashrc .bash_profile .aliases .gitconfig .gitignore"

cd ~/
for file in $files; do
    echo "Symlinking $file"
    ln -s $dir/$file ~/$file
done

rm ~/.atom
ln -s ~/Dropbox/Settings/Atom ~/.atom
