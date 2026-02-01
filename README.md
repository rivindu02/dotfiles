# My dotfiles
This directory contains the dotfiles for my system

## Requirements
Ensure you have the following installed on your system

### Git
```sudo apt install git -y```
### Stow
```sudo apt install stow -y```
### Installation
First, check out the dotfiles repo in your $HOME directory using git

```
$ git clone git@github.com/rivindu02/dotfiles.git
$ cd dotfiles
```
then use GNU stow to create symlinks
```
$ stow .
```
