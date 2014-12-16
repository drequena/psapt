#!/bin/bash
PSAPT_DIR="/opt/psapt"
BIN_DIR="$PSAPT_DIR/bin"
CEN_DIR="$PSAPT_DIR/cenarios"
UNIQUE_FILE="$CEN_DIR/control.run"
usage(){
	echo -e "uso: control <cenario|list> <comando|?>"
	exit 1
}
not_a_cenario(){
	echo -e "Cenario nao existente."
	usage
}
list(){
	local i
	for i in $(ls $CEN_DIR); do
		echo "Nome: $i"
		if [ -s $CEN_DIR/$i/desc.txt ]; then
			echo -n "info: "
			cat $CEN_DIR/$i/desc.txt
			echo ""
		else
			echo -e "info: none\n"
		fi
	done
	exit 0
}
if [ "$1" == "list" ]; then
	list
fi
# Testa se arg1 existe, se nao sai
test $1 && cen_to_control=$1 || usage
test $2 && cmd_cen=$2 || usage
# Testa se arg1 eh um diretorio, se nao sai
test -d $CEN_DIR/$cen_to_control || not_a_cenario
. $BIN_DIR/control_functions.sh
cenario="$CEN_DIR/$cen_to_control"
run_dir="$cenario/run"
#
# Checa se todos os arquivos necessarios para iniciar um cenario existem no diretorio.
# Caso nao exista, sai apenas escrevendo Erro na tela.
#
check_cen_sanity $cenario
ret_test $?
case "$cmd_cen" in
	start )
		is_unique
		if [ $? -ne 1 ]; then
			echo "Atencao, ja existe um cenario sendo executado. Essa versao do PSAPT nao suporta multiplos cenarios ao mesmo tempo."
			exit 1
		fi
		
		get_cen_status $cen_to_control
		if [ $? -eq 1 ]; then
			echo "Cenario ja executando..."
			exit 1
		fi
		echo "-----------------------Start begin: Cenario $cen_to_start: $(date +%H:%M:%S" "%d\/%m)-----------------------" >> $run_dir/$LOG_FILE
		check_vm_sanity $cenario
		echo -n "Copying config files..."
		copy_cen_files $cenario
		ret_test $?
		echo -n "Starting links..."
		start_links $cenario
		ret_test $?
                echo -n "Starting links connections..."
                start_links_conn $cenario
		ret_test $?
                echo -n "Starting bridges..."
                start_bridges $cenario
                ret_test $?
                echo -n "Starting Rbridges..."
                start_Rbridges $cenario
                ret_test $?
		echo -n "Starting VMs..."
		start_vms $cenario
		ret_test $?
	
		echo "Criando arquivo de status em $run_dir/$1.started" >> $run_dir/$LOG_FILE
		touch $run_dir/"$cen_to_control.started" &>> $run_dir/$LOG_FILE
		echo "Criando arquivo de status geral $UNIQUE_FILE" >> $run_dir/$LOG_FILE
		#touch $UNIQUE_FILE &>> $run_dir/$LOG_FILE
		echo $cen_to_control > $UNIQUE_FILE
		echo "-----------------------Start end: Cenario $cen_to_start: $(date +%H:%M:%S" "%d\/%m)-----------------------" >> $run_dir/$LOG_FILE
	;;
	stop )
                get_cen_status $cen_to_control
                if [ $? -eq 0 ]; then
                        echo "Cenario ja parado."
                        exit 1
                fi
		#
		# Variaveis _BKP utilizadas na hora de apagar o arquivo de controle
		# que sinaliza o status do cenario (iniciado ou parado)
		#
		echo "Salvando variaveis cenario,run_dir,LOG_FILE" >> $run_dir/$LOG_FILE
		cenario_bkp=$cenario
		run_dir_bkp=$run_dir
		LOG_FILE_BKP=$LOG_FILE
		check_diff $cenario
		
		if [ $? -eq 1 ]; then
                        echo "Cenario em exec. diferente do original..." >> $run_dir/$LOG_FILE
			echo "Setando var: cenario, run_dir ,LOG_FILE" >> $run_dir/$LOG_FILE
		
			cenario=$run_dir
			run_dir="$cenario/run"
			LOG_FILE="../log"
			echo "Cenario -> $cenario" >> $run_dir/$LOG_FILE
			echo "RUN_DIR -> $run_dir" >> $run_dir/$LOG_FILE
			echo "LOG -> $run_dir/$LOG_FILE" >> $run_dir/$LOG_FILE
			#####exit 1
                fi
		echo "-----------------------STOP begin: Cenario $cen_to_start: $(date +%H:%M:%S" "%d\/%m)-----------------------" >> $run_dir/$LOG_FILE
		echo -n "Stopping VMs..."
		stop_vms $cenario
		ret_test $?
                echo -n "Stopping Rbridges..."
                stop_Rbridges $cenario
                ret_test $?
                echo -n "Stopping bridges..."
                stop_bridges $cenario
                ret_test $?
                echo -n "Stopping links connections..."
                stop_links_conn $cenario
                ret_test $?
                echo -n "Stopping links..."
                stop_links $cenario
                ret_test $?
		#
		# Retorna valores antigos das variaveis para poder apagar arquivo de controle
		# No caso de ter havido diferenca entre arquivos de configuracao
		#
                echo "Voltando valores das variaveis" >> $run_dir/$LOG_FILE
		cenario=$cenario_bkp
		run_dir=$run_dir_bkp
		LOG_FILE=$LOG_FILE_BKP
		
		echo "Cenario -> $cenario" >> $run_dir/$LOG_FILE
                echo "RUN_DIR -> $run_dir" >> $run_dir/$LOG_FILE
                echo "LOG -> $run_dir/$LOG_FILE" >> $run_dir/$LOG_FILE
                echo -n "Deleting Run-config files..."
                delete_cen_files $cenario
                ret_test $?
		echo "Removendo arquivo de status em $run_dir/$1.started" >> $run_dir/$LOG_FILE
		rm -f $run_dir/"$cen_to_control.started" &>> $run_dir/$LOG_FILE
		echo "Removendo arquivo de status geral $UNIQUE_FILE" >> $run_dir/$LOG_FILE
		rm -f $UNIQUE_FILE &>> $run_dir/$LOG_FILE
		echo "-----------------------STOP end: Cenario $cen_to_start: $(date +%H:%M:%S" "%d\/%m)-----------------------" >> $run_dir/$LOG_FILE
	;;
	info)
                get_cen_status $cen_to_control
                if [ $? -eq 0 ]; then
			getinfo $cenario $cen_to_control
                else
			getinfo $run_dir $cen_to_control
		fi
	;;
	*)
		echo -e "comandos:\n <start> - inicia cenario\n <stop> - para cenario\n <info> - mostra informacoes do cenario"
		exit 1
	;;
esac
