#!/bin/bash
PSAPT_DIR="/opt/psapt"
BIN_DIR="$PSAPT_DIR/bin"
CEN_DIR="$PSAPT_DIR/cenarios"
arg_num=$#
if [ $arg_num -lt 2 ]; then
        echo "usage: vm <cenario> [<comando>|?]"
        exit 0
fi
cen_to_operate=$1
command=$2
if [ ! -d $CEN_DIR/$cen_to_operate ]; then
        echo "Cenario nao existe"
        exit 1
fi
cenario="$CEN_DIR/$cen_to_operate"
run_dir="$cenario/run"
. $BIN_DIR/vm_functions.sh
get_cen_status $cen_to_operate
if [ $? -eq 0 ]; then
   echo "Cenario nao executando..."
   exit 1
fi
if ! [ -s $cenario/vms ]; then
	echo "Cenario $cenario nao possue VMs."
	exit 1
fi
general_usage(){
	echo -e "Uso:
comandos:
list - lista as VMs do cenario informado.
info <vm> - mostra informacoes da VM como: IP, link, usuario e senha.
chaddr <vm> <ip> <mask> - muda o endereco IP da VM para <ip/mask>.
"
	exit 0
}
case "$command" in
        info )
                if [ $arg_num -ne 3 ]; then
                        general_usage
                fi
                target_vm=$3
		check_vm_existance $target_vm
		if [ $? -ne 1 ]; then
			echo "VM: $target_vm nao existe ou nao faz parte do cenario $cen_to_operate"
			exit 1
		fi
		echo "VM name: $target_vm"
		echo -n "IP: "
		get_vm_ip $target_vm
		echo -n "Link: "
		get_vm_link $target_vm
		echo "Username: daniel"
		echo "Password: 2fb438eg"
        ;;
	chaddr)
                if [ $arg_num -ne 5 ]; then
                        general_usage
                fi
                target_vm=$3
		target_ip=$4
		target_mask=$5
		validate_ipaddr $target_ip
		if [ $? -ne 0 ]; then
			echo "IP invalido."
			exit 1
		fi
		if [[ $target_mask =~ "^[0-9]+$" ]]; then
			echo "A mascara de rede de ser numerica e em bits [1-32]."
			exit 1
		fi
		if [ $target_mask -gt 32 ] || [ $target_mask -lt 1 ]; then
			echo "A mascara de rede deve ser entre 1 e 32"
			exit 1
		fi
                check_vm_existance $target_vm
                if [ $? -ne 1 ]; then
                        echo "VM: $target_vm nao existe ou nao faz parte do cenario $cen_to_operate"
                        exit 1
                fi
		change_vm_ip $target_vm $target_ip $target_mask
		if [ $? -ne 1 ]; then
                        echo "Erro ao definir IP: $target_ip/$target_mask na VM: $target_vm"
                        exit 1
                fi
		
	;;
	list)
		list_vms $cenario
		exit 0
	;;
	*)
		general_usage
	;;
esac
