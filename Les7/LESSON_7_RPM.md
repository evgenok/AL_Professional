Занятие 10. Размещаем свой RPM в своем репозитории
Домашнее задание

1) Создать свой RPM пакет (можно взять свое приложение, либо собрать, например,
Apache с определенными опциями).
2) Создать свой репозиторий и разместить там ранее собранный RPM.

Домашнее задание выполнял на ОС Fedora

// Для начала установил недостающие пакеты, которые необходимы для работы  
[root@192 ~]# yum install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano

// Скачал исходники nginx в ранее созданную директорию rpm
[root@192 ~]# yumdownloader --source nginx

// установил скачанный nginx и доустановил зависимости
[root@192 ~]# rpm -Uvh nginx*.src.rpm
[root@192 ~]# yum-builddep nginx

// перешел в каталог /root, скачал с гита модуль ngx_brotli
[root@192 ~]# cd /root
[root@192 ~]# git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli

// В созданном каталоге /out перехожим к сборке модуля ngx_brotli
[root@192 ~]# cd ngx_brotli/deps/brotli/out
[root@192 ~]# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF 
-DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections 
-Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops 
-ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..

[root@192 ~]# cmake --build . --config Release -j 2 --target brotlienc

// находим секцию %build, раздел configure в файле ~/rpmbuild/SPECS/nginx.spec и добавляем строку: 
--add-module=/root/ngx_brotli \

// перехожу к сборке пакета 
[root@192 ~]# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'

// проверяем собранные пакеты
[root@192 ~]# ls -lah rpmbuild/RPMS/x86_64

// копируем пакеты в один каталог:ы
[root@192 ~]# cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
[root@192 ~]# cd ~/rpmbuild/RPMS/x86_64

// устанавливаем собранные пакеты и проверяемся работоспособность. Готово!
[root@192 ~]# yum localinstall *.rpm
[root@192 ~]# systemctl start nginx
[root@192 ~]# systemctl status nginx


// Создал каталог /usr/share/nginx/html/repo и перенес туда ранее собранные пакеты
[root@192 /usr/share/nginx/html/repo]# cp ~/rpmbuild/RPMS/x86_64/*.rpm /usr/share/nginx/html/repo


// инициализировал репозиторий
[root@192 /usr/share/nginx/html/repo]# createrepo /usr/share/nginx/html/repo/

// добавил пару строк в конфигурационный файл nginx.conf, проверил соответствие синтаксису и перезапустил nginx
[root@192 /usr/share/nginx/html/repo]# nano /etc/nginx/nginx.conf
index index.html index.htm;
autoindex on;

[root@192 /usr/share/nginx/html/repo]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

[root@192 /usr/share/nginx/html/repo]# nginx -s reload

// Добавим его в /etc/yum.repos.d:
[root@192 /usr/share/nginx/html/repo]# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

// репозиторий подключился 
[root@192 /usr/share/nginx/html/repo]# yum repolist enabled | grep otus
otus-linux

// добавим новый пакет в наш репозиторий
[root@192 /usr/share/nginx/html/repo]# wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm

// Обновим список пакетов в репозитории:
[root@192 /usr/share/nginx/html/repo]# createrepo /usr/share/nginx/html/repo/
[root@192 /usr/share/nginx/html/repo]# yum makecache
[root@192 /usr/share/nginx/html/repo]# yum list | grep otus
percona-release.noarch 	1.0-27 		otus
