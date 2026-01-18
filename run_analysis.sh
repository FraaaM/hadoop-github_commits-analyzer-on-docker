#!/bin/bash

set -e 

EMAIL_LOG_FILE="commit_emails.txt"
LOCAL_RESULT_FILE="result_raw.txt"
HDFS_INPUT_DIR="/input"
HDFS_OUTPUT_DIR="/output"

rm -f $EMAIL_LOG_FILE $LOCAL_RESULT_FILE
mkdir -p /app/output

echo "--- 1: Запуск сервисов Hadoop ---"
service ssh start
if [ ! -d "/tmp/hadoop-root/dfs/name" ]; then
    echo "Форматирование HDFS..."
    hdfs namenode -format
fi
start-dfs.sh
start-yarn.sh

echo "--- 2: Сбор данных через GitHub API ---"
python3 get_commit_data.py

if [ ! -s "$EMAIL_LOG_FILE" ]; then
    echo "ОШИБКА: Файл с email-адресами '$EMAIL_LOG_FILE'"
    exit 1
fi
echo "Собрано email-адресов: $(wc -l < $EMAIL_LOG_FILE)."

echo "--- 3: Загрузка данных в HDFS ---"
hdfs dfs -rm -r $HDFS_INPUT_DIR 2>/dev/null || true
hdfs dfs -rm -r $HDFS_OUTPUT_DIR 2>/dev/null || true
hdfs dfs -mkdir -p $HDFS_INPUT_DIR
hdfs dfs -put $EMAIL_LOG_FILE $HDFS_INPUT_DIR

echo "--- 4: Запуск MapReduce задачи  ---"
python3 vendor_contribution.py -r hadoop \
    --output-dir $HDFS_OUTPUT_DIR \
    hdfs://$HDFS_INPUT_DIR/$EMAIL_LOG_FILE \
|| { echo "ОШИБКА: Hadoop задача провалилась"; exit 1; }
echo "Основная задача успешно завершена."

hdfs dfs -getmerge $HDFS_OUTPUT_DIR $LOCAL_RESULT_FILE
python3 plot_results.py $LOCAL_RESULT_FILE

echo "--- Остановка сервисов Hadoop ---"
stop-yarn.sh
stop-dfs.sh
service ssh stop

echo "--- Результаты находится в папке 'output' ---"