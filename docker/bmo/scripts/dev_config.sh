#!/bin/bash
# Add any custom setup instructions here

# Home dotfiles
git clone https://github.com/dklawren/homedir $HOME/homedir
cd $HOME/homedir && ./makedotfiles.sh

# Vim configuration
git clone https://github.com/dklawren/dotvim $HOME/.vim
cd $HOME/.vim
git submodule update --init
ln -sf $HOME/.vim/rc/vimrc $HOME/.vimrc
vim +PluginInstall +qall
git clone https://github.com/powerline/fonts.git $HOME/powerline-fonts
cd $HOME/powerline-fonts && ./install.sh
