#!/bin/bash
. /opt/psapt/bin/control_functions.sh
cen_dir="/opt/psapt/cenarios"
run_dir="$cen_dir/$1/run"
stop_vms "$cen_dir/$1"
#start_vms "$cen_dir/$1"
#check_cen_sanity "$cen_dir/$1"
#echo $?
#copy_cen_files "$cen_dir/$1"
#check_diff "$cen_dir/$1"
##get_cen_status $1
##stop_links_conn /opt/cenarios/$1
##stop_bridges /opt/cenarios/$1
