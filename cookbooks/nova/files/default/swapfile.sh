#!/bin/bash
swap_file=/swap_nova_0

usage(){
    echo "Usage:"
    echo "  $0 0      disable swap file"
    echo "  $0 size   create swap file"
}

make_swap(){
    local file=$1
    local size=$2

    #${size} * 1024
    dd if=/dev/zero of=${file} bs=1k count=${size}
    mkswap ${file}
}

do_swap_on(){
    # swap size as kb
    local swap_size=$1

    # minimal swap size
    if [ ${swap_size} -lt 41 ]; then
        swap_size=41
    fi

    if [ -f ${swap_file} -a `grep -c "^${swap_file}" /proc/swaps` = '1' ]; then
        current_size=$((`ls -l ${swap_file} | awk '{print $5}'` / 1024))
        if [ "$current_size" = "${swap_size}" ]; then
            echo "swap already exists"
            return
        fi
    fi

    if ! grep -q "^${swap_file}" /proc/swaps; then
        echo "create swap file ${swap_file}"
        make_swap ${swap_file} ${swap_size}
        swapon ${swap_file}
    fi

    if [ ! `du -b ${swap_file} | awk '{print $1}'` = "$((swap_size*1024))" ]; then
        echo "resize_swap to ${swap_size}"
        local swap_tmp=/swap_nova.tmp
        make_swap ${swap_tmp} ${swap_size}
        swapon ${swap_tmp}
        swapoff ${swap_file}

        make_swap ${swap_file} ${swap_size}
        swapon ${swap_file}
        swapoff ${swap_tmp}
        rm -f ${swap_tmp}
    fi
}

if [ -z "$1" ]; then
    usage
    exit
fi

if [ "$1" = "0" ]; then
    if grep -q "^${swap_file}" /proc/swaps; then
        echo "disable swap ${swap_file}"
        swapoff ${swap_file}
        rm -f ${swap_file}
    fi
else
    do_swap_on $1
fi
