Домашнее задание Стенд ZFS

 Цели домашнего задания
Научится самостоятельно устанавливать ZFS, настраивать пулы, изучить основные возможности ZFS. 

 Описание домашнего задания
Определить алгоритм с наилучшим сжатием:
Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
создать 4 файловых системы на каждой применить свой алгоритм сжатия;
для сжатия использовать либо текстовый файл, либо группу файлов.
Определить настройки пула.
С помощью команды zfs import собрать pool ZFS.
Командами zfs определить настройки:
    - размер хранилища;
    - тип pool;
    - значение recordsize;
    - какое сжатие используется;
    - какая контрольная сумма используется.
Работа со снапшотами:
скопировать файл из удаленной директории;
восстановить файл локально. zfs receive;
найти зашифрованное сообщение в файле secret_message.

//убеждаемся в подключении всех дисков. необходимых для работы
[root@osboxes ~]# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   25G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0   23G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0 11.5G  0 lvm  /
sdb                         8:16   0  512M  0 disk 
sdc                         8:32   0  512M  0 disk 
sdd                         8:48   0  512M  0 disk 
sde                         8:64   0  512M  0 disk 
sdf                         8:80   0  512M  0 disk 
sdg                         8:96   0  512M  0 disk 
sdh                         8:112  0  512M  0 disk 
sdi                         8:128  0  512M  0 disk 

//создаем пулы из дисков 
[root@osboxes ~]# zpool create test1 mirror /dev/sdb dev/sdc
[root@osboxes ~]# zpool create test2 mirror /dev/sdd /dev/sde 
[root@osboxes ~]# zpool create test3 mirror /dev/sdf /dev/sdg
[root@osboxes ~]# zpool create test4 mirror /dev/sdh /dev/sdi

//проверяем  информацию о созданных пулах 
[root@osboxes ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
test1   480M   116K   480M        -         -     0%     0%  1.00x    ONLINE  -
test2   480M   116K   480M        -         -     0%     0%  1.00x    ONLINE  -
test3   480M   146K   480M        -         -     0%     0%  1.00x    ONLINE  -
test4   480M   166K   480M        -         -     0%     0%  1.00x    ONLINE  -


//добавляем разные типы сжатия файлов к разным файловым системам соответственно и убежаемся в этом
[root@osboxes ~]# zfs set compression=lzjb tеst1
[root@osboxes ~]# zfs set compression=lz4 test2
[root@osboxes ~]# zfs set compression=gzip-9 test3
[root@osboxes ~]# zfs set compression=zle test4

[root@osboxes ~]# zfs get all | grep compression
tеst1  compression           lzjb                   local
tеst2  compression           lz4                    local
tеst3  compression           gzip-9                 local
tеst4  compression           zle                    local

//скачиваем файл во все пулы из методички
[root@osboxes ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done

//проверяем какой тип сжатия эффективнее (gzip-9)
[root@osboxes ~]# ls -l /test*
/test1:
total 22096
-rw-r--r-- 1 root root 41123477 Feb  2 08:31 pg2600.converter.log

/test2:
total 18006
-rw-r--r-- 1 root root 41123477 Feb  2 08:31 pg2600.converter.log

/test3:
total 10966
-rw-r--r-- 1 root root 41123477 Feb  2 08:31 pg2600.converter.log

/test4:
total 40188
-rw-r--r-- 1 root root 41123477 Feb  2 08:31 pg2600.converter.log

//данной командой мы можем проверить ВСЕ настройки нашего пула
[root@osboxes ~]# zpool get all test1
NAME   PROPERTY                       VALUE                          SOURCE
test1  size                           480M                           -
test1  capacity                       7%                             -
test1  altroot                        -                              default
test1  health                         ONLINE                         -
test1  guid                           1208694192677408881            -
test1  version                        -                              default
test1  bootfs                         -                              default
test1  delegation                     on                             default
test1  autoreplace                    off                            default
test1  cachefile                      -                              default
test1  failmode                       wait                           default
test1  listsnapshots                  off                            default
test1  autoexpand                     off                            default
test1  dedupratio                     1.00x                          -
test1  free                           444M                           -
test1  allocated                      36.0M                          -
test1  readonly                       off                            -
test1  ashift                         0                              default
test1  comment                        -                              default
test1  expandsize                     -                              -
test1  freeing                        0                              -
test1  fragmentation                  0%                             -
test1  leaked                         0                              -
test1  multihost                      off                            default
test1  checkpoint                     -                              -
test1  load_guid                      14539764335586081023           -
test1  autotrim                       off                            default
test1  compatibility                  off                            default
test1  bcloneused                     0                              -
test1  bclonesaved                    0                              -
test1  bcloneratio                    1.00x                          -
test1  feature@async_destroy          enabled                        local
test1  feature@empty_bpobj            active                         local
test1  feature@lz4_compress           active                         local
test1  feature@multi_vdev_crash_dump  enabled                        local
test1  feature@spacemap_histogram     active                         local
test1  feature@enabled_txg            active                         local
test1  feature@hole_birth             active                         local
test1  feature@extensible_dataset     active                         local
test1  feature@embedded_data          active                         local
test1  feature@bookmarks              enabled                        local
test1  feature@filesystem_limits      enabled                        local
test1  feature@large_blocks           enabled                        local
test1  feature@large_dnode            enabled                        local
test1  feature@sha512                 enabled                        local
test1  feature@skein                  enabled                        local
test1  feature@edonr                  enabled                        local
test1  feature@userobj_accounting     active                         local
test1  feature@encryption             enabled                        local
test1  feature@project_quota          active                         local
test1  feature@device_removal         enabled                        local
test1  feature@obsolete_counts        enabled                        local
test1  feature@zpool_checkpoint       enabled                        local
test1  feature@spacemap_v2            active                         local
test1  feature@allocation_classes     enabled                        local
test1  feature@resilver_defer         enabled                        local
test1  feature@bookmark_v2            enabled                        local
test1  feature@redaction_bookmarks    enabled                        local
test1  feature@redacted_datasets      enabled                        local
test1  feature@bookmark_written       enabled                        local
test1  feature@log_spacemap           active                         local
test1  feature@livelist               enabled                        local
test1  feature@device_rebuild         enabled                        local
test1  feature@zstd_compress          enabled                        local
test1  feature@draid                  enabled                        local
test1  feature@zilsaxattr             enabled                        local
test1  feature@head_errlog            active                         local
test1  feature@blake3                 enabled                        local
test1  feature@block_cloning          enabled                        local
test1  feature@vdev_zaps_v2           active                         local

//или только определенный параметр
[root@osboxes ~]# zpool get <property> test1

//скачать otus_task2.file не получилось, но прокинул общую папку, восстановил фс из него
[root@osboxes ~]# zfs receive test1/test@today < otus_task2.file

//нашел по методичке файл "secret_message" и просмотрел его содержимое
[root@osboxes ~]# find /test1/test -name "secret_message"
/test1/test/task1/file_mess/secret_message
[root@osboxes ~]# cat /test1/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/