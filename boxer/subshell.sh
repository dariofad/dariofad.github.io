#!/bin/bash

ENV_VARS=( $(env | cut -d= -f1) )

ENV_VAR_ALLOWLIST=( DBUS_SESSION_BUS_ADDRESS DESKTOP_SESSION GDMSESSION GTK_IM_MODULE GTK_MODULES HOME LANG LANGUAGE LC_ADDRESS LC_ALL LC_IDENTIFICATION LC_MONETARY LC_NAME LC_NUMERIC LC_TIME LESSOPEN LOGNAME OLD_PWD PATH PWD SESSION_MANAGER SYSTEMD_EXEC_PID USER USERNAME XDG_CONFIG_DIRS XDG_CURRENT_DESKTOP XDG_MENU_PREFIX XDG_SESSION_DESKTOP XDG_SESSION_TYPE XMODIFIERS SHELL )

for v in ${ENV_VARS[@]}; do
    found=0
    for va in ${ENV_VAR_ALLOWLIST[@]}; do
	if [ $v == $va ]; then
	    found=1
	    break
	fi
    done
    if [ $found == 0 ]; then
	# unset variable v
	unset $v
    fi
done

# spawn the sandboxer
(./boxer/target/debug/boxer --argument $1 --policy $2)
