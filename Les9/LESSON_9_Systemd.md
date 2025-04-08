Systemd — создание unit-файла

Домашнее задание
-Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
-Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
-Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.

1) Выполнял задание на VM с Ubuntu 24

// Создаем конфиг файл в директории /etc/default, в который добавляем переменные

[root@osboxes ~/etc/default/ #] nano watchlog

WORD="ALERT"
LOG=/var/log/watchlog.log

// в директории /var/log создаем log файл куда вносим любой текст включая ключевое слово ALERT (в нашем случае)

[root@osboxes ~/etc/default/ #] cd /var/log
[root@osboxes ~/var/log #] echo "ALERT: more my text..." > watchlog.log
ALERT: more my text...

// создаем скрипт, который будет искать ключевое слово (ALERT) в указанном пути (/var/log/watchlog) и записывать в системный журнал текст (в нашем случае "$DATE: I found word, Master!", где $DATE - сегодняшняя дата)
[root@osboxes ~/var/log #] cd /opt
[root@osboxes ~/opt #] nano watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi

// сразу сделаем этот скрипт исполняемым
[root@osboxes ~/opt #] chmod +x /opt/watchlog.sh

// переходим к описанию юнита типа service
[root@osboxes ~/opt #] nano /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/default/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG

// переходим к описанию юнита типа timer - он же и будет запускать наш watch.service
[root@osboxes ~/opt #] nano /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 sec

[Timer]
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target

// запускаем, ждем 30 сек и видим первые наши записи в syslog. Готово!
[root@osboxes ~/opt #] systemctl start watchlog.time
[root@osboxes ~/opt #] tail -n 1000 /var/log/syslog  | grep word
...
Apr  8 12:26:11 osboxes root: Thu Apr  8 12:26:11 UTC 2025: I found word, Master!

2) Переходим к сборке spawn-fcgi.sevice - утилита, которая является прослойкой между сервером и приложением

// устанавливаем необходимые пакеты
[root@osboxes ~ #] apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y

// создаем конфиг файл с заданными переменными
[root@osboxes ~ #] nano /etc/spawn-fcgi/fcgi.conf
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"

// создаем отдельный юнит типа service
[root@osboxes ~ #] nano /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target

// сохраняем и стартуем, проверяем 
[root@osboxes ~ #] systemctl start spawn-fcgi
[root@osboxes ~ #] systemctl status spawn-fcgi
spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: >
     Active: active (running) since Tue 2025-04-08 09:13:08 EDT; 4s ago
   Main PID: 13923 (php-cgi)
      Tasks: 33 (limit: 4608)
     Memory: 19.3M (peak: 19.8M)
        CPU: 85ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─13923 /usr/bin/php-cgi
             ├─13924 /usr/bin/php-cgi
             ...
             ├─13954 /usr/bin/php-cgi
             └─13955 /usr/bin/php-cgi

Apr 08 09:13:08 osboxes systemd[1]: Started spawn-fcgi.service - Spawn-fcgi sta>


3) Последнее задание - запуск нескольких инстансов nginx

// проверил, что nginx установлен
[root@osboxes ~ #] nginx -v 
nginx version: nginx/1.24.0 (Ubuntu)

// Создаем юнит для дальнейшей работы с шаблонами
[root@osboxes ~ #] nano /etc/systemd/system/nginx@.service
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target

// создаем конфиг файлы для nginx-first и nginx-second, делаем их идентичными nginx.conf, за исключением (см. двумя стр. ниже)
[root@osboxes ~ #] nano /etc/nginx/nginx-first.conf
[root@osboxes ~ #] nano /etc/nginx/nginx-second.conf

# добавил к "...nginx...;" "-first" и "-second" соответственно. Получилось:
pid /run/nginx-first.pid;
pid /run/nginx-second.pid;

# закомментил "include /etc/nginx/sites-enabled/*;"

# изменил файл для вывода логов. Для каждого сервиса соответственно добавил "_first" и "_second". Получилось:
error_log /var/log/nginx/error_first.log;
access_log /var/log/nginx/access_first.log;

error_log /var/log/nginx/error_second.log;
access_log /var/log/nginx/access_second.log;

# добавил для каждого сервиса в раздел http подраздел server и проставил номер прослушиваемого сервером порта 9001 и 9002 сответственно:
http {
...
	server {
		listen 9001;
	}
...
}

http {
...
	server {
		listen 9002;
	}
...
}

// стартуем готовые юниты, но перед этим убедился в том, что 80, 443 (дефолтные) и 9001, 9002 не заняты другими службами
[root@osboxes ~ #] ss -tulpn | grep -E "80|443|9001|9002"
[root@osboxes ~ #] systemctl start nginx@first
[root@osboxes ~ #] systemctl start nginx@second

// проверяем работоспособность инстантов (так же прикрепил скрин)
ss -tulpn | grep nginx
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=26223,fd=6),("nginx",pid=26222,fd=6),("nginx",pid=26221,fd=6))
tcp   LISTEN 0      511          0.0.0.0:9001       0.0.0.0:*    users:(("nginx",pid=26223,fd=5),("nginx",pid=26222,fd=5),("nginx",pid=26221,fd=5))
tcp   LISTEN 0      511          0.0.0.0:9002       0.0.0.0:*    users:(("nginx",pid=26566,fd=5),("nginx",pid=26565,fd=5),("nginx",pid=26564,fd=5))
tcp   LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=26223,fd=7),("nginx",pid=26222,fd=7),("nginx",pid=26221,fd=7))

