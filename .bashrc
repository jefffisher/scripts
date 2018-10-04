# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
    else
    color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    # alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias la='ls -A'
alias l='ls -AlF'
alias diff='colordiff'
alias less='less -XFR'
alias mk='make 2>&1 | tee .mk; grep DEVDIR .mk > /dev/null && echo make && mkenv && make; rm .mk #'
alias lint='cppcheck -j4 -q --enable=all --inline-suppr'
alias lsg='curl -s internal.trilliumeng.com/gimbal_list.php | sed -n "s/.*gimbal_ip\">\([^<]*\).*/\1/p"'
alias mkenv='pushd `pwd | grep -o ".*OrionPayload"` > /dev/null && `make env` && popd > /dev/null'
alias rebuild='make clean && make'
alias sl='sl -e'
alias ping='ping -W1'
alias ccat='ccat -C always'

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

function ll() {
    CMD="$(fc -ln -2 -2 | sed 's/^[ \t]*//') | less"
    for e in $(history 2 | awk '{ print $1 }'); do
        history -d $e
    done
    eval "$CMD"
    history -s "$CMD"
}


function ls {
    if [ -t 1 ]; then OPT=--color=always; else OPT=; fi
    command ls "$@" $OPT | ([ -t 1 ] && less || cat)
}

svn() {
    case $1 in
    "log"|"st"|"status"|"help") command svn $@ | less;;
    "diff")
        if [ -t 1 ]; then
            OPTS=-udpw
        else
            OPTS=-ud
        fi
        command svn -x $OPTS $@ | ([ -t 1 ] && tr -d '\r' | colordiff | less || cat)
        ;;
    "wdiff"|"wd") command svn -x -udpw diff ${@:2:$#-1} | ([ -t 1 ] && wdiff -nd | tr -d '\r' | colordiff | less || cat);;
    "patch")  [ "$#" -gt "1" ] && patch -p0 ${@:2:$#-2} -i ${!#} || patch --help;;
    "blame") command svn $@ | awk '{ if (R[$1] == "") R[$1] = length(R) % 147 + 70; printf "\x1b[1;38;5;%dm %5d %s\x1b[0m\n", R[$1], NR, $0 }' | less;;
    *) command svn $@;;
    esac;
}

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

if [ ! -f ~/.ssh/orion ]; then
    echo "Looking for Orion SSH key in ~/svn..."
    KEY=$(find ~/svn -path '*OrionPayload/id_rsa' ! -perm /g=r)

    if [ -n "$KEY" ]; then
        cp $KEY ~/.ssh/orion
    fi
fi

if [ -f ~/.ssh/orion ] && ! grep ~/.ssh/orion ~/.ssh/config > /dev/null 2>&1; then
    printf "\nIdentityFile ~/.ssh/orion\n" >> ~/.ssh/config
fi
