#!/bin/bash

# Variables
dir=~/Dropbox/Settings
files=".bashrc .bash_profile .aliases .gitconfig .gitignore .zshrc"

cd ~/
for file in $files; do
    rm ~/$file
    ln -s $dir/dotfiles/$file ~/$file
done

rm ~/.hyper.js
ln -s $dir/dotfiles/.hyper.js ~/.hyper.js

rm ~/.atom
ln -s $dir/Atom ~/.atom
