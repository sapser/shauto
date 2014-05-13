#!/bin/bash
#
#auto_shell.sh
#批量维护工具


#引用未定义的变量时报错并退出脚本
set -o nounset
#命令执行失败时报错并退出脚本
#set -o errexit

#当前绝对路径
CURRENT_PATH="$(cd $(dirname $0);pwd)"
#错误退出代码
FAIL_CODE=1
#要执行命令的主机列表
HOSTLIST=""
#默认用户及端口
USER="chenwei"
PORT=22
#要执行的命令
CMD=""
#定制ssh连接选项
SSH_ARGS="-o StrictHostKeyChecking=no"
#并发数量
PARALL=1
#远程SHELL
REMOTE_SHELL="bash"


ssh_connect() {
    local host="$1"

    #while read line; do
    #    if [[ -n "$line" ]]; then
    #        echo "$line" | sed -e "s/^/$host: /"
    #    fi
    #done < <(echo "$CMD" | ssh -t -l "$USER" -p "$PORT" "$SSH_ARGS" "$host" "$REMOTE_SHELL" 2>&1)
    result="$(echo "$CMD" | ssh -t -l "$USER" -p "$PORT" "$SSH_ARGS" "$host" "$REMOTE_SHELL" 2>&1)"
    
}


parall_run() {
    #建立命名管道文件，为了不受干扰，将文件打开，将文件inode信息删除
    local pipe="$(mktemp -u)" 
    mkfifo "$pipe" 
    #将文件$pipe绑定到文件描述符5 
    exec 5<>"$pipe"
    rm -f "$pipe" 

    #往命名管道存入值，存入多少个值就表示并发量多大
    for ((i=1;i<=${PARALL};i++)); do 
        echo >&5
    done 
  
    [[ -z "$HOSTLIST" ]] && error "no host"
    for host in $HOSTLIST; do
        #从命名管道读取一个值
        #如果此时命名管道中没有值，read会阻塞直到读取到一个值  
        read -u 5
        #执行具体的动作action，执行完后放入一个值到命名管道
        (ssh_connect; echo >&5) &
    done

    #等待所有后台进程执行完毕
    wait 
    #关闭文件描述符5
    exec 5>&-
}


error() {
    echo -e "\033[31m$@\033[0m" >&2
    exit $FAIL_CODE
}


#检查命令返回值，判断命令是否成功执行
return_code_check() {
    if [[ "$?" -eq 0 ]]; then
        echo "$@ success!"
    else
        error "$@ failed!"
    fi
}


#获取命令的绝对路径
#Arguments:
#  $1: 传入命令名
#Returns:
#  传入命令的绝对路径
get_cmd_abspath() {
    local cmd="$1"

    if which "$cmd" &>/dev/null; then
        echo "$(which $cmd)"
        return 0
    else
        error "no $cmd in ($PATH)"
    fi
}


#管理远程主机文件/目录的属性
#Arguments:
#  $1：远程文件/目录路径jj
#  $2：属主(owner)
#  $3：属组(group)
#  $4: 文件权限
file() {
    local path="$1"
    local owner="$2"
    local group="$3"
    local mode="$4"
}


#复制本地文件/目录到远程主机
#Arguments:
#  $1: 文件在本地主机的路径
#  $2: 文件在远程主机的存放路径
#  $3: 
copy() {
    local src="$1"
    local dest="$2"
    scp $src $user@$host:$dest
    # 如果目的路径在其他用户下怎么办
    # 先copy到$user下一个临时目录
    # 然后再sudo cp到对应目录
}


#连接到远程主机并执行命令
#Arguments:
#  $1: 远程主机用户
#  $2: 远程主机端口
#  $3: 远程主机IP地址
#  $4: 要执行的命令
#  $5: 值为yes表示需要sudo执行，默认值为no
#  $6: sudo到哪个用户，默认为root
_ssh() {
    # _ssh user port host cmd sudo sudo_user
    local user="$1"
    local port="$2"
    local host="$3"
    local cmd="$4"
    local sudo="${5:-no}"
    #local ssh="$(get_cmd_abspath ssh)"

    if [[ "$sudo" != "no" ]]; then
        local sudo_user="${6:-root}"
        #参数-t强制给ssh连接分配一个伪终端
        local ssh_cmd="ssh -t -l $user -p $port -oStrictHostKeyChecking=no $host /bin/bash" 
    else
        local ssh_cmd="ssh -l $user -p $port -oStrictHostKeyChecking=no $host /bin/bash"
    fi

    result=$(echo "$cmd" | $ssh_cmd)

    if [[ "$?" -eq 0 ]]; then
        echo "$result"
    else
        echo "$result"
        error "$ssh_cmd execute faild!"
    fi
}


