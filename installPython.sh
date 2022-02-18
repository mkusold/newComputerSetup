# === Proper python setup ===
# https://medium.com/@briantorresgil/definitive-guide-to-python-on-mac-osx-65acd8d969d0
xcode-select --install
# install pyenv
brew install pyenv
# install python required packages
brew install openssl readline sqlite3 xz zlib
# add pyenv to shell
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc
# Install python 3.x
brew install python
# Install pipx to manage global packages
python3 -m pip install --user pipx
python3 -m userpath append ~/.local/bin
# Install global packages
python3 -m pipx install flake8
python3 -m pipx install black
# install the latest python 2.7
brew install python@2
# get a stable version of python installed
pyenv install 3.9.10
# set it as the global python version
pyenv global 3.9.10
# install poetry
curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python
source $HOME/.poetry/env
# ensure that poetry installs dependencies at the project level
poetry config virtualenvs.in-project true
# bash profile config
echo '
# To properly set python3 as the default
PATH=$(pyenv root)/shims:$PATH

# pipx
export PATH="~/.local/bin:$PATH"

# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=true

# commands to override pip restriction above.
# use `gpip` or `gpip3` to force installation of
# a package in the global python environment
# Never do this! It is just an escape hatch.
gpip(){
   PIP_REQUIRE_VIRTUALENV="" pip "$@"
}
gpip3(){
   PIP_REQUIRE_VIRTUALENV="" pip3 "$@"
}
' >>~/.zshrc