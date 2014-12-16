#!/bin/bash
PSAPT_DIR="/opt/psapt"
BIN_DIR="$PSAPT_DIR/bin"
SPECIAL_BIN_DIR="$BIN_DIR/special_commands"
CEN_DIR="$PSAPT_DIR/cenarios"
TRILL_CONF_DIR="$PSAPT_DIR/trill/rbridges"
arg_num=$#
if [ $arg_num -lt 2 ]; then
        echo "usage: rbridge <cenario> [<comando>|?]"
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
. $BIN_DIR/rbridge_functions.sh
get_cen_status $cen_to_operate
#if [ $? -eq 0 ]; then
#   echo "Cenario nao executando..."
#   exit 1
#fi
general_usage(){
        echo -e "Uso:
comandos:
info <rbridge> - traz informacoes como: links conectados, Nickname, next-hop, modo, ip, porta, senhas.
connect <rbridge> <link> - conecta <link> a bridge
disconnect <rbridge> <link> - desconecta <link> da bridge
downgrade <rbridge> - transforma Rbridge em bridge (Rstp)
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
		target_rbridge=$3
		check_rbridge_existance $target_rbridge
		if [ $? -ne 1 ]; then
                        echo "$target_rbridge nao eh uma Rbridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		echo -n "$target_rbridge Nickname: "
		get_rbridge_id $target_rbridge
		echo -n "Links conectados a Rbridge $target_rbridge: "
		get_rbridge_links $target_rbridge
		echo -n "Next-Hop MAC: "
		get_nexthop_mac $target_rbridge
		echo -n "Rbridge mode: "
		get_rbridge_mode $target_rbridge
		get_rbridge_info $target_rbridge
	;;
	connect )
                if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
		target_rbridge=$3
		target_link=$4
                check_rbridge_existance $target_rbridge
                if [ $? -ne 1 ]; then
                        echo "$target_rbridge nao eh uma Rbridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		check_link_existance $target_link
		if [ $? -ne 1 ]; then
                        echo "$target_link nao eh uma link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		is_link_connected $target_link
                if [ $? -ne 0 ]; then
                        echo "Erro! $target_link ja se encontra conectado a outra bridge/Rbridge ou a propria $target_rbridge"
                        exit 1
                fi
		connect_link_to_rbridge $target_rbridge $target_link
                if [ $? -ne 1 ]; then
                        echo "Erro ao conectar $target_link a $target_rbridge"
                        exit 1
                fi
	;;
	disconnect )
                if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
                target_rbridge=$3
                target_link=$4
                check_rbridge_existance $target_rbridge
                if [ $? -ne 1 ]; then
                        echo "$target_rbridge nao eh uma Rbridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
                check_link_existance $target_link
                if [ $? -ne 1 ]; then
                        echo "$target_link nao eh uma link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
                is_link_connected_to_rbrg $target_rbridge $target_link
                if [ $? -ne 1 ]; then
                        echo "Erro! $target_link nao esta conectado a Rbridge $target_rbridge"
                        exit 1
                fi
		is_link_alone $target_rbridge $target_link
		if [ $? -ne 0 ]; then
                        echo "Erro! $target_link eh o unico link de $target_rbridge e nao pode ser desconectado."
                        exit 1
                fi
	
                disconnect_link_from_rbridge $target_rbridge $target_link
                if [ $? -ne 1 ]; then
                        echo "Erro ao conectar $target_link a $target_rbridge"
                        exit 1
                fi
	;;
	downgrade )
                if [ $arg_num -ne 3 ]; then
                        general_usage
                fi
		
                target_rbridge=$3
		
                check_rbridge_existance $target_rbridge
		
                if [ $? -ne 1 ]; then
                        echo "$target_rbridge nao eh uma Rbridge existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		
		downgrade_rbridge $target_rbridge
		
                if [ $? -ne 1 ]; then
                        echo "Erro ao fazer downgrade da Rbridge: $target_rbridge para uma bridge(Rstp)"
                        exit 1
                fi
	;;
	* )
		general_usage
	;;
esac
