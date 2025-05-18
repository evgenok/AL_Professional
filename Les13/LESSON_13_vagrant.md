Занятие 1. Vagrant-стенд для обновления ядра и создания образа системы
Цель домашнего задания
Научиться обновлять ядро в ОС Linux. Получение навыков работы с Vagrant. 
Описание домашнего задания
1) Запустить ВМ с помощью Vagrant.
2) Обновить ядро ОС из репозитория ELRepo.
3) Оформить отчет в README-файле в GitHub-репозитории.


// Пришлось помучаться, чтобы найти актуальные пути к образам и репозиториям

// Скачал Vagrant, создал Vagrantfile (прикреплен отдельно)

// Запустил командой vagrant up и подключился vagrant ssh

// Проверил версию ядра
uname -r
4.18.0-277.el8.x86_64

// Тут не обошелся без помощи ИИ. Заменяем стандартные репозитории на архивные (vault.centos.org)
sudo sed -i 's|mirrorlist=http://mirrorlist.centos.org|//mirrorlist=http://mirrorlist.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|//baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

// Очищаем кеш и обновляем список пакетов
sudo yum clean all
sudo yum makecache

// Устанавливаем GPG-ключ ELRepo
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

// Устанавливаем репозиторий ELRepo
sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm

// Доступные варианты для установки ядра

kernel-lt - стабильная версия
kernel-ml - свежая версия

// Установка LTS-ядра 
sudo yum --enablerepo=elrepo-kernel install kernel-lt -y

// Или установка Mainline-ядра 
sudo yum --enablerepo=elrepo-kernel install kernel-ml -y

// Обновляем загрузчик 
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

// Указываем новое ядро по умолчанию и перезагружаемся
sudo grub2-set-default 0  
sudo reboot

// Проверка установленного ядра
uname -r
5.4.293-1.el8.elrepo.x86_64
