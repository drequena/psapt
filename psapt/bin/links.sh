#!/bin/bash
PSAPT_DIR="/opt/psapt"
BIN_DIR="$PSAPT_DIR/bin"
SPECIAL_BIN_DIR="$BIN_DIR/special_commands"
CEN_DIR="$PSAPT_DIR/cenarios"
arg_num=$#
if [ $arg_num -lt 2 ]; then
	echo "usage: links <cenario> [<comando>|?]"
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
. $BIN_DIR/links_functions.sh
get_cen_status $cen_to_operate
#if [ $? -eq 0 ]; then
#   echo "Cenario nao executando..."
#   exit 1
#fi
general_usage(){
	echo -e "Uso:
comandos:
connect <link1> <link2> - conecta link1 ao link2 do cenario
disconnect <link1> <link2> - desconecta link1 de link2 do cenario
capture-start <link> [file|pipe] - inicia captura do link para um arquivo ou datapipe
capture-stop <link> - para a captura do link
info <link> - mostra informacoes sobre link
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
	connect )
                if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
                link1=$3
                link2=$4
                check_link_exists $link1
                if [ $? -ne 1 ]; then
                        echo "$link1 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
                check_link_exists $link2
                if [ $? -ne 1 ]; then
                        echo "$link2 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		check_is_link_connected $link1
                if [ $? -ne 0 ]; then
                        echo "$link1 ja esta conectado a outro link."
                        exit 1
                fi
                check_is_link_connected $link2
                if [ $? -ne 0 ]; then
                        echo "$link2 ja esta conectado a outro link."
                        exit 1
                fi
		connect_links $link1 $link2
                if [ $? -ne 1 ]; then
                        echo "Erro ao conectar $link1 e $link2."
                        exit 1
                else
                        echo "Links conectados."
                fi
	;;
	disconnect )
	
		if [ $arg_num -ne 4 ]; then
			general_usage
		fi
		link1=$3
		link2=$4
		check_link_exists $link1
		
		if [ $? -ne 1 ]; then
			echo "$link1 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
			exit 1
		fi
		check_link_exists $link2
		if [ $? -ne 1 ]; then
			echo "$link2 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
			exit 1
		fi
		
		check_links_connections $link1 $link2
		if [ $? -ne 1 ]; then
			echo "$link1 e $link2 nao estao conectados entre si."
			exit 1
		fi
		disconnect_links $link1 $link2
		if [ $? -ne 1 ]; then
			echo "Erro ao desconectar $link1 e $link2."
			exit 1
		else
			echo "Links desconectados."
		fi
	;;
	capture-start )
                if [ $arg_num -ne 4 ]; then
                        general_usage
                fi
                link1=$3
                capture_type=$4
                check_link_exists $link1
                if [ $? -ne 1 ]; then
                        echo "$link1 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		if [ $capture_type == "file" ]; then
			check_capture_status $link1
			if [ $? -ne 0 ]; then
                        	echo "$link1 ja esta sendo capturado."
                        	exit 1
                	else
				$SPECIAL_BIN_DIR/capture.sh $cen_to_operate $link1 &>> /dev/null
				
				if [ $? -ne 1 ]; then
					echo "Erro ao capturar $link1"
					exit 1
				else
					echo "Capturando link $link1 iniciada."
				fi
			fi
		else
			echo "Apenas captura do tipo file implementada por enquanto..."
			exit 1
		fi
	;;
	capture-stop )
                if [ $arg_num -ne 3 ]; then
                        general_usage
                fi
                link1=$3
                check_link_exists $link1
                if [ $? -ne 1 ]; then
                        echo "$link1 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
                check_capture_status $link1
                if [ $? -ne 1 ]; then
                	echo "$link1 nao esta sendo capturado."
                        exit 1
                else
			stop_link_capture $link1
			
                        if [ $? -ne 1 ]; then
                        	echo "Erro ao parar captura do link $link1"
                                exit 1
                        else
                               	echo "Captura de $link1 parada com sucesso."
                        fi
                fi
	;;
	info)
                if [ $arg_num -ne 3 ]; then
                        general_usage
                fi
                link1=$3
                check_link_exists $link1
                if [ $? -ne 1 ]; then
                        echo "$link1 nao eh um link existente ou nao pertence ao cenario $cen_to_operate"
                        exit 1
                fi
		echo "$link1 info:"
		echo -n "MAC Address: "
		get_link_mac $link1
		echo -n "Connected to link: "
		get_link_link $link1
		echo -n "Connected to device: "
		get_link_device $link1
	;;
	* )
		general_usage
	;;
esac
