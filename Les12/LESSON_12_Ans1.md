Домашнее задание
Первые шаги с Ansible

Цель:
Написать первые шаги с Ansible.

Что нужно сделать?

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:

необходимо использовать модуль yum/apt;
конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными;
после установки nginx должен быть в режиме enabled в systemd;
должен быть использован notify для старта nginx после установки;
сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible.

// установил ansible (2.16.3) на вм с ubuntu 24.04

root@osboxes:/home/osboxes# apt update -y && apt install ansible -y
root@osboxes:/home/osboxes# root@osboxes:/home/osboxes# ansible --version
ansible [core 2.16.3]

// в пользовательском каталоге создал директорию "ansible" и поддиректорию "host"
root@osboxes:/home/osboxes# mkdir -p ansible/host 

// переходим к созданию минимального конфига 
root@osboxes:/home/osboxes/ansible# nano ansible.cfg
[defaults]
inventory = host/hosts.ini
remote_user = osboxes
host_key_checking = False
retry_files_enabled = False

// переходим к созданию инвентаря. Добавил один узел на ВМ с debian(назвал ее "server"), установил подключение по ssh и указал учетные данные  
root@osboxes:/home/osboxes/ansible# cd /host && nano hosts.ini
server ansible_host=192.168.1.11 ansible_connection=ssh ansible_port=22 ansible_user=osboxes ansible_ssh_pass=11111111
[all]
server

// проверяем доступность нашей ВМ
root@osboxes:/home/osboxes/ansible/host# ansible -i hosts.ini server -m ping
server | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}

// теперь можем выполнять команды на самом server и сразу проверил версию ядра на нем
root@osboxes:/home/osboxes/ansible/host# ansible -i hosts.ini server -m command -a 'uname -r'
server | CHANGED | rc=0 >>
6.1.0-32-amd64

// проверил стояние службы firewalld
root@osboxes:/home/osboxes/ansible/host# ansible -i hosts.ini server -m systemd -a name=firewalld
server | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
         ...

// переходим к написанию плейбука
root@osboxes:/home/osboxes/ansible# nano play.yml
---
- name: playbook for install nginx on server
  hosts: all
  become: true

  tasks:
    - name: update apt packages
      apt:
        update_cache: yes

    - name: install nginx
      apt:
        name: nginx
        state: latest

// запускаем наш плейбук
root@osboxes:/home/osboxes/ansible# ansible-playbook -i host/hosts.ini play.yml  
PLAY [playbook for install nginx on server] ************************************

TASK [Gathering Facts] *********************************************************
ok: [server]

TASK [update apt packages] *****************************************************
ok: [server]

TASK [install nginx] ***********************************************************
changed: [server]

PLAY RECAP *********************************************************************
server                     : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 


// проверяем статус на нашем server. Действительно установился и запустился. Перед запуском плейбука я убедился в отсутствии установленного nginx.
root@osboxes: ~ # systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: e>
     Active: active (running) since Tue 2025-04-29 13:19:09 MSK; 4s ago
       Docs: man:nginx(8)
    Process: 4321 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_proce>
    Process: 4323 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (c>
   Main PID: 4324 (nginx)
      Tasks: 3 (limit: 4608)
     Memory: 2.4M (peak: 2.5M)
        CPU: 45ms
     CGroup: /system.slice/nginx.service

// создадим в каталоге ansible/templates шаблон конфига nginx.conf.j2 
root@osboxes:/home/osboxes/ansible/template# nano nginx.conf.j2
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}


// дополняем handlers и notify наш play.yml, что бы устанавливать параметры заданные в нашем nginx.conf.j2 и при его изменении - сервис перезагрузиться 
---
- name: playbook for install nginx on server
  hosts: all
  become: true
  vars:
    nginx_listen_port: 8080

  tasks:
    - name: update apt packages
      apt:
        update_cache: yes
      tags:
        - update apt

    - name: install nginx
      apt:
        name: nginx
        state: latest
      notify:
        - restart nginx
      tags:
        - install nginx

    - name: create config file
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify:
        - reload nginx
      tags:
        - nginx-configuration

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
        enabled: yes

    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded     

// запустим плейбук и проверим его работоспособность через curl 192.168.1.11:8080
root@osboxes:/home/osboxes/ansible# curl 192.168.1.11:9091
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>


// поменяем порт на 9091 и запускаем заново  и видим, что срабатывает на изменение переменной.
root@osboxes:/home/osboxes/ansible# ansible-playbook -i host/hosts.ini play.yml 

PLAY [playbook for install nginx on server] ******************************************

TASK [Gathering Facts] ***************************************************************
ok: [server]

TASK [update apt packages] ***********************************************************
ok: [server]

TASK [install nginx] *****************************************************************
ok: [server]

TASK [create config file] ************************************************************
changed: [server]

RUNNING HANDLER [reload nginx] *******************************************************
changed: [server]

PLAY RECAP ***************************************************************************
server                     : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 

// тоже самое для 9091
root@osboxes:/home/osboxes/ansible# curl 192.168.1.11:9091
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
    ...
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
    ...
</html>
