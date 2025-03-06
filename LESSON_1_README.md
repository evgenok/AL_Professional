# AL_Professional
Занятие 1. Обновление ядра системы
Цель домашнего задания
Научиться обновлять ядро в ОС Linux.
Описание домашнего задания
1) Запустить ВМ c Ubuntu.
2) Обновить ядро ОС на новейшую стабильную версию из mainline-репозитория.
3) Оформить отчет в README-файле в GitHub-репозитории.

Дополнительное задание:
Собрать ядро самостоятельно из исходных кодов.

// Проверяем актуальную версию нашего ядра и тип процессора
#uname -r
6.2.0-20-generic
#uname -p
x86_64

// проверил установленные на данный момент компоненты ядра (6.2.0-20-generic) 
#ls -lah /boot

// решил собрать ядро для своей ubuntu версии 6.13.5, перешел в репозиторий, указанный в методичке и подтянул оттуда 4 пакета в предварительно созданный каталог ~/kernel
#wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-headers-6.13.5-061305-generic_6.13.5-061305.202502271338_amd64.deb  
#wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-headers-6.13.5-061305_6.13.5-061305.202502271338_all.deb
#wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-image-unsigned-6.13.5-061305-generic_6.13.5-061305.202502271338_amd64.deb
#wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-modules-6.13.5-061305-generic_6.13.5-061305.202502271338_amd64.deb

~/kernel# ls | grep 6.13.5
linux-headers-6.13.5-061305_6.13.5-061305.202502271338_all.deb
linux-headers-6.13.5-061305-generic_6.13.5-061305.202502271338_amd64.deb
linux-image-unsigned-6.13.5-061305-generic_6.13.5-061305.202502271338_amd64.deb
linux-modules-6.13.5-061305-generic_6.13.5-061305.202502271338_amd64.deb

// установил пакеты
~/kernel# sudo dpkg -i *.deb

//обновил конфигурацию, ребутнул машину и проверил актуальную информацию о ядре
#update-grub

#uname -r
6.13.5-061305-generic






