# dotfiles git repository
alias cfg='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'

# run last command with sudo
alias please='/usr/bin/sudo $(history -p !!)'

# get me out of here
alias fuckoff='sudo shutdown -h now'
alias gitfuckit='git reset --hard HEAD'

# ls aliases
alias ls='ls -F' # make directories more visibly such
alias ll='ls -lAh' # use long listing format for all files
alias l.='ls -d .*' # See hidden files and folders

# cd aliases
alias ..='cd ..'
alias ...='cd ../..'

alias bc='bc -l' # start calculator with math support

alias diff='colordiff' # colourised diff 

alias edit='nano'
alias op='less' # cat but better

# Confirmation
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias du='du -ch' # human readable format for file size estimate
