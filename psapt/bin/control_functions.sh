#
# control_functions.sh
#
# Conjunto de funcoes utilizadas pelo script control.sh
# 
#
#
#
# Variaveis utilizadas ao longo de todas as funcoes.
#
DLADM="/usr/sbin/dladm"
DIFF="/usr/bin/diff"
CP="/usr/bin/cp"
RM="/usr/bin/rm"
LOG_FILE="log"
ZONE_ADM="/usr/sbin/zoneadm"
ZONE_CFG="/usr/sbin/zonecfg"
ZLOGIN="/usr/sbin/zlogin"
KILL="/usr/bin/kill"
is_unique(){
	if [ -f $UNIQUE_FILE ]; then
		return 0
	else
		return 1
	fi
}
#
# Checa se os arquivo necessarios para iniciar um cenario existem no diretorio
# recebido em arg1. Caso existam, retorna 0
# lista de arquivos no array sanity_files
#
check_cen_sanity(){
        cenario_dir=$1
        run_dir="$cenario_dir/run"
        sanity_files=(run bridges rbridges links links_connections)
        array_size=${#sanity_files[@]}
        ((array_size--))
        while [ $array_size -ge 0 ]; do
                test -a "$cenario_dir/${sanity_files[$array_size]}"
		if [ $? -ne 0 ]; then
			return 1
		else
			((array_size--))
		fi
        done
	return 0
}
check_vm_sanity(){
	local cenario_dir=$1
	local vm_files="$cenario_dir/vms"
	local vlan_file="$cenario_dir/vlans"
	local link_file="$cenario_dir/links"
	run_dir="$cenario_dir/run"
	local vm
	local vm_link
	echo "check_vm_sanity" >> $run_dir/$LOG_FILE
	if [ -s $vm_files ]; then
		echo "O cenario possui VMs, checando se elas sao registradas" >> $run_dir/$LOG_FILE
		for vm in $(cat $vm_files|cut -d : -f 1); do
			$ZONE_ADM -z $vm list &>> $run_dir/$LOG_FILE
			
			if [ $? -ne 0 ]; then
				echo "VM $vm nao registrada" >> $run_dir/$LOG_FILE
				echo "Erro! VM $vm referenciada no arquivo $vm_files nao existe."
				exit 1
			else
				echo "VM $vm registrada" >> $run_dir/$LOG_FILE
			fi
			echo "Checando link da VM $vm" >> $run_dir/$LOG_FILE
			
			vm_link=$(get_vm_link $vm)
			if [ -z $vm_link ]; then
				echo "Variavel vm_link retornou vazia, algo deu errado." >> $run_dir/$LOG_FILE
				echo "Erro ao estabelecer o link da VM $vm"
				exit 1
			else
				grep -q $vm_link $link_file
				if [ $? -ne 0 ]; then
					echo "link $vm_link nao encontrado em $link_file, procurando em $vlan_file" >> $run_dir/$LOG_FILE
					grep -q ^$vm_link $vlan_file 2> /dev/null
					retorno=$?
					if [ $retorno -ne 0 ]; then
						echo "Erro: link $vm_link da VM $vm nao consta no arquivo de link $link_file nem em $vlan_file" >> $run_dir/$LOG_FILE
						echo "Erro: link $vm_link da VM $vm nao consta no arquivo de link $link_file"
						exit 1
					else
						echo "link $vm_link achado em $vlan_file-> ok" >> $run_dir/$LOG_FILE
					fi
				else
					echo "link $vm_link -> ok" >> $run_dir/$LOG_FILE
				fi
			fi
		done
	else
		echo "Arquivo de VMs existe, porem esta vazio." >> $run_dir/$LOG_FILE
		return 0
	fi
}
get_vm_link(){
	local vm=$1
	echo $($ZONE_CFG -z $vm info net | grep physical |cut -d : -f 2| tr -d " ")
}
check_diff(){
	
	local i
	cenario_dir=$1
	run_dir="$cenario_dir/run"
	local vm_file="$cenario_dir/vms"
	if [ -e $vm_file ]; then
		check_file=(bridges rbridges links links_connections vms)
	else
		check_file=(bridges rbridges links links_connections)
	fi
	array_size=${#check_file[@]}
	((array_size--))
	
	while [ $array_size -ge 0 ]; do
		echo "Checando diferenca em arquivo $cenario_dir/${check_file[$array_size]}" >> $run_dir/$LOG_FILE
		$DIFF "$cenario_dir/${check_file[$array_size]}" "$run_dir/${check_file[$array_size]}" &>> $run_dir/$LOG_FILE
		if [ $? -ne 0 ]; then
			echo "Encontrada diferenca no arquivo $cenario_dir/${check_file[$array_size]}" >> $run_dir/$LOG_FILE
			return 1
		fi
	
		((array_size--))
	done
	return 0
}
copy_cen_files(){
        local i
        cenario_dir=$1
        run_dir="$cenario_dir/run"
        local vm_file="$cenario_dir/vms"
        local vlan_file="$cenario_dir/vlans"
        if [ -e $vm_file ]; then
                copy_files=(bridges rbridges links links_connections vms)
		 if [ -e $vlan_file ]; then
			copy_files=(bridges rbridges links links_connections vms vlans)
		 fi
        else
                copy_files=(bridges rbridges links links_connections)
        fi
        array_size=${#copy_files[@]}
        ((array_size--))
        while [ $array_size -ge 0 ]; do
                echo "Copiando arquivo $cenario_dir/${copy_files[$array_size]} para $run_dir" >> $run_dir/$LOG_FILE
                $CP "$cenario_dir/${copy_files[$array_size]}" "$run_dir/" &>> $run_dir/$LOG_FILE
                if [ $? -ne 0 ]; then
                        echo "Erro ao copiar  $cenario_dir/${copy_files[$array_size]} para $run_dir" >> $run_dir/$LOG_FILE
                        return 1
                fi
                ((array_size--))
        done
	return 0
}
delete_cen_files(){
        local i
        cenario_dir=$1
        run_dir="$cenario_dir/run"
        local vm_file="$cenario_dir/vms"
        local vlan_file="$cenario_dir/vlans"
        if [ -e $vm_file ]; then
                delete_files=(bridges rbridges links links_connections vms)
                 if [ -e $vlan_file ]; then
                        copy_files=(bridges rbridges links links_connections vms vlans)
                 fi
        else
                delete_files=(bridges rbridges links links_connections)
        fi
        array_size=${#delete_files[@]}
        ((array_size--))
        while [ $array_size -ge 0 ]; do
                echo "Deletando arquivo $run_dir/${delete_files[$array_size]}" >> $run_dir/$LOG_FILE
                $RM "$run_dir/${delete_files[$array_size]}" &>> $run_dir/$LOG_FILE
                if [ $? -ne 0 ]; then
                        echo "Erro ao deletar $run_dir/${delete_files[$array_size]}" >> $run_dir/$LOG_FILE
                        return 1
                fi
                ((array_size--))
        done
        return 0
}
get_cen_status(){
	cenario_status="$1.started"
	echo "Checando status do cenario $1" >> $run_dir/$LOG_FILE
	if [ -e "$run_dir/$cenario_status" ]; then
		return 1
	else
		return 0
	fi
}
ret_test(){
	ret=$1
	if [ $ret -eq 0 ]; then
		echo "Ok."
	else
		echo "Erro!"
		exit 1
	fi
}
start_links(){
	#
	# Criar os simnets contidos do arquivo de config. "links"
	#
	# Recebe o diretorio do cenario como arg 1 e 
	# roda em loop criando os simnet do arquivo "links" do diretorio.
	# Dando tudo certo, retorna 0.
	# Caso falhe no comando de criacao de algum simnet, apaga os ja
	# criados e retorna 1
	#
	local i
	cenario_dir=$1
	run_dir="$cenario_dir/run"
	#
	# Caso arquivo esteja vazio, retorne sem erro.
	#
	test -s $cenario_dir/links || return 0
	for i in $(cat $cenario_dir/links); do
		echo "Criando Simnet - $DLADM create-simnet $i" >> $run_dir/$LOG_FILE
		$DLADM create-simnet $i &>> $run_dir/$LOG_FILE
		if [ $? -ne 0 ]; then
			echo "Erro na criacao dos simnets"  >> $run_dir/$LOG_FILE
			test -e $run_dir/links.temp && stop_links $run_dir/links.temp || return 1
		else
			echo $i >> $run_dir/links.temp
		fi
	done
	echo "Apagando arquivo links temporario" >> $run_dir/$LOG_FILE
	rm $run_dir/links.temp &>> $run_dir/$LOG_FILE
	return 0
}
stop_links(){
	local i
	local w
	test -d $1 && run_normal=1 || run_normal=0
	if [ $run_normal -eq 1 ]; then
		cenario_dir=$1
		run_dir="$cenario_dir/run"
		test -s $cenario_dir/links || return 0
		echo "Testando por capturas em links nao paradas" >> $run_dir/$LOG_FILE
		ls $run_dir/*.run &>> $run_dir/$LOG_FILE
		if [ $? -ne 0 ]; then
			echo "Nenhuma captura em andamento." >> $run_dir/$LOG_FILE
		else
			echo "Capturas encontradas, matando processos..." >> $run_dir/$LOG_FILE
			for w in $(cat $run_dir/*.run); do
				echo "Matando processo $w" >> $run_dir/$LOG_FILE
				$KILL $w &>> $run_dir/$LOG_FILE
				if [ $? -ne 0 ]; then
					echo "Impossivel matar processo $w, teremos problemas" >> $run_dir/$LOG_FILE
				fi
			done
			
			echo "Contorno: Apagando todos os arquivo .run em run-run" >> $run_dir/$LOG_FILE
			rm -rf $run_dir/../*.run &>> $run_dir/$LOG_FILE
			echo "Apagando todos os arquivo .run" >> $run_dir/$LOG_FILE
			rm -rf $run_dir/*.run &>> $run_dir/$LOG_FILE
		fi
        	for i in $(cat $cenario_dir/links); do
                	echo "Deletando Simnet - $DLADM delete-simnet $i" >> $run_dir/$LOG_FILE
                	$DLADM delete-simnet $i &>> $run_dir/$LOG_FILE
                	if [ $? -ne 0 ]; then
				echo "Erro ao deletar simnet $i"  >> $run_dir/$LOG_FILE
                        	return 1
                	fi
        	done
		return 0	
	else
		cenario_file=$1
		test -s $cenario_file || return 0
                for i in $(cat $cenario_file); do
                        echo "Funcao Stop_links\(\) chamada por erro - $DLADM delete-simnet $i" >> $run_dir/$LOG_FILE
                        $DLADM delete-simnet $i &>> $run_dir/$LOG_FILE
                done
		echo "Apagando arquivo $cenario_file" >> $run_dir/$LOG_FILE
		rm $cenario_file &>> $run_dir/$LOG_FILE
		
                return 1
	fi
}
start_links_conn(){
	local i
        cenario_dir=$1
        run_dir="$cenario_dir/run"
	test -s $cenario_dir/links_connections || return 0
        for i in $(cat $cenario_dir/links_connections); do
		lnk1=$(echo $i | cut -d ":" -f 1)
		lnk2=$(echo $i | cut -d ":" -f 2)
                echo "Conectando Simnets - $DLADM modify-simnet -p $lnk1 $lnk2"  >> $run_dir/$LOG_FILE
                $DLADM modify-simnet -p $lnk1 $lnk2 &>> $run_dir/$LOG_FILE
                if [ $? -ne 0 ]; then
			echo "Erro ao conectar Simnets $lnk1 $lnk2" >> $run_dir/$LOG_FILE
                        test -e $run_dir/links_connections.temp && stop_links_conn $run_dir/links_connections.temp || return 1
                else
                        echo $i >> $run_dir/links_connections.temp
                fi
        done
	echo "Apagando links_connections temporario" >> $run_dir/$LOG_FILE
        rm $run_dir/links_connections.temp &>> $run_dir/$LOG_FILE
        return 0
}
stop_links_conn(){
	local i
	test -d $1 && run_normal=1 || run_normal=0
	if [ $run_normal -eq 1 ]; then
        	cenario_dir=$1
        	run_dir="$cenario_dir/run"
		test -s $cenario_dir/links_connections || return 0
       		for i in $(cat $cenario_dir/links_connections); do
                	lnk1=$(echo $i | cut -d ":" -f 1)
                	echo "Desconectando Simnets - $DLADM modify-simnet -p none $lnk1" >> $run_dir/$LOG_FILE
                	$DLADM modify-simnet -p none $lnk1 &>> $run_dir/$LOG_FILE
                	if [ $? -ne 0 ]; then
				echo "Erro ao desconectar Simnets $lnk1" >> $run_dir/$LOG_FILE
                        	return 1
                	fi
        	done
        	return 0
	else
                cenario_file=$1
		test -s $cenario_file || return 0
                for i in $(cat $cenario_file); do
                        lnk1=$(echo $i | cut -d ":" -f 1)
                        echo "Chamado por erro - $DLADM modify-simnet -p none $lnk1" >> $run_dir/$LOG_FILE
                        $DLADM modify-simnet -p none $lnk1 &>> $run_dir/$LOG_FILE
                done
		echo "Apagando arquivo $cenario_file" >> $run_dir/$LOG_FILE
                rm $cenario_file &>> $run_dir/$LOG_FILE
                return 1
	fi
}
start_bridges(){
	local i
	local j
        cenario_dir=$1
        run_dir="$cenario_dir/run"
	test -s $cenario_dir/bridges || return 0
	for i in $(cat $cenario_dir/bridges); do
		declare -a brg_prop
        	n=0
        	create_cmd="dladm create-bridge "
        	for j in $(echo $i| tr ":" " "); do
                	brg_prop[$n]=$j
                	((n++))
        	done
        	ultimo=${#brg_prop[@]}
        	((ultimo--))
        	while [ $ultimo -ge 0 ]; do
                	if [ $ultimo -eq 0 ]; then
                        	create_cmd="$create_cmd ${brg_prop[$ultimo]}"
                	elif [ $ultimo -eq 1 ]; then
                        	create_cmd="$create_cmd -p ${brg_prop[$ultimo]} "
                	else
                        	create_cmd="$create_cmd -l ${brg_prop[$ultimo]} "
                	fi
                	((ultimo--))
        	done
		echo "Criando Bridge com comando - $create_cmd" >> $run_dir/$LOG_FILE
        	$($create_cmd) &>> $run_dir/$LOG_FILE
		sleep 5
		
		if [ $? -ne 0 ]; then
			echo "Erro ao criar Bridge - $create_cmd" >> $run_dir/$LOG_FILE
                        test -e $run_dir/bridges.temp && stop_bridges $run_dir/bridges.temp || return 1
                else
                        echo $i >> $run_dir/bridges.temp
                fi
		unset brg_prop
	done
	echo "Apagando arquivo temporario bridges" >> $run_dir/$LOG_FILE
	rm $run_dir/bridges.temp &>> $run_dir/$LOG_FILE
	return 0
}
stop_bridges(){
	#
	# ATENCAO! Toda Bridge deve estar conectada pelo menos a um link
	#
	local i
	local j
	local cenario_local
	if [ -d $1 ]; then
		cenario_local=$1/bridges
		error=0
	else
		cenario_local=$1
		error=1
	fi
	test -s $cenario_local || return 0
	        for i in $(cat $cenario_local); do
			declare -a brg_prop
	                n=0
	                remove_cmd="$DLADM remove-bridge "
	                delete_cmd="$DLADM delete-bridge "
	
	                for j in $(echo $i| tr ":" " "); do
	                        brg_prop[$n]=$j
	                        ((n++))
	                done
	                ultimo=${#brg_prop[@]}
	                ((ultimo--))
	                while [ $ultimo -ge 0 ]; do
        	                if [ $ultimo -eq 0 ]; then
                	                remove_cmd="$remove_cmd ${brg_prop[$ultimo]}"
                	                delete_cmd="$delete_cmd ${brg_prop[$ultimo]}"
	                        elif [ $ultimo -gt 1 ]; then
					remove_cmd="$remove_cmd -l ${brg_prop[$ultimo]} "
	                        fi
        	                ((ultimo--))
	                done
        	        echo "Removendo links da Bridge com comando - $remove_cmd" >> $run_dir/$LOG_FILE
        	        $($remove_cmd) &>> $run_dir/$LOG_FILE
                        if [ $? -ne 0 ]; then
				echo "Erro ao remover links da Bridge - $remove_cmd" $run_dir/$LOG_FILE
                                return 1
                        fi
			echo "Removendo Bridge com comando - $delete_cmd" >> $run_dir/$LOG_FILE
			$($delete_cmd) &>> $run_dir/$LOG_FILE
	                if [ $? -ne 0 ]; then
	                        echo "Erro ao Remover Bridge com comando - $delete_cmd" >> $run_dir/$LOG_FILE
	                        return 1
	                fi
			unset brg_prop
	        done
		if [ $error -eq 1 ]; then
			return 1
		else
			return 0
		fi
}
start_Rbridges(){
        local i
        local j
	local create_cmd
        cenario_dir=$1
        run_dir="$cenario_dir/run"
	test -s $cenario_dir/rbridges || return 0
        for i in $(cat $cenario_dir/rbridges); do
	        declare -a rbrg_prop
                n=0
                create_cmd="dladm create-bridge -P trill"
                for j in $(echo $i| tr ":" " "); do
                        rbrg_prop[$n]=$j
                        ((n++))
                done
                ultimo=${#rbrg_prop[@]}
                ((ultimo--))
                while [ $ultimo -ge 0 ]; do
                        if [ $ultimo -eq 0 ]; then
                                create_cmd="$create_cmd ${rbrg_prop[$ultimo]}"
                        else
                                create_cmd="$create_cmd -l ${rbrg_prop[$ultimo]} "
                        fi
                        ((ultimo--))
                done
                echo "Criando RBridge com comando - $create_cmd" >> $run_dir/$LOG_FILE
                $($create_cmd) &>> $run_dir/$LOG_FILE
                if [ $? -ne 0 ]; then
                        echo "Erro ao criar RBridge - $create_cmd" >> $run_dir/$LOG_FILE
                        test -e $run_dir/rbridges.temp && stop_Rbridges $run_dir/rbridges.temp || return 1
                else
                        echo $i >> $run_dir/rbridges.temp
                fi
		
		unset rbrg_prop
        done
        echo "Apagando arquivo temporario rbridges" >> $run_dir/$LOG_FILE
        rm $run_dir/rbridges.temp &>> $run_dir/$LOG_FILE
        return 0
}
stop_Rbridges(){
	#
	# ATENCAO! Toda RBridge deve estar conectada pelo menos a um link
	#
        local i
        local j
        local cenario_local
        if [ -d $1 ]; then
                cenario_local=$1/rbridges
                error=0
        else
                cenario_local=$1
                error=1
        fi
	test -s $cenario_local || return 0
        for i in $(cat $cenario_local); do
                declare -a rbrg_prop
                n=0
                remove_cmd="dladm remove-bridge "
                delete_cmd="dladm delete-bridge "
                for j in $(echo $i| tr ":" " "); do
                        rbrg_prop[$n]=$j
                        ((n++))
                done
                ultimo=${#rbrg_prop[@]}
                ((ultimo--))
                while [ $ultimo -ge 0 ]; do
                        if [ $ultimo -eq 0 ]; then
                                remove_cmd="$remove_cmd ${rbrg_prop[$ultimo]}"
                                delete_cmd="$delete_cmd ${rbrg_prop[$ultimo]}"
                        else
                                remove_cmd="$remove_cmd -l ${rbrg_prop[$ultimo]} "
                        fi
                        ((ultimo--))
                done
                echo "Removendo links da RBridge com comando - $remove_cmd" >> $run_dir/$LOG_FILE
                $($remove_cmd) &>> $run_dir/$LOG_FILE
                if [ $? -ne 0 ]; then
                        echo "Erro ao remover links da RBridge - $remove_cmd" >> $run_dir/$LOG_FILE
			return 1
                fi
                echo "Deletando a RBridge com comando - $delete_cmd" >> $run_dir/$LOG_FILE
                $($delete_cmd) &>> $run_dir/$LOG_FILE
                if [ $? -ne 0 ]; then
                        echo "Erro ao deletar a RBridge - $delete_cmd" >> $run_dir/$LOG_FILE
			return 1
                fi
                unset rbrg_prop
        done
        if [ $error -eq 1 ]; then
	        echo "Apagando arquivo temporario rbridges" >> $run_dir/$LOG_FILE
	        rm $run_dir/rbridges.temp &>> $run_dir/$LOG_FILE
        	return 1
        else
                return 0
        fi
}
start_vms(){
        local i
        local k
        cenario_dir=$1
        run_dir="$cenario_dir/run"
        local vms_file="$cenario_dir/vms"
        local vlan_file="$cenario_dir/vlans"
        local vm
        local ipadr
        local vm_link
        local vlan_link
	local lnk_vlan
	local vlan_id
	local vlan_over
        if [ -s $vms_file ]; then
                for i in $(cat $vms_file); do
                        vm=${i%:*}
                        ipadr=${i#*:}
			vlan_link=$(get_vm_link $vm)
			grep -q ^$vlan_link: $vlan_file 2> /dev/null
			if [ $? -eq 0 ]; then
				echo "VM encontrada usando Vlan" >> $run_dir/$LOG_FILE
				echo "Criando Vlan" >> $run_dir/$LOG_FILE
				for k in $(grep ^$vlan_link: $vlan_file); do
					lnk_vlan=$(echo $k|tr : " "| awk '{print $1}')
					vlan_id=$(echo $k|tr : " "| awk '{print $2}')
					vlan_over=$(echo $k|tr : " "| awk '{print $3}')
				done
				echo "Executando: dladm create-vlan -l $vlan_over -v $vlan_id $lnk_vlan" >> $run_dir/$LOG_FILE
				dladm create-vlan -l $vlan_over -v $vlan_id $lnk_vlan
				if [ $? -ne 0 ]; then
					echo "Erro ao criar Vlan" >> $run_dir/$LOG_FILE
					echo "Erro ao criar Vlan!"
					exit 1
				fi
			fi
                        echo "Iniciando VM: $vm" >> $run_dir/$LOG_FILE
                        $ZONE_ADM -z $vm boot &>> $run_dir/$LOG_FILE
                        if [ $? -ne 0 ]; then
                                echo "Erro ao iniciar VM: $vm" >> $run_dir/$LOG_FILE
                                return 1
                        fi
                        vm_link=$(get_vm_link $vm)
                        echo "Definindo IP: $ipadr no link: $vm_link" >> $run_dir/$LOG_FILE
			echo "sleeping 15..."
			sleep 15
                        $ZLOGIN $vm ipadm create-addr -T static -a "$ipadr/24" "$vm_link/v4" &>> $run_dir/$LOG_FILE
                        if [ $? -ne 0 ]; then
                                echo "Erro ao definir IP: $ipadr no link: $vm_link para a VM: $vm" >> $run_dir/$LOG_FILE
                                echo "Aviso, nao foi possivel definir IP na vm: $vm"
                                #return 0
                        fi
                done
                return 0
        else
                return 0
        fi
}
stop_vms(){
        local i
        cenario_dir=$1
        run_dir="$cenario_dir/run"
        local vms_file="$cenario_dir/vms"
        local vlan_file="$cenario_dir/vlans"
        local vm
        local ipadr
        local vm_link
	local lnk_vlan
        if [ -s $vms_file ]; then
                for i in $(cat $vms_file| cut -d ":" -f 1); do
                        vm=$i
			vm_link=$(get_vm_link $vm)
                        echo "Removendo IP: $ipadr no link: $vm_link" >> $run_dir/$LOG_FILE
                        $ZLOGIN $vm ipadm delete-addr "$vm_link/v4" &>> $run_dir/$LOG_FILE
                        if [ $? -ne 0 ]; then
                                echo "Erro ao remover IP: $ipadr no link: $vm_link para a VM: $vm" >> $run_dir/$LOG_FILE
                                echo "Aviso, nao foi possivel remover IP na vm: $vm"
                                #return 0
                        fi
                        echo "Desligando VM: $vm" >> $run_dir/$LOG_FILE
                        $ZONE_ADM -z $vm shutdown &>> $run_dir/$LOG_FILE
                        if [ $? -ne 0 ]; then
                                echo "Erro ao desligar VM: $vm" >> $run_dir/$LOG_FILE
                                echo "Erro ao desligar VM: $vm"
                                return 1
                        fi
			grep -q ^$vm_link: $vlan_file 2> /dev/null
			if [ $? -eq 0 ]; then
				echo "Vm usando Vlan encontrada" >> $run_dir/$LOG_FILE
				echo "Removendo Vlan $vm_link" >> $run_dir/$LOG_FILE
				dladm delete-vlan $vm_link
				if [ $? -ne 0 ]; then
					echo "Erro ao apagar Vlan $vm_link" >> $run_dir/$LOG_FILE
					echo "Erro ao apagar Vlan $vm_link"
					exit 1
				fi
			fi
                done
                return 0
        else
                return 0
        fi
}
getinfo(){
        cenario_dir=$1
	local cenario_name=$2
        local desc_file="$cenario_dir/desc.txt"
        local vms_file="$cenario_dir/vms"
        local rbridges_file="$cenario_dir/rbridges"
        local bridges_file="$cenario_dir/bridges"
        local links_file="$cenario_dir/links"
	echo "Nome: $cenario_name"
	if [ -s $desc_file ]; then
		echo -n "Descricao: "
		cat $desc_file
	else
		echo "Descricao: none"
	fi
        if [ -s $vms_file ]; then
                echo "Maquinas virtuais:"
                cat $vms_file | cut -d ":" -f 1 | sed 's/^/    /'
        fi
        if [ -s $rbridges_file ]; then
                echo "Rbridges:"
                cat $rbridges_file | cut -d ":" -f 1 | sed 's/^/    /'
        fi
        if [ -s $bridges_file ]; then
                echo "Bridges:"
                cat $bridges_file | cut -d ":" -f 1 | sed 's/^/    /'
        fi
        if [ -s $links_file ]; then
                echo "Links:"
                cat $links_file | sed 's/^/    /'
        fi
}
