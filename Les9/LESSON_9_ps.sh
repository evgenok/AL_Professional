#!/bin/bash

# Заголовок вывода
printf "%-10s %-10s %-10s %-10s %s\n" "PID" "PPID" "STAT" "NI" "COMMAND"

# Перебираем все числовые директории в /proc (каждая соответствует процессу)
for pid in $(ls -d /proc/[0-9]*/ | awk -F/ '{print $3}' | sort -n); do
    # Проверяем, существует ли директория процесса (на случай завершения процесса во время работы скрипта)
    if [ -d "/proc/$pid" ]; then
        # Считаем основную информацию о процессе
        if [ -r "/proc/$pid/stat" ]; then
            # Считаем и разбираем /proc/[pid]/stat
            stat_data=$(cat "/proc/$pid/stat" 2>/dev/null)
            if [ -z "$stat_data" ]; then
                continue
            fi

            # Нужно быть аккуратным, так как comm может содержать пробелы и скобки
            # Вытаскиваем в переменную comm (имя процесса)
            comm=$(echo "$stat_data" | awk -F'[()]' '{print $2}')
            # Вытаскиваем состояние процесса в переменную rest
            rest=$(echo "$stat_data" | awk -F')' '{print $2}')

            # Извлекаем остальные поля
            read -r state ppid ni <<< $(echo "$rest" | awk '{print $1, $2, $17}')

            # Форматируем вывод из 5 колонок
            printf "%-10s %-10s %-10s %-10s %s\n" "$pid" "$ppid" "$state" "$ni" "$comm"
        fi
    fi
done