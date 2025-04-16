Работа с NFS 

Цель домашнего задания
-Научиться самостоятельно разворачивать сервис NFS и подключать к нему клиентов.

Описание домашнего задания 
Основная часть: 
-запустить 2 виртуальных машины (сервер NFS и клиента);
на сервере NFS должна быть подготовлена и экспортирована директория; 
-в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё; 
-экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
-монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.

//При выполнении ДЗ развенул серверную часть на Ubuntu server 24.04(192.168.1.12/24) и клиентскую на Ubuntu 24.04 (192.168.1.7/24)

//на серверной ВМ установил nfs-kernel-server
root@osboxes:home/osboxes# apt install nfs-kernel-server

//создал директорию, которая будет являться общей папкой
root@osboxes:home/osboxes# mkdir -p /srv/share/upload 

//нарезал права и задал владельцев каталога на общую папку
root@osboxes:home/osboxes# chown -R nobody:nogroup /srv/share 
root@osboxes:home/osboxes# chmod 0777 /srv/share/upload 

//создал файл export со следующим содержимым (каталог к которому будет доступ у клиентской машины и задал права доступа)
root@osboxes:home/osboxes# nano /etc/exports 
/srv/share 192.168.1.7/24(rw,sync,root_squash)

//применяем изменения
root@osboxes:etc/# exportfs -r

//проверяем директорию, к корой применили правила b видим вывод аналогичный методичке
root@osboxes:etc/# exportfs -s
/srv/share  192.168.1.7/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

//далее переходим к установке и настройке клиентской ВМ
root@osboxes:etc/# apt install nfs-common
root@osboxes:etc/# nano /etc/fstab
192.168.1.12:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0

//выполняем команды для применения измененеий без перезагрузки системы
root@osboxes:etc/# systemctl daemon-reload 
root@osboxes:etc/# systemctl restart remote-fs.target

//теперь если перейдем в каталог /srv/share/update и создадим там файлы(неважно с какой ВМ, они будут синхронизироваться)
root@osboxes:etc/# cd /srv/share/update && touch text1.txt 