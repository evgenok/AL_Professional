Занятие 10. Размещаем свой RPM в своем репозитории
Домашнее задание

1) Создать свой RPM пакет (можно взять свое приложение, либо собрать, например,
Apache с определенными опциями).
2) Создать свой репозиторий и разместить там ранее собранный RPM.

Домашнее задание выполнял на ОС Fedora

// Для начала установил недостающие пакеты, которые необходимы для работы  
[root@packages ~]# yum install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano

// Скачал исходники nginx в ранее созданную директорию rpm
[root@packages ~]# yumdownloader --source nginx

// установил скачанный nginx и доустановил зависимости
[root@packages ~]# rpm -Uvh nginx*.src.rpm
[root@packages ~]# yum-builddep nginx

// перешел в каталог /root, скачал с гита модуль ngx_brotli
[root@packages ~]# cd /root
[root@packages ~]# git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli

// В созданном каталоге /out перехожим к сборке модуля ngx_brotli
[root@packages ~]# cd ngx_brotli/deps/brotli/out
[root@packages ~]# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF 
-DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections 
-Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops 
-ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..

[root@packages ~]# cmake --build . --config Release -j 2 --target brotlienc

// находим секцию %build, раздел configure в файле ~/rpmbuild/SPECS/nginx.spec и добавляем строку: 
--add-module=/root/ngx_brotli \

// перехожу к сборке пакета 
[root@packages ~]# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'

// проверяем собранные пакеты
[root@packages ~]# ls -lah rpmbuild/RPMS/x86_64

// копируем пакеты в один каталог:ы
[root@packages ~]# cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
[root@packages ~]# cd ~/rpmbuild/RPMS/x86_64

// устанавливаем собранные пакеты и проверяемся работоспособность. Готово!
[root@packages ~]# yum localinstall *.rpm
[root@packages ~]# systemctl start nginx
[root@packages ~]# systemctl status nginx


