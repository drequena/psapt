#!/bin/bash
PSAPT_DIR="/opt/psapt"
BIN_DIR="$PSAPT_DIR/bin"
SPECIAL_BIN_DIR="$BIN_DIR/special_commands"
CEN_DIR="$PSAPT_DIR/cenarios"
arg_num=$#
if [ $arg_num -lt 2 ]; then
        echo "usage: bridge <cenario> [<comando>|?]"
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
. $BIN_DIR/bridge_functions.sh
get_cen_status $cen_to_operate
if [ $? -eq 0 ]; then
   echo "Cenario nao executando..."
   exit 1
fi
general_usage(){
        echo -e "Uso:
comandos:
info <bridge> - traz informacoes como: links conectados, bridge_id ,root-bridge_id e prioridade
connect <bridge> <link> - conecta <link> a bridge
disconnect <bridge> <link> - desconecta <link> da bridge
upgrade <bridge> - transforma <bridge> em Rbridge (TRILL)
priority_change <bridge> <priority (0-61440)> - altera a prioridade da <bridge>
"
        exit 0
}
case "$command" in
        add )
                echo "Comando ainda nao implementado."
        ;;
        del )
                echo "Comando ainda nao implementado."
        ;;
	info )
		if [ $arg_num -ne 3 ]; then
                        general_usage
                fi
		target_bridge=$3
		check_bridge_existance $target_bridge
		if [ $? -ne 1 ]; then
                        echo "$target_bridge nao eh uma bridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		echo -n "$target_bridge BID: "
		get_bridge_id $target_bridge
		echo -n "$target_bridge Priority: "
		get_bridge_priority $target_bridge
		echo -n "Links conectados a bridge $target_bridge: "
		get_bridge_links $target_bridge
		echo -n "Root-Bridge ID: "
		get_root-bridge_id $target_bridge
	;;
	connect )
                if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
		target_bridge=$3
		target_link=$4
                check_bridge_existance $target_bridge
                if [ $? -ne 1 ]; then
                        echo "$target_bridge nao eh uma bridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		check_link_existance $target_link
		if [ $? -ne 1 ]; then
                        echo "$target_link nao eh uma link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		is_link_connected $target_link
                if [ $? -ne 0 ]; then
                        echo "Erro! $target_link ja se encontra conectado a outra bridge/Rbridge ou a propria $target_bridge"
                        exit 1
                fi
		connect_link_to_bridge $target_bridge $target_link
                if [ $? -ne 1 ]; then
                        echo "Erro ao conectar $target_link a $target_bridge"
                        exit 1
                fi
	;;
	disconnect )
                if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
                target_bridge=$3
                target_link=$4
                check_bridge_existance $target_bridge
                if [ $? -ne 1 ]; then
                        echo "$target_bridge nao eh uma bridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
                check_link_existance $target_link
                if [ $? -ne 1 ]; then
                        echo "$target_link nao eh uma link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
                is_link_connected_to_brg $target_bridge $target_link
                if [ $? -ne 1 ]; then
                        echo "Erro! $target_link nao esta conectado a bridge $target_bridge"
                        exit 1
                fi
		is_link_alone $target_bridge $target_link
		if [ $? -ne 0 ]; then
                        echo "Erro! $target_link eh o unico link de $target_bridge e nao pode ser desconectado."
                        exit 1
                fi
	
                disconnect_link_from_bridge $target_bridge $target_link
                if [ $? -ne 1 ]; then
                        echo "Erro ao conectar $target_link a $target_bridge"
                        exit 1
                fi
	;;
	upgrade )
                if [ $arg_num -ne 3 ]; then
                        general_usage
                fi
                target_bridge=$3
                check_bridge_existance $target_bridge
                if [ $? -ne 1 ]; then
                        echo "$target_bridge nao eh uma bridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		upgrade_bridge $target_bridge
                if [ $? -ne 1 ]; then
                        echo "Erro ao fazer upgrade da bridge: $target_bridge para uma Rbridge(TRill)"
                        exit 1
                fi
	
	;;
	priority_change )
		if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
                target_bridge=$3
		new_priority=$4
		if ! [ $new_priority -ge 0 -a $new_priority -le 61440 ]; then
			echo "A prioridade deve estar entre 0 e 61440."
			exit 1
		fi
                check_bridge_existance $target_bridge
                if [ $? -ne 1 ]; then
                        echo "$target_bridge nao eh uma bridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		change_bridge_priority $target_bridge $new_priority
		if [ $? -ne 1 ]; then
                        echo "Erro ao setar prioridade: $new_priority em $target_bridge "
                        exit 1
                else
			echo "Prioridade alterada."
		fi
	;;
	* )
		general_usage
	;;
esac
