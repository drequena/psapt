#
# Funcoes comuns aos comandos de interacao
# com os cenarios do PSATP
#
DLADM="/usr/sbin/dladm"
CP="/usr/bin/cp"
RM="/usr/bin/rm"
GREP="/usr/xpg4/bin/grep"
LOG_FILE="log"
DATE="/usr/bin/date"
KILL="/usr/bin/kill"
TR="/usr/bin/tr"
SED="/usr/bin/sed"
get_cen_status(){
        cenario_status="$1.started"
        echo "Checando status do cenario $1" >> $run_dir/$LOG_FILE
        if [ -e "$run_dir/$cenario_status" ]; then
                return 1
        else
                return 0
        fi
}
check_rbridge_existance(){
	rbridges_file="$run_dir/rbridges"
	local rbrg=$1
	echo "Checando existencia da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	$GREP -qs ^$rbrg $rbridges_file
	if [ $? -eq 0 ]; then
		echo "Existe" >> $run_dir/$LOG_FILE
                return 1
        else
		echo "Nao existe" >> $run_dir/$LOG_FILE
                return 0
        fi
}
get_rbridge_links(){
	local rbrg=$1
	echo "Listando links da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	echo $($DLADM show-link -p -o link,class,over |$GREP bridge |$GREP ^$rbrg | $SED s/^$rbrg[0-9]*:bridge:/""/)
}
get_nexthop_mac(){
	local rbrg=$1
	
	echo "Listando nexthop da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	echo $($DLADM show-bridge -p -o nexthop -t $rbrg)
}
get_rbridge_id(){
	local rbrg=$1
	local rbridge_log_file="$TRILL_CONF_DIR/$rbrg/$rbrg.log"
	local nick
	
	echo "Listando nick da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	if [ -e $rbridge_log_file ]; then
		echo "Rbridge em modo debug, detectando nick pelo LOG" >> $run_dir/$LOG_FILE
		nick=$($GREP generated $rbridge_log_file| tail -1 | $SED s/.*nick:/""/)
		if [ -z $nick ]; then
			echo Definindo
		else
			echo $nick
		fi
	else
		nick=$($DLADM show-bridge -p -o nick,flags -t $rbrg | $GREP [0-9]*:L | cut -d ":" -f 1)
		echo "$nick (nao confiavel)"
	fi
}
get_rbridge_mode(){
	
	local rbrg=$1
	local rbridge_config_file="$TRILL_CONF_DIR/$rbrg/$rbrg.conf"
	echo "Checando modo de operacao da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	if [ -e $rbridge_config_file ]; then
		echo "Modo debug identificado" >> $run_dir/$LOG_FILE
		echo "debug"
	else
		echo "Modo standard identificado" >> $run_dir/$LOG_FILE
		echo "standard"
	fi
}
get_rbridge_info(){
	local rbrg=$1
	local rbridge_mode=$(get_rbridge_mode $rbrg)
	echo "Colhendo informacoes (debug) da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	if [ $rbridge_mode == "debug" ]; then
		rbridge_config_file="$TRILL_CONF_DIR/$rbrg/$rbrg.conf"
		rbridge_port_file="$TRILL_CONF_DIR/$rbrg/$rbrg.port"
		echo -e "\nDebug info: "
		$GREP -E '^hostname|^password|^enable' $rbridge_config_file
		echo -n "Port: "
		cat $rbridge_port_file
	fi
}
check_link_existance(){
	local lnk=$1
        links_file="$run_dir/links"
	echo "Verificando se o link $lnk existe" >> $run_dir/$LOG_FILE
        $GREP -qs ^$lnk $links_file
        if [ $? -eq 0 ]; then
		echo "Existe" >> $run_dir/$LOG_FILE
                return 1
        else
		echo "Nao existe" >> $run_dir/$LOG_FILE
                return 0
        fi
}
is_link_connected(){
	local lnk=$1
	local bridges_file="$run_dir/bridges"
	local rbridges_file="$run_dir/rbridges"
	echo "Checando se o link $lnk esta conectado a alguma bridge ou Rbridge" >> $run_dir/$LOG_FILE
	$GREP -qs $lnk $bridges_file &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
		echo "Esta conectado a uma bridge" >> $run_dir/$LOG_FILE
                return 1
        else
		$GREP -qs $lnk $rbridges_file &>> $run_dir/$LOG_FILE
		if [ $? -eq 0 ]; then
			echo "Esta conectado a uma Rbridge" >> $run_dir/$LOG_FILE
			return 1
		else
			echo "Nao esta conectado a nada" >> $run_dir/$LOG_FILE
			return 0
		fi
        fi
}
connect_link_to_rbridge(){
	local rbrg=$1
	local lnk=$2
	rbridges_file="$run_dir/rbridges"
	echo "Conectando link: $lnk aa Rbridge: $rbrg" >> $run_dir/$LOG_FILE
	dladm add-bridge -l $lnk $rbrg &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
                echo "Criando arquivo temporario de Rbridges: $rbridges_file" >> $run_dir/$LOG_FILE
                cat $rbridges_file | $SED s/^$rbrg/\&:$lnk/ > $rbridges_file".tmp"
		echo "Conteudo do arquivo temporario" >> $run_dir/$LOG_FILE
		cat $rbridges_file".tmp" >> $run_dir/$LOG_FILE
		echo "-----------" >> $run_dir/$LOG_FILE
                echo "Renomeando arquivo temporario para $rbridges_file" >> $run_dir/$LOG_FILE
                mv $rbridges_file".tmp" $rbridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
                return 0
        fi
}
is_link_connected_to_rbrg(){
	local rbrg=$1
	local lnk=$2
	rbridges_file="$run_dir/rbridges"
	
	echo "Checando se o link $lnk esta conectado a Rbridge $rbrg" >> $run_dir/$LOG_FILE
	$GREP ^$rbrg $rbridges_file | $GREP -qs $lnk
        if [ $? -eq 0 ]; then
		echo "Esta" >> $run_dir/$LOG_FILE
                return 1
        else
		echo "Nao esta" >> $run_dir/$LOG_FILE
                return 0
        fi
}
disconnect_link_from_rbridge(){
	local rbrg=$1
	local lnk=$2
	rbridges_file="$run_dir/rbridges"
	echo "Desconectando link: $lnk da Rbridge: $rbrg" >> $run_dir/$LOG_FILE
	$DLADM remove-bridge -l $lnk $rbrg &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
		echo "Checando se link $lnk eh o ultimo da linha" >> $run_dir/$LOG_FILE
		$GREP -qs $lnk$ $rbridges_file
		if [ $? -eq 0 ]; then
			echo "Eh sim" >> $run_dir/$LOG_FILE
	                echo "Criando arquivo temporario de Rbridges: $rbridges_file.tmp" >> $run_dir/$LOG_FILE
			cat $rbridges_file | $SED s/:$lnk/""/ > $rbridges_file".tmp"
		else
			echo "Nao, nao eh" >> $run_dir/$LOG_FILE
			echo "Criando arquivo temporario de Rbridges: $rbridges_file.tmp" >> $run_dir/$LOG_FILE
			cat $rbridges_file | $SED s/$lnk:*/""/ > $rbridges_file".tmp"
		fi
                echo "Conteudo do arquivo temporario" >> $run_dir/$LOG_FILE
                cat $rbridges_file".tmp" >> $run_dir/$LOG_FILE
                echo "-----------" >> $run_dir/$LOG_FILE
                echo "Renomeando arquivo temporario para $rbridges_file" >> $run_dir/$LOG_FILE
                mv $rbridges_file".tmp" $rbridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
                return 0
        fi
}
is_link_alone(){
	local rbrg=$1
	local lnk=$2
	rbridges_file="$run_dir/rbridges"
	echo "Checando se link $lnk eh o unico da Rbridge $rbrg" >> $run_dir/$LOG_FILE
	$GREP -qs ^$rbrg:$lnk$ $rbridges_file
        if [ $? -eq 0 ]; then
		echo "Eh o unico" >> $run_dir/$LOG_FILE
                return 1
        else
		echo "Nao eh o unico" >> $run_dir/$LOG_FILE
                return 0
        fi
}
downgrade_rbridge(){
	local rbrg=$1
	bridges_file="$run_dir/bridges"
	rbridges_file="$run_dir/rbridges"
	echo "Transformando Rbridge: $rbrg em uma bridge" >> $run_dir/$LOG_FILE
	$DLADM modify-bridge -P stp $rbrg &>> $run_dir/$LOG_FILE
	if [ $? -eq 0 ]; then
		echo "Preparando arquivo temporario de Rbridges" >> $run_dir/$LOG_FILE
		$GREP -v ^$rbrg $rbridges_file > $rbridges_file".temp"
		echo "Conteudo de $rbridges_file.temp" >> $run_dir/$LOG_FILE
		cat $rbridges_file".temp" >> $run_dir/$LOG_FILE
		echo "Preparando arquivo temporario de bridges" >> $run_dir/$LOG_FILE
		$GREP ^$rbrg $rbridges_file | $SED s/^$rbrg/\&:32768/ > $bridges_file".temp"
		echo "Conteudo de $bridges_file.temp" >> $run_dir/$LOG_FILE
		cat $bridges_file".temp" >> $run_dir/$LOG_FILE
		echo "Movendo conteudo de $bridges_file.temp para $bridge_file" >> $run_dir/$LOG_FILE
		cat $bridges_file".temp" >> $bridges_file
		echo "Removendo arquivo temporario $bridges_file.temp" >> $run_dir/$LOG_FILE
		rm  $bridges_file".temp" &>> $run_dir/$LOG_FILE
		echo "Movendo $rbridges_file.temp para $rbridges_file" >> $run_dir/$LOG_FILE
                mv $rbridges_file".temp" $rbridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
		echo "Erro ao transformar $rbrg em bridge" >> $run_dir/$LOG_FILE
                return 0
        fi
}
