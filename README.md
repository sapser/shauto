### shauto
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

shauto中的模块本质是bash函数（可以直接看成是一个命令），所以我们可以在自己的shell脚本中调用这些函数，然后通过shauto的`-b`参数来执行这些脚本：
```bash
$ cat test.sh 
#!/bin/bash

#执行命令
command "/sbin/ifconfig eth0"

for f in /home/sapser/*.txt; do
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

TASK - file: /home/sapser/a.txt
172.16.9.141 | success | rc=0 >>

TASK - file: /home/sapser/b.txt
172.16.9.141 | success | rc=0 >>

TASK - file: /home/sapser/c.txt
172.16.9.141 | success | rc=0 >>

TASK - command: ls /root/
172.16.9.141 | success | rc=0 >>
172.16.9.141: anaconda-ks.cfg  hello    install.log  install.log.syslog
```

### 安装及使用
shauto就一个单独的shell脚本，可以放在`PATH`下，也可以放在任意路径然后通过绝对或相对路径调用，记得要给可执行权限。

shauto脚本开头有一些全局变量需要自定义，可以根据实际情况修改：
```
#hosts文件路径
HOSTS_FILE="hosts"

#日志文件路径
LOG_FILE="$(basename $0).log"

#远程ssh用户
REMOTE_USER="sapser"

#远程ssh端口
REMOTE_PORT=22

#远程shell
REMOTE_SHELL="/bin/sh"

#sudo到哪个用户
SUDO_USER="root"

#sudo命令参数
SUDO_ARGS="-H"

#私钥文件路径
PRIVATE_KEY_FILE=""

#ssh连接超时时间
SSH_TIMEOUT=10

#并发数量
FORKS=5
```
这些全局变量的作用看注释就一目了然了，特别说下shauto采用命名管道和后台进程来做并发控制，通过`-f`选项或`FORKS`全局变量来控制并发量，具体看脚本的`parall_run`函数。


### ssh远程连接
shauto使用openssh来连接远程主机，使用rsync来传输文件，对私钥验证支持比较好，因为可以通过`ssh-agent`来自动填私钥密码，在`~/.bashrc`中添加这一段代码，可以永久使用`ssh-agent`，而不会因为终端推出被干掉：
```bash
if [ -f ~/.agent.env ]; then
        . ~/.agent.env >/dev/null
        if ! kill -s 0 $SSH_AGENT_PID >/dev/null 2>&1; then
                echo "Stale agent file found. Spawning new agent..."
                eval `ssh-agent |tee ~/.agent.env`
                ssh-add
        fi
else
        echo "Starting ssh-agent..."
        eval `ssh-agent |tee ~/.agent.env`
        ssh-add
fi
```


### TODO
- `sudo`模块在命令行用有bug
- `copy`模块越写越复杂，需要简化
- 添加更多模块
