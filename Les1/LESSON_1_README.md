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
#ls -lah /boot | grep 6.13.5
-rw-r--r--  1 root root 304K Feb 27 08:38 config-6.13.5-061305-generic
lrwxrwxrwx  1 root root   32 Mar  6 06:26 initrd.img -> initrd.img-6.13.5-061305-generic
-rw-r--r--  1 root root  71M Mar  6 06:27 initrd.img-6.13.5-061305-generic
-rw-------  1 root root 9.7M Feb 27 08:38 System.map-6.13.5-061305-generic
lrwxrwxrwx  1 root root   29 Mar  6 06:26 vmlinuz -> vmlinuz-6.13.5-061305-generic
-rw-------  1 root root  16M Feb 27 08:38 vmlinuz-6.13.5-061305-generic

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
Sourcing file /etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.13.5-061305-generic
Found initrd image: /boot/initrd.img-6.13.5-061305-generic
Found linux image: /boot/vmlinuz-6.2.0-20-generic
Found initrd image: /boot/initrd.img-6.2.0-20-generic
Found memtest86+x64 image: /boot/memtest86+x64.bin
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
#grub-set-defaut 0
#uname -r
6.13.5-061305-generic






