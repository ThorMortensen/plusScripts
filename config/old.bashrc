# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

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
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

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
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi





######## My stuff ######
alias å='gedit ~/.bashrc &'
alias ø='. ~/.bashrc'
alias eclipse='/home/thm/eclipse/eclipse'
#alias ifconfig='/sbin/ifconfig'
#alias route='/sbin/route'
alias peterssh='ssh -i ~/.ssh/r thm@10.0.100.236'
#alias vsim='~/intelFPGA_lite/16.1/modelsim_ase/bin/vsim'
alias lowlevelcd='cd ~/workspace/223_EMBEDDED/firmware/lib/rovsing/apb-lowlevel'
alias mountlabpc='sshfs rma@10.0.100.104:/home/rma/thm ~/labpc'
alias cpkernel='scp uImage uImage.md5sum  rma@10.0.100.104:thm/newKernel'
alias labpc='ssh -i ~/.ssh/r rma@10.0.100.104'
alias flashLocal='export LD_PRELOAD=/opt/Xilinx/usb-driver/libusb-driver.so && impact -batch ~/impactLocal.cmds'
alias fixnet='sudo route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.255.1 dev enp0s31f6'
alias antbuild='ant -f ~/workspace/223_SAS/xml/MASC_SLP_SAS_FirmwareBuilder.xml'
alias cdvhdl='cd ~/workspace/223_EMBEDDED/firmware/lib/rovsing/'
#alias masctest_telnet='_telnet 192.168.52.16'
#alias masctest_makedeploy='make deploy DEPLOY_IP="192.168.52.16"'
#alias masctest_flashkernel='_deployGeneric -tmasc -wkernel-FPU_preCompiledLib -slocal -b16 -i16'
alias masctest_telnet='_telnet 192.168.52.25'
alias masctest_makedeploy='make deploy DEPLOY_IP="192.168.52.25"'
alias masctest_flashkernel='_deployGeneric -tmasc -wkernel-FPU_preCompiledLib -slocal -b25 -i25'
alias docrun='sudo docker run -v ~/workspace/223_SAS/systemTestDocuments:/testdoc -w /testdoc -it testdocimg bash'
alias docdel='sudo ip link del docker0'
alias xmledit='gedit ~/workspace/223_SAS/xml/MASC_SLP_SAS_FirmwareBuilder.xml'
######## Build stuff #####
export XILINXD_LICENSE_FILE=2100@10.0.100.44
export LM_LICENSE_FILE=2100@10.0.100.44

PATH=$PATH:/home/thm/intelFPGA/16.1/modelsim_ase/bin:/home/thm/workspace/223_EMBEDDED/deployScripts:/opt/Xilinx/14.2/ISE_DS/ISE/bin/lin64/:/opt/Xilinx/current/ISE_DS/ISE/bin/lin64:/opt/sparc-linux-3.4.4/bin/:~/scripts
export XILINX=/opt/Xilinx/14.2/ISE_DS/ISE
#export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH:/opt/Xilinx/14.2/ISE_DS/ISE/lib/lin64:/lib/lin64:/smartmodel/lin64/installed_lin64/lib
export LD_LIBRARY_PATH=/home/thm/intelFPGA_lite/16.1/modelsim_ase/lib32
#/opt/Xilinx/usb-driver/libusb-driver.so

#export MODELSIM=~/modelsim.ini



export TMP=$TMPDIR
export TEMP=$TMPDIR


#export MODELSIM=/home/prs/modelsim.ini




#test -s ~/.alias && . ~/.alias || true


export QSYS_ROOTDIR="/home/thm/intelFPGA_lite/16.1/quartus/sopc_builder/bin"

#sudo route add -net 192.168.0.0 netmask 255.255.0.0 gw 192.168.255.1 dev eth0
