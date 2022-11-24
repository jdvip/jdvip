#!/usr/bin/env bash
dir_config=/ql/config
github="https://yanyu.ltd/https://raw.githubusercontent.com/jdvip/jdvip/master"

# 下载默认的配置文件
dl_ql_config(){
    config_list=(code.sh config.sh extra.sh task_before.sh)
    for file in ${config_list[@]}; do
        file_path=$dir_config/$file
        rm -rf $file_path
        echo "下载->$github/$file"
        curl -sL --connect-timeout 3 $github/$file -o $file_path
        file_size=$(ls -l $file_path | awk '{print $5}')
        if (( $(echo "${file_size} < 100" | bc -l) )); then
            echo "$file_path 下载失败"
            exit 0
        fi
        chmod 755 $dir_config/$file
    done
}

# 将 ql extra 添加到定时任务
add_ql_extra() {
    if [ "$(grep -c "ql\ extra" /ql/config/crontab.list)" != 0 ]; then
        echo "您的任务列表中已存在 task:ql extra"
    else
        echo "开始添加 task:ql extra"
        # 获取token
        token=$(cat /ql/config/auth.json | jq --raw-output .token)
        curl -s -H 'Accept: application/json' -H "Authorization: Bearer $token" -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept-Language: zh-CN,zh;q=0.9' --data-binary '{"name":"同步Faker","command":"ql extra","schedule":"15 0-23/4 * * *"}' --compressed 'http://127.0.0.1:5700/api/crons?t=1624782068473'
    fi
}

# 运行一次 ql extra
run_ql_extra() {
    ql extra
    sleep 5
}
# 将 task code.sh 添加到定时任务
add_task_code() {
    if [ "$(grep -c "code.sh" /ql/config/crontab.list)" != 0 ]; then
        echo "您的任务列表中已存在 task:task code.sh"
    else
        echo "开始添加 task:task code.sh"
        # 获取token
        token=$(cat /ql/config/auth.json | jq --raw-output .token)
        curl -s -H 'Accept: application/json' -H "Authorization: Bearer $token" -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept-Language: zh-CN,zh;q=0.9' --data-binary '{"name":"格式化更新助力码","command":"task /ql/config/code.sh","schedule":"*/10 * * * *"}' --compressed 'http://127.0.0.1:5700/api/crons?t=1626247939659'
    fi
}

main(){
    dl_ql_config
    add_task_code
    add_ql_extra
    run_ql_extra
}

main $*
