Домашнее задание
Работа с LVM

Цель:
создавать и управлять логическими томами в LVM;

*Настроить LVM в Ubuntu 24.04 Server
*Создать Physical Volume, Volume Group и Logical Volume
*Отформатировать и смонтировать файловую систему
*Расширить файловую систему за счёт нового диска
*Выполнить resize
*Проверить корректность работы



///проверил корректность подключения всех дисков, необходимых для работы (sdb,sdc,sdd)\\
root@osboxes:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  500G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  498G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0  100G  0 lvm  /
sdb                         8:16   0   10G  0 disk 
sdc                         8:32   0   10G  0 disk 
sdd                         8:48   0   10G  0 disk 
sr0                        11:0    1 1024M  0 rom  


///создал два physical volume из носителя sdb и sdc\\ 
root@osboxes:~# pvcreate /dev/sdb 
Physical volume "/dev/sdb" successfully created.
root@osboxes:~# pvcreate /dev/sdc
Physical volume "/dev/sdb" successfully created.

///затем volume group(с именем: vg1) из носителя sdb и sdc\\
root@osboxes:~# vgcreate vg1 /dev/sdb
Volume group "vg1" successfully extended
root@osboxes:~# vgcreate vg1 /dev/sdc
Volume group "vg1" successfully extended

///убедился в этомm проверил наличие sdb и sdc в VG\\
root@osboxes:~# pvs && vgs
  PV         VG        Fmt  Attr PSize    PFree   
  /dev/sda3  ubuntu-vg lvm2 a--  <498.00g <398.00g
  /dev/sdb             lvm2 ---    10.00g   10.00g
  /dev/sdc             lvm2 ---    10.00g   10.00g

  VG        #PV #LV #SN Attr   VSize    VFree   
  ubuntu-vg   1   1   0 wz--n- <498.00g <398.00g
  vg1         2   0   0 wz--n-   19.99g   19.99g

///создаем логический раздел logical volume (lv1 и lv2) на vg1, делаем файловую систему в lv1 и lv2 и убеждаемся в этом\\
root@osboxes:~# lvcreate -L 5G -n lv1 vg1
Wiping ext4 signature on /dev/vg1/lv1.
  Logical volume "lv1" created.

root@osboxes:~# lvcreate -L 10G -n lv2 vg1
Wiping ext4 signature on /dev/vg1/lv2.
  Logical volume "lv2" created.

root@osboxes:~# mkfs.ext4 /dev/vg1/lv1 (при копировании с удаленного сервера нарушился формат чтения, поэтому в выводе данной команды присутствуют непонятные символы)
Creating filesystem with 1310720 4k blocks and 327680 inodes
Filesystem UUID: 59dd456f-63ba-4c97-82c6-fff6928efb74
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736

Allocating group tables:  0/40     done                            
Writing inode tables:  0/40     done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information:  0/40     done

root@osboxes:~# mkfs.ext4 /dev/vg1/lv2
Creating filesystem with 1310720 4k blocks and 327680 inodes
Filesystem UUID: 59dd456f-63ba-4c97-82c6-fff6928efb74
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736

Allocating group tables:  0/40     done                            
Writing inode tables:  0/40     done                            
Creating journal (2123384 blocks): done
Writing superblocks and filesystem accounting information:  0/40     done

///Монтируем\\
root@osboxes:~# mount /dev/vg1/lv1 /mnt/01
root@osboxes:~# mount /dev/vg1/lv2 /mnt/02

root@osboxes:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  500G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  498G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0  100G  0 lvm  /
sdb                         8:16   0   10G  0 disk 
├─vg1-lv1                 252:1    0    5G  0 lvm  /mnt/01
└─vg1-lv2                 252:2    0   10G  0 lvm  /mnt/02
sdc                         8:32   0   10G  0 disk 
└─vg1-lv2                 252:2    0   10G  0 lvm  /mnt/02
sdd                         8:48   0   10G  0 disk 
sr0                        11:0    1 1024M  0 rom 

///приступим к добавлению нового диска к файловой системе\\
root@osboxes:~# pvcreate /dev/sdd 
Physical volume "/dev/sdd" successfully created.

root@osboxes:~# vgextend vg1 /dev/sdd
Volume group "vg1" successfully extended

///видно, что диск добавился к vg1(в столбце pv было 2, стало 3)\\
root@osboxes:~# vgs

  VG        #PV #LV #SN Attr   VSize    VFree   
  ubuntu-vg   1   1   0 wz--n- <498.00g <398.00g
  vg1         3   2   0 wz--n-  <29.99g  <14.99g

///изменили объем lv до 15Гб и сделали resize\\
root@osboxes:~# lvresize -L 15G /dev/vg1/lv1
Size of logical volume vg1/lv1 changed from 5.00 GiB (1280 extents) to 15.00 GiB (3840 extents).
Logical volume vg1/lv1 successfully resized.

root@osboxes:~# resize2fs /dev/mapper/vg1-lv1
Filesystem at /dev/mapper/vg1-lv1 is mounted on /mnt/01; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 2
The filesystem on /dev/mapper/vg1-lv1 is now 3932160 (4k) blocks long.

///видно, что в итоге получилось. 3 физических носителя (sdb,sdc,sdd) в vg1 общим объемом 30Gb,
имеющие "на борту" 2 lv (lv1 и lv2), разбитые на 5Gb и 10Gb соответственно, но со свободным пространством 
в vg1 14.99Gb, которое можно разбить еще на несколько логических\\
root@osboxes:~# pvs
PV         VG        Fmt  Attr PSize    PFree   
  /dev/sda3  ubuntu-vg lvm2 a--  <498.00g <398.00g
  /dev/sdb   vg1       lvm2 a--   <10.00g    4.99g
  /dev/sdc   vg1       lvm2 a--   <10.00g       0 
  /dev/sdd   vg1       lvm2 a--   <10.00g  <10.00g
root@osboxes:~# vgs
  VG        #PV #LV #SN Attr   VSize    VFree   
  ubuntu-vg   1   1   0 wz--n- <498.00g <398.00g
  vg1         3   2   0 wz--n-  <29.99g  <14.99g
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
root@osboxes:~# lvs
  ubuntu-lv ubuntu-vg -wi-ao---- 100.00g                                                    
  lv1       vg1       -wi-a-----   5.00g                                                    
  lv2       vg1       -wi-ao----  10.00g                                                    





