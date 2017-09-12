#!/bin/bash
set -e

cd `dirname $0`/..

# up하면서 chef-zero도 띄우기 때문에 vagrant up은 반드시 필요함
vagrant up --no-provision --parallel

provision() {
    # chef-zero가 준비될 때까지 wait
    if [ -z "$BERKSHELF" ]; then
        until knife role list > /dev/null 2>&1 ; do
            sleep `echo $((RANDOM % 60))`
        done
    fi

    vagrant provision $@
}

if [ -z "$vms_config" ]; then
    echo '$vms_config environment required'
    exit 1
fi

vms=`python -c "import json; print ' '.join(json.load(open('config/${vms_config}'))['vms'].keys())"`
for vm in $vms; do
    # background로 provisioning
    provision $vm &

    # provision pid를 기록해서 종료할 때까지 대기
    # 그냥 wait하면 chef-zero까지 wait를 해서 영원히 종료하지 않음
    ppid+=" $!"

    # 모든 vm이 동시에 provision되면 berks upload하면서 chef-zero에 부하가 많아서
    # 두번째 vm부터는 berks를 실행히지 않음
    unset BERKSHELF
done

wait $ppid

# lb setup 확인!!
knife ssh roles:openstack-api-loadbalancer 'sudo chef-client'
# 변경된 LB 적용
knife ssh "NOT roles:openstack-api-loadbalancer" 'sudo chef-client' -C 3

ssh_config=~/.ssh/config
if [ -d ~/.ssh/config.d ]; then
    ssh_config=~/.ssh/config.d/99.stack.config 
fi

cat << EOF > $ssh_config
host *.stack
    IdentityFile ~/.vagrant.d/insecure_private_key
    User vagrant
    LogLevel=ERROR
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentityFile ~/.vagrant.d/insecure_private_key
EOF
