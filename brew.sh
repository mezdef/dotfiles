#!/usr/bin/env bash

xcode-select --install

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew doctor
brew update
brew upgrade

brew install wget --with-iri
brew install vim --with-override-system-vi
brew install git
brew install imagemagick --with-webp
brew install chrome-cli

# Apps
brew install caskroom/cask/brew-cask
brew cask install hyper
brew cask install google-chrome
brew cask install Hazel
brew cask install alfred
brew cask install backblaze
brew cask install dropbox
brew cask install 1password
brew cask install omnifocus
brew cask install atom
brew cask install bartender
brew cask install bitbar
brew cask install iina
brew cask install karabiner-elements

# Fin
brew cleanup
