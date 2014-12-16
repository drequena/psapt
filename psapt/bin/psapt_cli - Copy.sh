#!/bin/bash
trap "echo Por favor, digite o comando exit para sair" 1 2 3 15 23
command_array_unshift() {
  placeholder=${command_array[0]}
  unset command_array[0]
  arr=("${command_array[@]}")
}
log_alert() {
	echo "O comando anterior retornou um erro,"
	echo "execute o comando log para checar o possivel motivo."
}
PSAPT_DIR="/opt/psapt"
BIN_DIR="$PSAPT_DIR/bin"
CEN_DIR="$PSAPT_DIR/cenarios"
target_cenario=""
target=""
red=$'\E[31m'
cyan=$'\E[36m'
reset=$'\E[0m'
echo -e "
$red##############################################################################
$red#$reset Seja bem vindo ao Psapt_cli v0.9					 
$red#$reset									 
$red#$reset Essa versao tem a limitacao de executar apenas um cenario simulado   
$red#$reset de cada vez.							 
$red#$reset 									 
$red#$reset Autor: Daniel Requena						 
$red##############################################################################$reset
"
while true; do
	$BIN_DIR/control.sh list
	echo "$red.psapt>$reset Selecione o cenario que sera iniciado ou exit para sair."
	while true; do
		read -p "$red.psapt>$reset" target
		if [ -z $target ]; then
			continue
		else
			if [ $target = "exit" ]; then
				exit 0
			fi
			break
		fi
	done
	$BIN_DIR/control.sh list | grep "^Nome:" | awk '{print $2}'| grep -q $target
	if [ $? -ne 0 ]; then
		echo -e "$red.psapt>$reset Cenario invalido!"
	else
		target_cenario=$target
		$BIN_DIR/control.sh $target_cenario start
		echo "$red.psapt@$cyan$target_cenario>$reset Digite o comando ou help|? para lista-los"
		while true; do
			read -p "$red.psapt@$cyan$target_cenario>$reset" command
	
			command_array=($command)
			case "${command_array[0]}" in
				?|help )
					echo -e "
stop - Para o cenario e sai do programa
info - lista informacoes sobre o cenario em execucao
link <comandos|?> - Manipula os links de um cenario iniciado
bridge <comandos|?> - Manipula as bridges de um cenario iniciado
rbridge <comandos|?> - Manipula as Rbridges de um cenario iniciado
vm <comandos|?> - Manipula as VMs de uma cenario iniciado
log - Mostra as ultimas 20 linhas do arquivo de log do cenario em execução
quit|exit - sai da ferramenta
"
				;;
				quit|exit)
		
					if [ -f $CEN_DIR/control.run ]; then
						echo -en "$red.psapt@$cyan$target_cenario>$reset O cenario ainda se encontra em execucao, eh necessario para-lo antes de sair, deseja para-lo agora? $cyan[y|N]:$reset"
						read answer				
						case "$answer" in
							[yY]|[sS])
								$BIN_DIR/control.sh $target_cenario stop
			                                        if [ $? -ne 0 ]; then
                        			                        log_alert
			                                        else
			                                                exit 0
			                                        fi
							;;
		                                        [nN])
								continue
		                                        ;;
							*)
								continue
							;;	
						esac
					else
						exit 0
					fi
				;;
		                stop)
					$BIN_DIR/control.sh $target_cenario stop
					if [ $? -ne 0 ]; then
						log_alert
					else
						break
					fi
		                ;;
				info)
					$BIN_DIR/control.sh $target_cenario info
                                        if [ $? -ne 0 ]; then
                                                log_alert
                                        fi
				;;
				link)
					command_array_unshift					
					parameters=${command_array[@]}
					$BIN_DIR/links.sh $target_cenario $parameters
                                        if [ $? -ne 0 ]; then
                                                log_alert
                                        fi
				;;
		                bridge)
		                        command_array_unshift
		                        parameters=${command_array[@]}
		                        $BIN_DIR/bridge.sh $target_cenario $parameters
                                        if [ $? -ne 0 ]; then
                                                log_alert
                                        fi
		                ;;
		                rbridge)
		                        command_array_unshift
		                        parameters=${command_array[@]}
		                        $BIN_DIR/rbridge.sh $target_cenario $parameters
                                        if [ $? -ne 0 ]; then
                                                log_alert
                                        fi
		                ;;
		                vm)
		                        command_array_unshift
		                        parameters=${command_array[@]}
		                        $BIN_DIR/vm.sh $target_cenario $parameters
                                        if [ $? -ne 0 ]; then
                                                log_alert
                                        fi
		                ;;
				log)
					tail -20 $CEN_DIR/$target_cenario/run/log
				;;
				* )
				;;
			esac	
		done
	fi
done
