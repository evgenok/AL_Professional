Домашнее задание: работа с mdadm
Задание
• Добавить в виртуальную машину несколько дисков
• Собрать RAID-0/1/5/10 на выбор
• Сломать и починить RAID
• Создать GPT таблицу, пять разделов и смонтировать их в системе.
На проверку отправьте:
скрипт для создания рейда, 
отчет по командам для починки RAID и созданию разделов.

//скрипт для создания рейда
$./script_raid
  #!/bin/bash

//отчет по командам для починки RAID и созданию разделов

//проверил содержимое RAID10
root@osboxes:/home/osboxes#  mdadm -D /dev/md10
/dev/md10:
           Version : 1.2
     Creation Time : Tue Mar 11 13:04:00 2025
        Raid Level : raid10
        Array Size : 2616320 (2.50 GiB 2.68 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Mar 11 13:08:10 2025
             State : clean
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : osboxes:10  (local to host osboxes)
              UUID : 5e1e19f3:fd3f3f03:0c271801:8a40dd40
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       17        0      active sync   /dev/sdb1
       1       8       18        1      active sync   /dev/sdb2
       2       8       19        2      active sync   /dev/sdb3
       3       8       20        3      active sync   /dev/sdb4
       4       8       21        4      active sync   /dev/sdb5

//потушил диск в RAID и проверил его статус (removed)
root@osboxes:/home/osboxes# mdadm /dev/md10 --fail /dev/sdb1
mdadm: set /dev/sdb1 faulty in /dev/md10
root@osboxes:/home/osboxes#  mdadm -D /dev/md10
/dev/md10:
           Version : 1.2
     Creation Time : Tue Mar 11 13:04:00 2025
      ...
      Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       18        1      active sync   /dev/sdb2
       2       8       19        2      active sync   /dev/sdb3
       3       8       20        3      active sync   /dev/sdb4
       4       8       21        4      active sync   /dev/sdb5

       0       8       17        -      faulty   /dev/sdb1


//удалил sdb1 из RAIDи убедился, что sdb1  удален из RAID
root@osboxes:/home/osboxes# mdadm /dev/md10 --remove /dev/sdb1
mdadm: hot removed /dev/sdb1 from /dev/md10
root@osboxes:/home/osboxes#  mdadm -D /dev/md10
/dev/md10:
           Version : 1.2
     Creation Time : Tue Mar 11 13:04:00 2025
        Raid Level : raid10
      ...
        Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       18        1      active sync   /dev/sdb2
       2       8       19        2      active sync   /dev/sdb3
       3       8       20        3      active sync   /dev/sdb4
       4       8       21        4      active sync   /dev/sdb5


//добавил sdb1 в RAID и увидел статус процесса восстановления
root@osboxes:/home/osboxes# mdadm --add /dev/md10 /dev/sdb1
mdadm: added /dev/sdb1
root@osboxes:/home/osboxes#  mdadm -D /dev/md10
/dev/md10:
           Version : 1.2
     Creation Time : Tue Mar 11 13:04:00 2025
     ...
     State : clean, degraded, recovering
    Active Devices : 4
   Working Devices : 5
     ...
     Number   Major   Minor   RaidDevice State
       5       8       17        0      spare rebuilding   /dev/sdb1
       1       8       18        1      active sync   /dev/sdb2
       2       8       19        2      active sync   /dev/sdb3
       3       8       20        3      active sync   /dev/sdb4
       4       8       21        4      active sync   /dev/sdb5


//здесь проверяем успешность восстановления диска(sdb1) в RAID
root@osboxes:/home/osboxes# cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md10 : active raid10 sdb1[5] sdb5[4] sdb4[3] sdb3[2] sdb2[1]
      2616320 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]

unused devices: <none>
