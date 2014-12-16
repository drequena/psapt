#!/bin/bash
# NAO EXECUTE ESSE SCRIPT MANUALMENTE!
# Recebe cenario e link a ser capturado.
PSAPT_DIR="/opt/psapt"
CEN_DIR="$PSAPT_DIR/cenarios"
LOG_FILE="log"
TCPDUMP="/usr/sbin/tcpdump"
CAPTURE_DIR="/tmp/pub/psatp"
DATE="/usr/bin/date"
JOBS="/usr/bin/jobs"
arg_num=$#
if [ $arg_num -lt 2 ] || [ $arg_num -gt 2 ]; then
        echo "Nao execute esse script via linha de comando!"
        exit 15
fi
cen_to_operate=$1
link_capture=$2
cenario="$CEN_DIR/$cen_to_operate"
run_dir="$cenario/run"
echo "capture.sh: Checando existencia do diretorio $CAPTURE_DIR" >> $run_dir/$LOG_FILE
if [ ! -d $CAPTURE_DIR ]; then
                echo "$CAPTURE_DIR nao existe, criando..." >> $run_dir/$LOG_FILE
                mkdir -p $CAPTURE_DIR
fi
echo "Criando arquivo $link_capture.run" >> $run_dir/$LOG_FILE
touch  $run_dir/$link_capture".run"
capture_prefix=$($DATE +%m-%d-%y-%H%M%S)
capture_prefix="$capture_prefix.cap"
CAPTURE_FILE_NAME="$CAPTURE_DIR/$link_capture-$capture_prefix"
$TCPDUMP -i $link_capture -n -s 0 -w $CAPTURE_FILE_NAME &
if [ $? -ne 0 ]; then
	echo "Erro ao iniciar captura do link $link_capture" >> $run_dir/$LOG_FILE
	echo "Erro ao iniciar captura do link $link_capture"
	echo "Apagando arquivo $link_capture.run" >> $run_dir/$LOG_FILE
	rm $run_dir/$link_capture".run"
	exit 0
fi
tcpdump_pid=$!
echo "Processo de captura do link $link_capture iniciado com sucesso. Executando sob pid: $tcpdump_pid" >> $run_dir/$LOG_FILE
echo $tcpdump_pid > $run_dir/$link_capture".run"
exit 1
