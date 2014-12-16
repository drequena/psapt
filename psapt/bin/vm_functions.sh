DLADM="/usr/sbin/dladm"
CP="/usr/bin/cp"
RM="/usr/bin/rm"
GREP="/usr/xpg4/bin/grep"
LOG_FILE="log"
DATE="/usr/bin/date"
KILL="/usr/bin/kill"
TR="/usr/bin/tr"
SED="/usr/bin/sed"
ZONE_ADM="/usr/sbin/zoneadm"
ZONE_CFG="/usr/sbin/zonecfg"
ZLOGIN="/usr/sbin/zlogin"
IPADM="/usr/sbin/ipadm"
get_cen_status(){
        cenario_status="$1.started"
        echo "Checando status do cenario $1" >> $run_dir/$LOG_FILE
        if [ -e "$run_dir/$cenario_status" ]; then
                return 1
        else
                return 0
        fi
}
check_vm_existance(){
	local vm_name=$1
	local vms_file="$run_dir/vms"
	echo "Checando a existencia da VM $vm_name" >> $run_dir/$LOG_FILE
	$GREP -q ^$vm_name $vms_file &>> $run_dir/$LOG_FILE
	if [ $? -eq 0 ];then
		echo "Existe" >> $run_dir/$LOG_FILE
		return 1
	else
		echo "Nao existe" >> $run_dir/$LOG_FILE
		return 0
	fi
}
get_vm_link(){
        local vm=$1
        echo $($ZONE_CFG -z $vm info net | grep physical |cut -d : -f 2| tr -d " ")
}
get_vm_ip(){
	local vm_name=$1
	local vm_link=$(get_vm_link $vm_name)
	local IPaddr
	IPaddr=$($ZLOGIN $vm_name ipadm show-addr "$vm_link/v4" -p -o addr 2>> /dev/null)
	if [ $? -eq 0 ]; then
		echo $IPaddr
	else
		echo "Nao ha IP definido."
	fi
}
validate_ipaddr(){
    local  ip=$1
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
change_vm_ip(){
	local vm_name=$1
	local ip=$2
	local mask=$3
	local vm_link=$(get_vm_link $vm_name)	
	
	echo "Checando se VM: $vm_name tem IP definido" >> $run_dir/$LOG_FILE
	IPaddr=$($ZLOGIN $vm_name ipadm show-addr "$vm_link/v4" -p -o addr 2>> /dev/null)
	
	if [ $? -ne 0 ]; then
		echo "VM: $vm_name nao tinha IP definido, definindo novo IP agora" >> $run_dir/$LOG_FILE
		$ZLOGIN $vm_name ipadm create-addr -T static -a "$ip/$mask" "$vm_link/v4" &>> $run_dir/$LOG_FILE
		if [ $? -ne 0 ]; then
			echo "Erro ai definir IP: $ip na VM: $vm_name no Link: $vm_link" >> $run_dir/$LOG_FILE
			return 0
		else
			echo "IP definido com sucesso." >> $run_dir/$LOG_FILE
			commit_vm_ip_change $vm_name $ip
			return 1
		fi
	else
		echo "Apagando antigo endereco IP do link: $vm_link  da VM: $vm_name" >> $run_dir/$LOG_FILE	
		$ZLOGIN $vm_name ipadm delete-addr "$vm_link/v4" &>> $run_dir/$LOG_FILE
		if [ $? -ne 0 ]; then
			echo "Erro ao remover IP" >> $run_dir/$LOG_FILE
			echo "Erro ao remover antigo IP"
			return 0
		else
			echo "Definindo novo IP" >> $run_dir/$LOG_FILE
			
                	$ZLOGIN $vm_name ipadm create-addr -T static -a "$ip/$mask" "$vm_link/v4" &>> $run_dir/$LOG_FILE
	                if [ $? -ne 0 ]; then
	                        echo "Erro ai definir IP: $ip na VM: $vm_name no Link: $vm_link" >> $run_dir/$LOG_FILE
  	                      	return 0
     	  	        else
    	                    	echo "IP definido com sucesso." >> $run_dir/$LOG_FILE
				commit_vm_ip_change $vm_name $ip
    	                    	return 1
     	           	fi
		fi
	fi
}
commit_vm_ip_change(){
	local vm_name=$1
	local ip=$2
	local vms_file="$run_dir/vms"
	local tmp_vms_file="$vms_file.tmp"
	echo "Function call: commit_vm_ip_change $vm_name $ip" >> $run_dir/$LOG_FILE
	echo "Gerando arquivo temporario $tmp_vms_file" >> $run_dir/$LOG_FILE
	$GREP -v ^$vm_name $vms_file > $tmp_vms_file
	echo "$vm_name:$ip" >> $tmp_vms_file
	echo "Conteudo do arquivo: " >> $run_dir/$LOG_FILE
	cat $tmp_vms_file >> $run_dir/$LOG_FILE
	echo "Movendo $tmp_vms_file para $vms_file" >> $run_dir/$LOG_FILE
	mv $tmp_vms_file $vms_file &>> $run_dir/$LOG_FILE
}
list_vms(){
	local vms_file="$run_dir/vms"
	local vm_name
                if [ -s $vms_file ]; then
                        for vm_name in $(cat $vms_file| cut -d ":" -f 1); do
                                echo "VM: $vm_name"
                        done
                        return 0
                else
                        echo "Nao existem VMs sendo utilizadas nesse cenario."
                        return 1
                fi
}
