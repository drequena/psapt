#
# Funcoes comuns aos comandos de interacao
# com os cenarios do PSATP
#
DLADM="/usr/sbin/dladm"
CP="/usr/bin/cp"
RM="/usr/bin/rm"
GREP="/usr/xpg4/bin/grep"
TCPDUMP="/usr/sbin/tcpdump"
LOG_FILE="log"
CAPTURE_DIR="/tmp/pub/psatp"
DATE="/usr/bin/date"
KILL="/usr/bin/kill"
get_cen_status(){
        cenario_status="$1.started"
        echo "Checando status do cenario $1" >> $run_dir/$LOG_FILE
        if [ -e "$run_dir/$cenario_status" ]; then
                return 1
        else
                return 0
        fi
}
check_link_exists(){
	links_file="$run_dir/links"
	$GREP -qs ^$1 $links_file
	if [ $? -eq 0 ]; then
		return 1
	else
		return 0
	fi	
}
check_links_connections(){
	links_connections_file="$run_dir/links_connections"
	$GREP -Eq "$1:$2|$2:$1" $links_connections_file
	if [ $? -eq 0 ]; then
		return 1
	else
		return 0
	fi
}
disconnect_links(){
	links_connections_file="$run_dir/links_connections"
	disconn_link1=$1
	disconn_link2=$2
	##echo "Desconectando $disconn_link1 de $disconn_link2" >> $run_dir/$LOG_FILE
	##$DLADM modify-simnet -p none $disconn_link1 &>> $run_dir/$LOG_FILE
	$DLADM modify-simnet -p none $disconn_link1
	if [ $? -eq 0 ]; then
		##echo "Preparando arquivo temporario $links_connections_file" >> $run_dir/$LOG_FILE
		$GREP -Ev "$disconn_link1:$disconn_link2|$disconn_link2:$disconn_link1" $links_connections_file > $links_connections_file".tmp"
		##echo "Movendo arquivo temporario $links_connections_file" >> $run_dir/$LOG_FILE
		mv $links_connections_file".tmp" $links_connections_file
		return 1
	else
		return 0
	fi
}
check_is_link_connected(){
	is_connected=$1
	links_connections_file="$run_dir/links_connections"
	##echo "Procurando por $is_connected em $links_connections_file"  >> $run_dir/$LOG_FILE
	$GREP -Eq "$is_connected" $links_connections_file
        if [ $? -eq 0 ]; then
		##echo "$is_connected encontrado." >> $run_dir/$LOG_FILE
                return 1
        else
		##echo "$is_connected nao encontrado." >> $run_dir/$LOG_FILE
                return 0
        fi
}
connect_links(){
	conn_link1=$1
	conn_link2=$2
	links_connections_file="$run_dir/links_connections"
	##echo "Conectando $conn_link1 e $conn_link2" >> $run_dir/$LOG_FILE
        ##$DLADM modify-simnet -p $conn_link1 $conn_link2 &>> $run_dir/$LOG_FILE
        $DLADM modify-simnet -p $conn_link1 $conn_link2
        if [ $? -eq 0 ]; then
                ##echo "Escrevendo $conn_link1:$conn_link2 em $links_connections_file" >> $run_dir/$LOG_FILE
                echo "$conn_link1:$conn_link2" >> $links_connections_file
                return 1
        else
                return 0
        fi
}
check_capture_status(){
	link_cap_stat=$1
	cap_stat_file="$run_dir/$link_cap_stat.run"
	##echo "Checando por $cap_stat_file em $run_dir" >> $run_dir/$LOG_FILE
	if [ -e $cap_stat_file ]; then
		##echo "$cap_stat_file encontrado, captura ja em andamento." >> $run_dir/$LOG_FILE
		return 1
	else
		##echo "$cap_stat_file nao encontrado." >> $run_dir/$LOG_FILE
		return 0
	fi
}
capture_link(){
	link_capture=$1
	echo "capture_link: Checando existencia do diretorio $CAPTURE_DIR" >> $run_dir/$LOG_FILE
	if [ ! -d $CAPTURE_DIR ]; then
                echo "$CAPTURE_DIR nao existe, criando..." >> $run_dir/$LOG_FILE
                mkdir -p $CAPTURE_DIR
	fi
	echo "Criando arquivo $link_capture.run" >> $run_dir/$LOG_FILE
	touch  $run_dir/$link_capture".run"
	echo "Contorno: Criando arquivo $link_capture.run em run-run" >> $run_dir/$LOG_FILE
	touch  $run_dir/run/$link_capture".run"
	capture_prefix=$($DATE +%m-%d-%y-%H%M%S)
	capture_prefix="$capture_prefix.cap"
	CAPTURE_FILE_NAME="$CAPTURE_DIR/$link_capture-$capture_prefix"
	$TCPDUMP -i $link_capture -n -s 0 -w $CAPTURE_FILE_NAME &
	if [ $? -ne 0 ]; then
        	echo "Erro ao iniciar captura do link $link_capture" >> $run_dir/$LOG_FILE
        	echo "Erro ao iniciar captura do link $link_capture"
        	echo "Apagando arquivo $link_capture.run" >> $run_dir/$LOG_FILE
	        rm $run_dir/$link_capture".run"
        	echo "Contorno: Apagando arquivo $link_capture.run em run-run" >> $run_dir/$LOG_FILE
	        rm $run_dir/run/$link_capture".run"
       		return 0
	fi
	tcpdump_pid=$!
	echo "Processo de captura do link $link_capture iniciado com sucesso. Executando sob pid: $tcpdump_pid" >> $run_dir/$LOG_FILE
	echo $tcpdump_pid > $run_dir/$link_capture".run"
	echo $tcpdump_pid > $run_dir/run/$link_capture".run"
	return 1
	###/usr/bin/date +%m-%d-%y-%H%M%S
	### exemplo: 10-28-13-224301
	### $TCPDUMP -i rb1_t_p1 -n -s 0 -w /tmp/captura.raw
}
stop_link_capture(){
	stop_capture_link=$1
	echo "Stop_link_capture: Parando captura do link $stop_capture_link" >> $run_dir/$LOG_FILE
	pid_of_tcpdump=$(cat $run_dir/$stop_capture_link".run")
	echo "Enviando sinal para PID: $pid_of_tcpdump" >> $run_dir/$LOG_FILE
	$KILL $pid_of_tcpdump &>> $run_dir/$LOG_FILE
	if [ $? -ne 0 ]; then
		echo "Erro ao matar processo $pid_of_tcpdump" >> $run_dir/$LOG_FILE
		return 0
	else
		echo "Tcpdump de PID: $pid_of_tcpdump sinalizado com sucesso" >> $run_dir/$LOG_FILE
		echo "Contorno: Apagando arquivo de status run-run" >> $run_dir/$LOG_FILE
		
		rm $run_dir/run/$stop_capture_link".run" &>> $run_dir/$LOG_FILE
		echo "Apagando arquivo de status" >> $run_dir/$LOG_FILE
		rm $run_dir/$stop_capture_link".run" &>> $run_dir/$LOG_FILE
		if [ $? -ne 0 ]; then
			echo "Erro ao apagar arquivo $run_dir/$stop_capture_link.run" >> $run_dir/$LOG_FILE
			return 0
		fi
		return 1
	fi
}
get_link_mac(){
	local lnk_name=$1
	echo $($DLADM show-simnet $lnk_name -o macaddress -p)
}
get_link_link(){
	local lnk_name=$1
	local lnk_lnk
	lnk_lnk=$($DLADM show-simnet $lnk_name -o otherlink -p)
	if [ -z $lnk_lnk ];then
		echo "none"
	else
		echo $lnk_lnk
	fi
}
get_link_device(){
	local lnk_name=$1
	local device_name
	device_name=$($DLADM show-link -p -o link,class,over | $GREP -e phys -e bridge | $GREP $lnk_name | cut -d : -f 1)
	if [ -z $device_name ];then
                echo "none"
        else
                echo $device_name
        fi
}
