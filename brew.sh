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

# Env
brew install zsh
echo "/usr/local/bin/zsh" | sudo tee -a /etc/shells
chsh -s /usr/local/bin/zsh
brew install zsh-completions
brew install zsh-syntax-highlighting
brew install zsh-history-substring-search

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
