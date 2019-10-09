#!/bin/bash

hcmnt_init() {
    local who="$(who -m)"
    local ip=($who)
    readonly hcmnt_tty="${ip[1]}"
    readonly hcmnt_user="${ip[0]}"
    ip="${who#*(}"
    ip="${ip%)*}"
    readonly hcmnt_ip="$ip"
    readonly hcmnt_id="$(id -nu)"
}

hcmnt() {
    local HISTTIMEFORMAT=':%F %T;'

    if [ -z "${hcmnt_init}" ]
    then
        readonly hcmnt_init=1
        return 0
    fi

    if [ -z "${hcmnt_last}" ]
    then
        local last=$(fc -l -1 -1)
        last=${last%% *}
        hcmnt_last=${last//[[:blank:]]/}
    else
        hcmnt_last=${hcmnt_num}
    fi

    local hcmnt=$(history 1)
    local date=${hcmnt%%;*}
    local num=${date% :*}
    hcmnt_num=${num//[[:blank:]]/}

    if [[ ${hcmnt_num:0} != ${hcmnt_last:0} || ${hcmnt_num:0} == 1 ]]
    then
        date=${date# *[0-9]* :}
        hcmnt=${hcmnt#*;}
        hcmnt="[${date:--} ${hcmnt_id:--} (${hcmnt_user:--} ${hcmnt_tty:--} ${hcmnt_ip:--}) ${PWD:--}] ${hcmnt}"
        logger -t history "$hcmnt"
        echo "$hcmnt" >> ~/.full_history || echo "$script: file error." ; return 1
    fi

    return 0
}

hcmnt_init

if [ "$PS1" ]; then
  if [ -z "$PROMPT_COMMAND" ]; then
    case $TERM in
    xterm*)
        if [ -e /etc/sysconfig/bash-prompt-xterm ]; then
            PROMPT_COMMAND=/etc/sysconfig/bash-prompt-xterm
        else
            PROMPT_COMMAND='printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
        fi
        ;;
    screen)
        if [ -e /etc/sysconfig/bash-prompt-screen ]; then
            PROMPT_COMMAND=/etc/sysconfig/bash-prompt-screen
        else
            PROMPT_COMMAND='printf "\033]0;%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
        fi
        ;;
    *)
        [ -e /etc/sysconfig/bash-prompt-default ] && PROMPT_COMMAND=/etc/sysconfig/bash-prompt-default
        ;;
      esac
  fi
fi

if [ -z "${PROMPT_COMMAND}" ]
then
        declare -r PROMPT_COMMAND='hcmnt'
else
        declare -r PROMPT_COMMAND="hcmnt;${PROMPT_COMMAND}"
fi

declare -rx HISTCONTROL=""
declare -rx HISTIGNORE=""
declare -rx HISTSIZE=10000
declare -x HISTTIMEFORMAT='%F %T '

shopt -s histappend
