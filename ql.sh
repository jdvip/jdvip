#!/usr/bin/env bash
github="https://yanyu.ltd/https://raw.githubusercontent.com/jdvip/jdvip/master/"
QL_IMG_NAME="registry.cn-hongkong.aliyuncs.com/shippoo/qinglong"
QL_TAG="2.11.3"
SHELL_FOLDER=$(pwd)
JD_PATH=""
CONTAINER_NAME="qinglong"
JD_PORT=5700
MAPPING_JD_PORT="-p $JD_PORT:5700"
log() {
    echo -e "\e[32m\n$1 \e[0m\n"
}

inp() {
    echo -e "\e[33m\n$1 \e[0m\n"
}

opt() {
    echo -n -e "\e[36m输入您的选择->\e[0m"
}

warn() {
    echo -e "\e[31m$1 \e[0m\n"
}

cancelrun() {
    if [ $# -gt 0 ]; then
        echo -e "\e[31m $1 \e[0m"
    fi
    exit 1
}

docker_install() {
    echo "检测 Docker......"
    if [ -x "$(command -v docker)" ]; then
        echo "检测到 Docker 已安装!"
    else
        echo "安装 docker 环境..."
        curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
        echo "安装 docker 环境...安装完成!"
        systemctl enable docker
        systemctl start docker
    fi
}

# 配置文件保存目录
step_01(){
    warn "Faker系列仓库一键安装配置，小白回车到底，一路默认选择"
    echo -n -e "\e[33m一、请输入配置文件保存的绝对路径（示例：/root)，回车默认为当前目录:\e[0m"
    read jd_path
    if [ -z "$jd_path" ]; then
        JD_PATH=$SHELL_FOLDER
    elif [ -d "$jd_path" ]; then
        JD_PATH=$jd_path
    else
        mkdir -p $jd_path
        JD_PATH=$jd_path
    fi
    rm -rf $JD_PATH/ql
    CONFIG_PATH=$JD_PATH/ql/config
    DB_PATH=$JD_PATH/ql/db
    REPO_PATH=$JD_PATH/ql/repo
    RAW_PATH=$JD_PATH/ql/raw
    SCRIPT_PATH=$JD_PATH/ql/scripts
    LOG_PATH=$JD_PATH/ql/log
    DEPS_PATH=$JD_PATH/ql/deps
}

# 检测容器是否存在
rm_old_container() {
    if [ ! -z "$(docker ps -a | grep $CONTAINER_NAME 2> /dev/null)" ]; then
        log "发现已安装容器，删除先前的容器"
        docker stop $CONTAINER_NAME >/dev/null
        docker rm $CONTAINER_NAME >/dev/null
    fi
}

creat_ql_dir(){
    log "1.开始创建配置文件目录"
    PATH_LIST=($CONFIG_PATH $DB_PATH $REPO_PATH $RAW_PATH $SCRIPT_PATH $LOG_PATH $DEPS_PATH)
    for i in ${PATH_LIST[@]}; do
        mkdir -p $i
    done
}

creat_new_container(){
    log "3.开始创建容器并执行"
    docker run -dit \
        -t \
        -v $CONFIG_PATH:/ql/config \
        -v $DB_PATH:/ql/db \
        -v $LOG_PATH:/ql/log \
        -v $REPO_PATH:/ql/repo \
        -v $RAW_PATH:/ql/raw \
        -v $SCRIPT_PATH:/ql/scripts \
        -v $DEPS_PATH:/ql/deps \
        $MAPPING_JD_PORT \
        --name $CONTAINER_NAME \
        --hostname qinglong \
        --restart always \
        $QL_IMG_NAME:$QL_TAG

    if [ $? -ne 0 ] ; then
        cancelrun "** 错误：容器创建失败，请翻译以上英文报错，Google/百度尝试解决问题！"
    fi
    
}

step_02(){
    echo -n -e "\e[33m二、容器配置\e[0m"
    rm_old_container
    creat_ql_dir
    creat_new_container
}

setep_check(){
    # 检查 config 文件是否存在
    if [ ! -f "$CONFIG_PATH/config.sh" ]; then
        docker cp $CONTAINER_NAME:/ql/sample/config.sample.sh $CONFIG_PATH/config.sh
        if [ $? -ne 0 ] ; then
            cancelrun "** 错误：找不到配置文件！"
        fi
    fi
    log "4.下面列出所有容器"
    docker ps -a
    log "5.安装已完成，请进入面板一次以便进行内部配置"
    log "5.1.用户名和密码已显示，请登录 ip:$JD_PORT"
    cat $CONFIG_PATH/auth.json
    echo -e "\n"
    # 防止 CPU 占用过高导致死机
    echo -e "-------- 机器累了，休息 20s，趁机去操作一下吧 --------"
    sleep 20s
    echo -e "\n"
    cat $CONFIG_PATH/auth.json
    echo -e "\n"
    log "6.2.用被修改的密码登录面板并进入"
    # token 检测
    inp "是否已进入面板：\n1) 进入[默认]\n2) 未进入"
    opt
    read access
    log "6.3.观察 token 是否成功生成"
    cat $CONFIG_PATH/auth.json
    echo -e "\n"
    if [ "$(grep -c "token" $CONFIG_PATH/auth.json)" != 0 ]; then
        log "7.开始青龙内部配置"
        docker exec -it $CONTAINER_NAME bash -c "$(curl -fsSL $github/1customCDN.sh)"
    else
        warn "7.未检测到 token，取消内部配置"
    fi
}

main(){
    docker_install
    step_01
    step_02
    setep_check
}
main $*