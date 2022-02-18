echo "Congrats on Getting a New Computer. Lets Party!"
# install and update brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update

echo "Setting up directories..."
mkdir ~/Developments

# permissions for zshrc
(cd /usr/local/share/ && sudo chmod -R 755 zsh && sudo chown -R root:staff zsh )

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
git config --global user.email "m@kusold.com"

echo "Installing Core Applications..."
# install docker
brew install docker
# install bettertouchtool
brew install bettertouchtool
echo "Don't forget to go in and setup auto locking shortcuts"
# install hyper terminal
brew install hyper
node ./setHyperPlugins.js

# install vscode
brew install visual-studio-code
# add to path so that we can use the 'code' command
echo '
# vscode
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"' >>~/.zshrc
# auto-install favorite extensions
bash ./vscodeExtensions.sh
# make vscode the default git editor
git config --global core.editor "code"

# install hyper gitkraken
brew install gitkraken
# install vmware fusion
# brew install vmware-fusion

echo "Installing Extra Applications..."
# install slack
brew install slack

# install firefox
brew install firefox

# install flux
# brew install flux

# install spotify
brew install spotify

# install numi
brew install numi

# install recordit
brew install recordit

echo "Customizing user profile"
echo '
# Custom Modifications
alias ding="afplay /System/Library/Sounds/Glass.aiff"
alias dev="cd ~/Development
alias modified-coverage="git changed-files | xargs npx jest --coverage --collectCoverageOnlyFrom"
' >>~/.zshrc

