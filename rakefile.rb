# Setup ////////////////////////////////////////////////////////////

#-1.  http://www.alfredapp.com/
#-2.  https://www.google.com/intl/en/chrome/browser/
#-3.  https://www.dropbox.com
#-4.  App Store > Divvy
#-5.  App Store > Caffeine
#-6.  App Store > Xcode
#-7.  http://bjango.com/mac/istatmenus/
#-8.  http://www.macbartender.com/
#-9.  http://www.iterm2.com/#/section/home
#-10. $ ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
#-11. $ brew install zsh
#-12. $ brew install git
#-13. $ brew install rvm


# Tasks - Link  ////////////////////////////////////////////////////

# http://www.sublimetext.com/
desc "Link Sublime Text"
task :link_sublime do
  system "ln -s ~/Dropbox/settings/Sublime\ Text\ 2/Packages/User/ ~/Library/Application Support/Sublime Text 2/Packages/User"
end

# http://www.gnupg.org/
desc "Link gnupg for password-store"
task :link_gnupg do
  system "ln -s ~/Dropbox/settings/.gnupg ~/.gnupg"
end

# http://www.zx2c4.com/projects/password-store/
desc "Link password-store"
task :link_pass do
  system "ln -s ~/Dropbox/settings/.password-store ~/.password-store"
end


# Automation ///////////////////////////////////////////////////////

desc 'Link Development'
task :jekyll => [:haml, :clean] do |task, args|
  system "jekyll serve --watch"
end

desc 'Link Personal'
task :jekyll => [:haml, :clean] do |task, args|
  system "jekyll serve --watch"
end

desc 'Backup password-store and gnupg to USB'
task :backup_pass do
  system "cp -R ~/Dropbox/settings/.password-store /Volumes/keychain/settings"
  system "echo ## Backed-up password-store to USB"
  system "cp -R ~/Dropbox/settings/.gnupg /Volumes/keychain/settings"
  system "echo ## Backed-up gnupg to USB"
end
