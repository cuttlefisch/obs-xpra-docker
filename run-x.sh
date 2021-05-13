#!/bin/bash

export XDG_RUNTIME_DIR=/run/user/$(id -u)
function show_log() {
	while [ 1 ]; do
		sleep 1
		tail -f $XDG_RUNTIME_DIR/xpra/:100.log
	done
}

xvfb='Xorg -dpi 96 -noreset -nolisten tcp +extension GLX +extension RANDR +extension RENDER -logfile ${HOME}/.xpra/Xvfb-10.log -config ${HOME}/xorg.conf'

xpra --xvfb="$xvfb"  start :100 --exec-wrapper="$(which vglrun) -d :100" --start="obs $*" --bind-tcp=0.0.0.0:14500 --html=on

show_log &

cnt=30
while [[ ! -f /tmp/.X100-lock && $cnt -gt 0 ]]; do
	echo "Waiting for ready Xpra..."
	cnt=$((cnt - 1))
	sleep 1
done

if [ ! -f /tmp/.X100-lock ]; then
	echo "xpra start failed"
	exit 1
fi

xpra_pid=$(cat /tmp/.X100-lock | tr -d ' ')

while kill -0 $xpra_pid; do
	sleep 1
done

