#!/bin/bash
brg_name=$1
porta=$$
TRILL_DIR="/opt/psapt/trill/rbridges/$brg_name"
clean1(){
if [ -e $TRILL_DIR/$brg_name.conf ]; then
	echo "sig1" >> $TRILL_DIR/$brg_name-signal
	kill -1 $(cat $TRILL_DIR/$brg_name.pid)
	/usr/sbin/trilld -d -A 0.0.0.0 -i $TRILL_DIR/$brg_name.pid -P $porta -f $TRILL_DIR/$brg_name.conf $brg_name
else
	echo "sig1" >> /tmp/$brg_name-signal
	kill -1 $(cat /tmp/$brg_name.pid)
fi
}
clean15(){
if [ -e $TRILL_DIR/$brg_name.conf ]; then
	echo "sig15" >> $TRILL_DIR/$brg_name-signal
	kill -15 $(cat $TRILL_DIR/$brg_name.pid)
	exit 0
else
	kill -15 $(cat /tmp/$brg_name.pid)
	rm -f /tmp/$brg_name.*
	rm -f /tmp/$brg_name-signal
	exit 0
fi
}
trap "clean1" 1
trap "clean15" 15
if [ -e $TRILL_DIR/$brg_name.conf ]; then
	rm $TRILL_DIR/$brg_name.pid 2> /dev/null
	touch $TRILL_DIR/$brg_name.pid
	porta=$(cat $TRILL_DIR/$brg_name.port)
	echo "" > $TRILL_DIR/$brg_name.log
	/usr/sbin/trilld -d -A 0.0.0.0 -i $TRILL_DIR/$brg_name.pid -P $porta -f $TRILL_DIR/$brg_name.conf $brg_name
else
	touch /tmp/$brg_name.pid
	/usr/sbin/trilld -d -i /tmp/$brg_name.pid -P 0 $brg_name
fi
while true; do
 sleep 5
done
