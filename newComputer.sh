echo "Congrats on Getting a New Computer. Let's Party!"
# install and update brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update

echo "Setting up directories..."
mkdir ~/Developments

echo "Installing Development Tools..."
# install python the 'correct' way
bash ./installPython.sh

# install node and npm
brew install node
# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash

# install git
brew install git
git config --global user.name "M Kusold"
git config --global user.email "michelle.kusold@freshconsulting.com"

echo "Installing Core Applications..."
# install docker
brew cask install docker
# install bettertouchtool
brew cask install bettertouchtool
echo "Don't forget to go in and setup auto locking shortcuts"
# install hyper terminal
brew cask install hyper
node ./setHyperPlugins.js

# install vscode
brew cask install visual-studio-code
# add to path so that we can use the 'code' command
echo '
# vscode
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"' >>~/.bash_profile
# auto-install favorite extensions
bash ./vscodeExtensions.sh

# install hyper gitkraken
brew cask install gitkraken
# install vmware fusion
brew cask install vmware-fusion

echo "Installing Extra Applications..."
# install slack
brew cask install slack
# install harvest
brew cask install harvest
# install dropbox
brew cask install dropbox
# install firefox
brew cask install firefox
# install flux
brew cask install flux
# install spotify
brew cask install spotify
# install numi
brew cask install numi
# install recordit
brew cask install recordit
# gotomeeting
brew cask install gotomeeting

echo "Customizing user profile"
echo '
# Custom Modifications
alias ding="afplay /System/Library/Sounds/Glass.aiff"
alias dev="cd ~/Development
alias fresh="echo '🍃'
alias modified-coverage="git changed-files | xargs npx jest --coverage --collectCoverageOnlyFrom"
' >>~/.bash_profile

