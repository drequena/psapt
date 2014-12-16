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
check_bridge_existance(){
	bridges_file="$run_dir/bridges"
	local brg=$1
	$GREP -qs ^$brg: $bridges_file
	if [ $? -eq 0 ]; then
                return 1
        else
                return 0
        fi
}
get_bridge_links(){
	local brg=$1
#	bridges_file="$run_dir/bridges"
#	brg_links=($($GREP ^$brg $bridges_file| $TR ":" " "))
#	echo ${brg_links[@]:2}
	echo $($DLADM show-bridge -l $brg -p -o link,state)
}
get_root-bridge_id(){
	local brg=$1
	echo $($DLADM show-bridge -p -o DESROOT $brg)
}
get_bridge_id(){
	local brg=$1
	echo $($DLADM show-bridge -p -o address $brg)
}
get_bridge_priority(){
	local brg=$1
	echo $($DLADM  show-bridge -p -o priority $brg)
}
change_bridge_priority(){
	bridges_file="$run_dir/bridges"
	local brg=$1
	local prio=$2
	
	echo "Alterando prioridade da bridge $brg para $prio" >> $run_dir/$LOG_FILE
	$DLADM modify-bridge -p $prio $brg &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
		echo "Criando arquivo temporario de bridges: $bridges_file" >> $run_dir/$LOG_FILE
		cat $bridges_file | $SED s/^$brg:[0-9]*/$brg:$prio/ > $bridges_file".tmp"
		echo "Renomeando arquivo temporario para $bridges_file" >> $run_dir/$LOG_FILE
		mv $bridges_file".tmp" $bridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
                return 0
        fi
}
check_link_existance(){
        links_file="$run_dir/links"
        $GREP -qs ^$1 $links_file
        if [ $? -eq 0 ]; then
                return 1
        else
                return 0
        fi
}
is_link_connected(){
        local lnk=$1
        local bridges_file="$run_dir/bridges"
        local rbridges_file="$run_dir/rbridges"
        $GREP -qs $lnk $bridges_file &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
                return 1
        else
                $GREP -qs $lnk $rbridges_file &>> $run_dir/$LOG_FILE
                if [ $? -eq 0 ]; then
                        return 1
                else
                        return 0
                fi
        fi
}
connect_link_to_bridge(){
	local brg=$1
	local lnk=$2
	bridges_file="$run_dir/bridges"
	echo "Conectando link: $lnk aa bridge: $brg" >> $run_dir/$LOG_FILE
	dladm add-bridge -l $lnk $brg &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
                echo "Criando arquivo temporario de bridges: $bridges_file" >> $run_dir/$LOG_FILE
                cat $bridges_file | $SED s/^$brg:[0-9]*/\&:$lnk/ > $bridges_file".tmp"
		echo "Conteudo do arquivo temporario" >> $run_dir/$LOG_FILE
		cat $bridges_file".tmp" >> $run_dir/$LOG_FILE
		echo "-----------" >> $run_dir/$LOG_FILE
                echo "Renomeando arquivo temporario para $bridges_file" >> $run_dir/$LOG_FILE
                mv $bridges_file".tmp" $bridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
                return 0
        fi
}
is_link_connected_to_brg(){
	local brg=$1
	local lnk=$2
	bridges_file="$run_dir/bridges"
	$GREP ^$brg $bridges_file | $GREP -qs $lnk
        if [ $? -eq 0 ]; then
                return 1
        else
                return 0
        fi
}
disconnect_link_from_bridge(){
	local brg=$1
	local lnk=$2
	bridges_file="$run_dir/bridges"
	echo "Desconectando link: $lnk da bridge: $brg" >> $run_dir/$LOG_FILE
	$DLADM remove-bridge -l $lnk $brg &>> $run_dir/$LOG_FILE
        if [ $? -eq 0 ]; then
		echo "Checando se link $lnk eh o ultimo da linha" >> $run_dir/$LOG_FILE
		$GREP -qs $lnk$ $bridges_file
		if [ $? -eq 0 ]; then
			echo "Eh sim" >> $run_dir/$LOG_FILE
	                echo "Criando arquivo temporario de bridges: $bridges_file.tmp" >> $run_dir/$LOG_FILE
			cat $bridges_file | $SED s/:$lnk/""/ > $bridges_file".tmp"
		else
			echo "Nao, nao eh" >> $run_dir/$LOG_FILE
			echo "Criando arquivo temporario de bridges: $bridges_file.tmp" >> $run_dir/$LOG_FILE
			cat $bridges_file | $SED s/$lnk:*/""/ > $bridges_file".tmp"
		fi
                echo "Conteudo do arquivo temporario" >> $run_dir/$LOG_FILE
                cat $bridges_file".tmp" >> $run_dir/$LOG_FILE
                echo "-----------" >> $run_dir/$LOG_FILE
                echo "Renomeando arquivo temporario para $bridges_file" >> $run_dir/$LOG_FILE
                mv $bridges_file".tmp" $bridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
                return 0
        fi
}
is_link_alone(){
	local brg=$1
	local lnk=$2
	bridges_file="$run_dir/bridges"
	$GREP -qs ^$brg:[0-9]*:$lnk$ $bridges_file
        if [ $? -eq 0 ]; then
                return 1
        else
                return 0
        fi
}
upgrade_bridge(){
	local brg=$1
	bridges_file="$run_dir/bridges"
	rbridges_file="$run_dir/rbridges"
	echo "Transformando bridge: $brg em uma Rbridge" >> $run_dir/$LOG_FILE
	$DLADM modify-bridge -P trill $brg &>> $run_dir/$LOG_FILE
	if [ $? -eq 0 ]; then
		echo "Preparando arquivo temporario de bridges" >> $run_dir/$LOG_FILE
		$GREP -v ^$brg $bridges_file > $bridges_file".temp"
		echo "Conteudo de $bridges_file.temp" >> $run_dir/$LOG_FILE
		cat $bridges_file".temp" >> $run_dir/$LOG_FILE
		echo "Preparando arquivo temporario de Rbridges" >> $run_dir/$LOG_FILE
		$GREP ^$brg $bridges_file | $SED s/^$brg:[0-9]*/$brg/ > $rbridges_file".temp"
		echo "Conteudo de $rbridges_file.temp" >> $run_dir/$LOG_FILE
		cat $rbridges_file".temp" >> $run_dir/$LOG_FILE
		echo "Movendo conteudo de $rbridge_file.temp para $rbridge_file" >> $run_dir/$LOG_FILE
		cat $rbridges_file".temp" >> $rbridges_file
		echo "Removendo arquivo temporario $rbridges_file.temp" >> $run_dir/$LOG_FILE
		rm  $rbridges_file".temp" &>> $run_dir/$LOG_FILE
		echo "Movendo $bridges_file.temp para $bridges_file" >> $run_dir/$LOG_FILE
                mv $bridges_file".temp" $bridges_file &>> $run_dir/$LOG_FILE
                return 1
        else
		echo "Erro ao transformar $brg em Rbridge" >> $run_dir/$LOG_FILE
                return 0
        fi
}
