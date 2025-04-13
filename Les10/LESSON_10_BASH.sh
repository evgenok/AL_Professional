#!/bin/bash
# Переменные
LOG_FILE="/home/osboxes/access.log"            # Путь к логу 
LOCK_FILE="/tmp/bash_hw.lock"                  # Файл блокировки
LAST_RUN_FILE="/tmp/last_run_timestamp"        # Файл для хранения времени последнего запуска

# Проверка на блокировку
if [ -f "$LOCK_FILE" ]; then
    echo "Скрипт уже выполняется. Завершение."
    exit 1
else
    touch "$LOCK_FILE"  # Создаем файл блокировки, чтобы предотвратить одновременный запуск
fi

# Запоминаем текущее время для следующего запуска
CURRENT_TIME=$(date +%s)
echo "$CURRENT_TIME" > "$LAST_RUN_FILE" # Сохраняем текущее время

# Если файл с временем последнего запуска не существует, установим время в начале лога
if [ ! -f "$LAST_RUN_FILE" ]; then
    LAST_RUN_TIMESTAMP=0
else
    LAST_RUN_TIMESTAMP=$(cat "$LAST_RUN_FILE")
fi

# Преобразуем время последнего запуска в формат для grep
START_TIME=$(date -d @$LAST_RUN_TIMESTAMP "+%d/%b/%Y:%H:%M:%S")

# Формирование письма
REPORT="Отчет о запросах с последнего запуска скрипта ($START_TIME):\n\n"

# 1. Список IP-адресов с наибольшим количеством запросов
REPORT+="\nСписок IP-адресов с наибольшим количеством запросов:\n"
TOP_IPS=$(grep -E "^\S+.*" $LOG_FILE | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 15)
REPORT+="$TOP_IPS\n"

# 2. Список запрашиваемых URL
REPORT+="\nСписок запрашиваемых URL:\n"
TOP_URLS=$(grep -E "^\S+.*" $LOG_FILE | awk '{print $7}' | sort | uniq -c | sort -rn | head -n 15)
REPORT+="$TOP_URLS\n"

# 3. Ошибки веб-сервера
REPORT+="\nОшибки веб-сервера:\n"
ERRORS=$(grep -E "^\S+.*" $LOG_FILE | grep -E ' 403| 404| 500| 502| 503' | awk '{print $9}' | sort | uniq -c | sort -rn)
REPORT+="$ERRORS\n"

# 4. Список всех кодов HTTP ответа
REPORT+="\nВсе коды HTTP ответа:\n"
HTTP_CODES=$(grep -E "^\S+.*" $LOG_FILE | awk {'print $9'} | grep -E '[0-9][0-9][0-9]' | sort | uniq -c | sort -rn)
REPORT+="$HTTP_CODES\n"

echo -e "$REPORT" > new.txt

# Удаляем файл блокировки по завершению
rm -f "$LOCK_FILE"