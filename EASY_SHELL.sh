#!/bin/bash

#文件:.EASY_SHELL.sh
#放到/root目录
#在~/.bashrc文件中中插入一行
#source ~/.EASY_SHELL.sh

#shell中执行,即时生效
#source ~/.bashrc

#操作系统ID
export EASY_SHELL_OS_ID=$(awk -F'=' '/^ID=/ {print $2}' /etc/os-release | tr -d '"')

#导出脚本文件路径
if [ "$BASH_SOURCE" != "" ]; then
    EASY_SHELL_SCRIPT_PATH="$(command cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
else
    EASY_SHELL_SCRIPT_PATH="/root/.EASY_SHELL.sh"
fi
export EASY_SHELL_SCRIPT_PATH

#脚本最后修改时间
export EASY_SHELL_SCRIPT_TIME=$(date -r "$EASY_SHELL_SCRIPT_PATH" "+%Y-%m-%d %H:%M:%S")

#调试.自动更新脚本内容到环境
export EASY_SHELL_DEBUG_UPDATE=true

#更新脚本环境
function debug_update_shell() {
    if [ "$EASY_SHELL_DEBUG_UPDATE" = "true" ]; then

        local curtime=$(date -r "$EASY_SHELL_SCRIPT_PATH" "+%Y-%m-%d %H:%M:%S")
        if [ "$EASY_SHELL_SCRIPT_TIME" != "$curtime" ]; then
            echo "脚本已更新,刷新环境变量..."
            source "$EASY_SHELL_SCRIPT_PATH"
            return 0
        fi
    fi
    return 1
}

function set_ifs() {
    oldIFS=$IFS
    IFS=$'\n'
}
function unset_ifs() {
    #echo "原IFS: $oldIFS"
    IFS=$oldIFS
}

function get_array_size() {
    local tmpstr="$@"
    if [ "${#tmpstr}" = "0" ]; then
        echo 0
        return 0
    fi
    echo $(echo "$tmpstr" | wc -l)
}
function get_array_item() {
    local input_index=$1
    shift
    local file_list="$@"
    echo $(echo "$file_list" | awk -v input_index="$input_index" 'NR==input_index {print $0}')
}

#模糊匹配路径- 只能匹配唯一路径
function cd() {
    debug_update_shell

    local dir_name="$1"
    shift

    if [ ! -d "$dir_name" ]; then

        local tmp_list=$(find . -maxdepth 1 -name "*$dir_name*" -type d)

        #原版
        #set_ifs
        #local arr_string=($tmp_list)
        #unset_ifs
        #local file_count=${#arr_string[@]}
        #echo "个数:" $file_count
        #if [ $file_count -eq 1 ]; then
        #dir_name=${tmp_list[0]}
        #fi

        #for i in $tmp_list; do
        #echo "测266622试:$i"
        #done

        local file_count=$(get_array_size "$tmp_list")

        echo "文件个数:"$file_count

        if [ $file_count -eq 1 ]; then
            dir_name=$tmp_list
        fi
    fi

    command cd "$dir_name" "$@"
    return $?
}
export cd

function ls() {
    debug_update_shell

    #local default_args=()

    if [ "$EASY_SHELL_OS_ID" = "openwrt" ]; then
        command ls "--color=auto" "-lA" "-lu" "$@"
    else
        command ls "--color=auto" "--time-style=+%Y-%m-%d %H:%M:%S" "-lA" "-lu" "$@"
    fi

    return $?
}
export ls

#服务
#srv ssh status
function srv() {
    debug_update_shell
    /etc/init.d/$@
}
export srv

#解压缩文件
unfile() {
    debug_update_shell

    local src

    if [ -z "$1" ]; then
        echo "usage: unfile filename"
        return 1
    fi

    # 判断文件是否存在
    if [ -f "$1" ]; then
        echo "文件存在"
        src="$1"
    else

        local file_list=$(find . -maxdepth 1 -type f \( -name "*$1*.tar" -o -name "*$1*.tbz2" -o -name "*$1*.tgz" -o -name "*$1*.tar.bz2" -o -name "*$1*.tar.gz" -o -name "*$1*.tar.Z" -o -name "*$1*.bz2" -o -name "*$1*.rar" -o -name "*$1*.gz" -o -name "*$1*.zip" -o -name "*$1*.Z" -o -name "*$1*.xz" -o -name "*$1*.lzo" -o -name "*$1*.7z" \))

        #find . -type f \( -name "*.tar" -o -name "*.gz" \)

        #local arr_file=($file_list)
        #local file_count=${#arr_file[@]}

        local file_count=$(get_array_size "$file_list")

        if [ $file_count -eq 0 ]; then
            echo "没有找到需要解压的文件: $1"
            return 1
        fi

        echo "文件个数: $file_count"

        if [ $file_count -gt 1 ]; then
            echo " $1 匹配多个文件,输入需要解压的文件序号或输入0解压所有匹配文件"
            #echo "-------------------------------------------------------------"

            echo "[ 0 ] 解压所有文件"

            set_ifs
            local curIndex=1
            for item in $file_list; do
                echo "[ $curIndex ] "$item""
                curIndex=$((curIndex + 1))
            done
            unset_ifs

            local input_index
            read -p "输入需要解压的文件序号: " input_index

            # 检查输入是否为数字
            if ! [[ "$input_index" =~ ^[0-9]+$ ]]; then
                return 1
            fi

            if [ "$input_index" -gt "$file_count" ]; then
                echo "input error [ 0 - $file_count ]"
                return 1
            fi

            if [ $input_index -eq 0 ]; then

                set_ifs

                shift
                for item in $file_list; do
                    unfile "$item" "$@"
                done
                unset_ifs

                return 0
            else
                src=$(get_array_item $input_index "$file_list")

                #input_index=$((input_index - 1))
                #src=${arr_file[$input_index]}
            fi
        else
            #src=${arr_file[0]}
            src="$file_list"
        fi
    fi

    shift

    echo "解压文件-模拟:$src"
    return 0

    if [[ "$src" == *.tar ]] ||
        [[ "$src" == *.tbz2 ]] ||
        [[ "$src" == *.tgz ]] ||
        [[ "$src" == *.tar.bz2 ]] ||
        [[ "$src" == *.tar.gz ]] ||
        [[ "$src" == *.tar.xz ]] ||
        [[ "$src" == *.tar.Z ]]; then

        tar xvf $src "$@"

    elif [[ "$src" == *.bz2 ]]; then
        bunzip2v $src "$@"

    elif [[ "$src" == *.rar ]]; then
        rar x $src "$@"

    elif [[ "$src" == *.gz ]]; then
        gunzip $src "$@"

    elif [[ "$src" == *.zip ]]; then
        unzip $src "$@"

    elif [[ "$src" == *.Z ]]; then
        uncompress $src "$@"

    elif [[ "$src" == *.xz ]]; then
        xz -d $src "$@"

    elif [[ "$src" == *.lzo ]]; then
        lzo -dv $src "$@"

    elif [[ "$src" == *.7z ]]; then
        7z x $src "$@"
    else
        echo "不支持的压缩格式"
    fi
}
export unfile
