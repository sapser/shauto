shauto
======

bash写的批量执行工具，模拟python的ansible库。

简单示例：
```bash
$ cat hosts 
[test1]
172.16.9.140
172.16.9.141
#172.16.9.142

[web]
172.16.9.141

$ ./shauto test1 -m ping
TASK - ping
172.16.9.141 | success | rc=0
172.16.9.140 | success | rc=0

$ ./shauto 172.16.9.140 -m command -a "/sbin/ifconfig eth0"
TASK - command: /sbin/ifconfig eth0
172.16.9.140 | success | rc=0

$ ./shauto 172.16.9.140 -m command -a "/sbin/ifconfig eth0" -v
TASK - command: /sbin/ifconfig eth0
172.16.9.140 | success | rc=0 >>
172.16.9.140: eth0      Link encap:Ethernet  HWaddr 08:00:27:AD:A1:41  
172.16.9.140:           inet addr:172.16.9.140  Bcast:172.16.9.255  Mask:255.255.255.0
172.16.9.140:           inet6 addr: fe80::a00:27ff:fead:a141/64 Scope:Link
172.16.9.140:           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
172.16.9.140:           RX packets:4726 errors:0 dropped:0 overruns:0 frame:0
172.16.9.140:           TX packets:2133 errors:0 dropped:0 overruns:0 carrier:0
172.16.9.140:           collisions:0 txqueuelen:1000 
172.16.9.140:           RX bytes:389555 (380.4 KiB)  TX bytes:689622 (673.4 KiB)
172.16.9.140: 
```

shauto中的模块本质是bash函数，所以我们可以在自己的shell脚本中调用这些函数，然后通过shauto的`-b`参数调用：
```bash
$ cat test.sh 
#!/bin/bash

#执行命令
command "/sbin/ifconfig eth0"

for f in /home/chenwei/*.txt; do
    #修改文件权限
    file -m 0755 "$f"
done

#sudo执行
sudo -m command -a "ls /root/"

$ ./shauto 172.16.9.141 -b test.sh -v
TASK - command: /sbin/ifconfig eth0
172.16.9.141 | success | rc=0 >>
172.16.9.141: eth0      Link encap:Ethernet  HWaddr 08:00:27:97:96:30  
172.16.9.141:           inet addr:172.16.9.141  Bcast:172.16.9.255  Mask:255.255.255.0
172.16.9.141:           inet6 addr: fe80::a00:27ff:fe97:9630/64 Scope:Link
172.16.9.141:           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
172.16.9.141:           RX packets:186911 errors:0 dropped:0 overruns:0 frame:0
172.16.9.141:           TX packets:25990 errors:0 dropped:0 overruns:0 carrier:0
172.16.9.141:           collisions:0 txqueuelen:1000 
172.16.9.141:           RX bytes:16844986 (16.0 MiB)  TX bytes:10420005 (9.9 MiB)
172.16.9.141: 

TASK - file: /home/chenwei/a.txt
172.16.9.141 | success | rc=0 >>

TASK - file: /home/chenwei/b.txt
172.16.9.141 | success | rc=0 >>

TASK - file: /home/chenwei/c.txt
172.16.9.141 | success | rc=0 >>

TASK - command: ls /root/
172.16.9.141 | success | rc=0 >>
172.16.9.141: anaconda-ks.cfg  hello    install.log  install.log.syslog
```
