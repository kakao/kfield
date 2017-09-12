# Kfield 환경 구축하기
# 기본 요구 사항
 - OS: Ubuntu 14.04 (Trusty)
 - User: Non-root mode
 - Intel VT-X option이 BIOS에서 활성화

## VT-X 활성화 여부 확인
```sh-session
$ sudo kvm-ok
NFO: /dev/kvm exists
KVM acceleration can be used
```
`kvm-ok`
명령어로 위의 결과를 얻지 못하면 현재 사용중인 서버는 VT-X옵션이 비활성화 상태다.

## 시작하기 전에
이전에 Rubygems를 통해서 관련된 패키지를 다운받은 적이 있는 경우에는 삭제한다.
```Shell
gem uninstall chef knife vagrant berkshelf -aIx
```
기본적으로 필요한 패키지들을 설치한다.
```Shell
sudo apt-get install -qqy make gcc g++ autoconf
```

## Kfield 다운로드하기
```Shell
git clone https://github.com/kakao/kfield.git
```

# 기본환경 설정
## ChefDK 설치하기
ChefDK(Chef Development Kit)을 [ChefDK Homepage](https://downloads.getchef.com/chef-dk/ubuntu/) 에서 내려받고,
`dpkg`를 통해서 설치한다.
```Shell
sudo dpkg -i chefdk_$VERSION_amd64.deb
```
혹은 아래와 같은 스크립트를 이용해서 다운 받는다.
```Shell
function setproxy ()
{
    p=http://proxy.proxyserver.io:3128;
    n=localhost,127.0.0.1,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,$(hostname -i),$ADDITIONAL_NO_PROXY;
    http_proxy=$p https_proxy=$p HTTP_PROXY=$p HTTPS_PROXY=$p no_proxy=$n NO_PROXY=$n $@
}

latest_chefdk=$(setproxy curl -sL https://packages.chef.io/stable/ubuntu/12.04/ | grep chefdk | grep -v asc | cut -d'>' -f3- | cut -d'<' -f1 | sort -V | tail -n1)
setproxy curl -sL https://packages.chef.io/stable/ubuntu/12.04/$latest_chefdk -o $latest_chefdk
sudo dpkg -i $latest_chefdk
```

Kfield에서는 ChefDK에 내장된 ruby를 사용하므로 아래의 설정을 통해서 shell에서 ChefDK의 ruby를 사용할 수 있도록 한다.
```Shell
echo 'eval "$(chef shell-init bash)"' >> ~/.profile
source ~/.profile
```

ChefDK의 ruby가 사용되고 있음을 확인한다.
```sh-session
$ which ruby
/opt/chefdk/embedded/bin/ruby
```

## Ruby 패키지 설치
### Rubygem 서버 등록하기
Kfield에서 ruby는 ChefDK와 후술할 Vagrant에서 제공하는 것을 각기 사용한다.
당사 proxy 환경과 같이 공통적으로 적용되어야 할 설정이 있다.
`.gemrc`는 서로 다른 버전의 rubygem을 사용하여도 파일에 기록된 설정값을 읽어들여
모두 동일한 설정을 사용할 수 있도록 해준다.

```Shell
echo "---
:backtrace: false
:bulk_threshold: 1000
:sources:
- http://ftp.daumkakao.com/rubygems/
:update_sources: true
:verbose: true
benchmark: false" | tee ~/.gemrc
```

## libvirt 설치하기
### libvirt의 의존성 설치하기
libvirt를 사용하기 위해서 필요한 의존성 패키지들을 설치한다.
```Shell
sudo apt-get install -qqy liblzma-dev zlib1g-dev libxslt1-dev libxml2-dev \
libvirt-dev libvirt-bin dnsmasq qemu-kvm qemu-utils
```
Libvirt의 virsh를 non-root에서 사용하기 위해서 현재 user(e.g., deploy)를 `libvirtd` 그룹에 등록한다.
```Shell
sudo -i
adduser deploy libvirtd
exit
```
KSM은 높은 cpu를 사용하기 때문에 꺼둔다.
```
sudo sed -i 's/KSM_ENABLED=1/KSM_ENABLED=0/g' /etc/default/qemu-kvm
sudo restart qemu-kvm
```

**주의! libvirtd 그룹에  deploy가 추가되어야 하기때문에 가능한 해당 머신에서 logout 다시 로그인을 해야 한다.**
```Shell
exit
ssh $MACHINE
```


### virsh 명령의 자동완성
`virsh` 명령어들의 자동완성 스트립트를 다운로드한다.
```Shell
https_proxy=proxy.server.io:8080 \
curl -s -L https://raw.githubusercontent.com/LuyaoHuang/virsh-bash-completion/master/virsh_bash_completion \
| sudo tee /etc/bash_completion.d/virsh
```

### Libvirt default network 비활성화
아래의 명령은 반드시 non-root user로 실행되는 것을 확인한다.
```Shell
virsh net-undefine default
virsh net-destroy default
```

## dnsmasq 설정하기
dnsmasq의 설정을 변경하여 localhost(127.0.0.1)로 listen하도록 변경한다.
```Shell
sudo sed -i 's/#listen-address=/listen-address=127.0.0.1/g' /etc/dnsmasq.conf
sudo sed -ri 's/^(except-interface)/#\0/' /etc/dnsmasq.d/libvirt-bin
```

## Network 설정하기
### ovs 설치
```Shell
sudo apt-get install -qqy openvswitch-switch
```

### IP포워딩 및 DNS 설정
`resolvconf` 패키지를 삭제한다.
```Shell
echo 'resolvconf resolvconf/reboot-recommended-after-removal select true' | sudo debconf-set-selections
sudo apt-get purge -qqy resolvconf
```

IP forwarding 설정을 한다.
```Shell
sudo -i
iptables -t nat -A POSTROUTING -j MASQUERADE -o eth0
sysctl net.ipv4.ip_forward=1
exit
```

DNS에 Kfield에서 사용할 호스트들을 등록한다.
```Shell
echo '''search stack kr.your.com kr2.your.com kr3.your.com
nameserver 127.0.0.1
nameserver 10.20.30.40''' | sudo tee /etc/resolv.conf

sudo service dnsmasq restart
```

서버가 Reboot되더라도 동일한 Network설정을 유지할 수 있도록 `rc.local` 스크립트에 적용한다.
```Shell
sudo sed -i '/exit 0/d' /etc/rc.local
echo """iptables -t nat -A POSTROUTING -j MASQUERADE -o eth0
sysctl net.ipv4.ip_forward=1
echo ''' search stack kr.your.com kr2.your.com kr3.your.com
nameserver 127.0.0.1
nameserver 10.20.30.40''' | tee /etc/resolv.conf
service dnsmasq restart
exit 0""" | sudo tee -a /etc/rc.local
```

## Vagrant
### Vagrant 설치
[Vagrant Homepage](http://www.vagrantup.com/downloads.html)에서 Vagrant 설치파일을 내려받고,
`dpkg`를 이용하여 설치한다.
```Shell
sudo dpkg -i vagrant_$VERSION_x86_64.deb
```
혹은 아래와 같은 스크립트를 이용한다.
```Shell
function setproxy ()
{
    p=http://proxy.server.io:8080;
    n=localhost,127.0.0.1,127.0.0.0/8,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,$(hostname -i),$ADDITIONAL_NO_PROXY;
    http_proxy=$p https_proxy=$p HTTP_PROXY=$p HTTPS_PROXY=$p no_proxy=$n NO_PROXY=$n $@
}

** vagrant 최신버전인 1.8.4는 현재 버그가 발견되어서, 1.8.1을 사용한다.
latest_vagrant_ver=1.8.1
setproxy curl -sL https://releases.hashicorp.com/vagrant/${latest_vagrant_ver}/vagrant_${latest_vagrant_ver}_x86_64.deb -o vagrant_${latest_vagrant_ver}_x86_64.deb
sudo dpkg -i vagrant_${latest_vagrant_ver}_x86_64.deb
```

Vagrant 명령어들의 자동완성 스크립트를 내려받는다.
```Shell
https_proxy=proxy.server.io:8080 \
curl -s -L https://raw.githubusercontent.com/kura/vagrant-bash-completion/master/etc/bash_completion.d/vagrant \
| sudo tee /etc/bash_completion.d/vagrant
```

### Vagrant Plugins
Kfield는 Vagrant plugin 설치를 위한 스트립트를 제공하고 있다.
스크립트를 실행하여 필요한 Plugin들을 설치한다.
```Shell
bash -x vagrant_plugins.sh
```

### Berkshelf
Berkshelf는 Chef cookbook의 의존성들을 관리해주는 툴이다.
Kfield는 Vagrant를 이용하여 VM를 생성하고 각 VM에 설치될 cookbook들의 의존성을 Berkshelf를 통해서 해결한다.
Kfield가 사용할 cookbook들의 의존성들을 설치한다.
만약 재설치 하려면 아래 스크립트로 기존 berks로 올라간 쿡북들 및 디펜던시들을 삭제한다.
```Shell
# delete all installed cookbooks
rm -rf ~/.berkshelf/
KFIELD=${KFIELD:-/home/deploy/kfield}
cd $KFIELD
rm -f Berksfile.lock
```

### Vagrant를 위한 ssh client설정
Vagrant를 통해서 생성될 VM들을 SSH로 접근하기 위해서, 호스트 SSH client의 config 파일에 아래의 내용을 추가한다.
`$KFIELD`에는 호스트에 내려받은 Kfield 소스의 절대 경로를 대입한다.
```Shell
echo '''Host db0 lb0 control0 compute000 swift0 glb0 gdb0 gcontrol0
User vagrant
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
PasswordAuthentication no
IdentityFile $KFIELD/.vagrant/machines/%h.stack/libvirt/private_key
IdentitiesOnly yes
LogLevel FATAL

Host *.stack
User vagrant
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
PasswordAuthentication no
IdentityFile $KFIELD/.vagrant/machines/%h/libvirt/private_key
IdentitiesOnly yes
LogLevel FATAL
''' | tee /home/deploy/.ssh/config
chmod 644 ~/.ssh/config
```

### kfield 사용전 필요한 설정
kfield는 chef-zero 라는 daemon 을 띄우고 그 안에 chef 정보들을 업로드해서 사용한다.
그렇기 때문에 vagrant 로 배포하기 전에 chef-zero를 띄우고 berks, knife command들로 직접 업로드 해야 한다.
이런 커맨드를 직접입력하는 것이 불편하다면 아래와 같은 함수들을 bash에 설정함으로 보다 간편히 사용가능하다.
```Shell
function run_chef_zero() {
  server=$(curl -is http://$(hostname -i):4000/ | awk '/^Server: /{print $2}')
  if [[ "$server" != "chef-zero" ]]; then
    /opt/chefdk/embedded/bin/chef-zero --host $(hostname -i) --port 4000 -d
  fi
}

function berks() {
    if [[ $1 == "install" || "$#" == 0 ]]; then
        p=http://proxy.server.io:8080
        n=localhost,127.0.0.1,$(hostname -i)
        http_proxy=$p https_proxy=$p HTTP_PROXY=$p HTTPS_PROXY=$p no_proxy=$n NO_PROXY=$n command berks
    else
        command berks "$@"
    fi
}

function vagrant() {
    if [[ "${PWD##*/}" == "kfield" ]]; then
        if [[ $1 == "up" || $1 == "provision" ]]; then
            if [[ ! -f knife.rb ]]; then
                echo """chef_server_url 'http://$(hostname -i):4000'
node_name 'zero-host'
client_key './.chefzero/fake.pem'""" | tee knife.rb
            fi
            run_chef_zero && \
            berks install && \
            berks install && \
            berks upload --force && \
            knife role from file roles/*.rb && \
            knife environment from file environments/*.rb && \
            command vagrant "$@"
        elif [[ $1 == "destroy" && ( $2 == "" || $2 == "-h" || $2 == "-f" ) ]]; then
            command vagrant "$@"
            pid=$(lsof -i tcp:4000 | grep -E 'ruby|chef-zero' | awk '{print $2}')
            if [[ "$pid" != "" ]]; then
                kill -15 $pid
            fi
        else
            command vagrant "$@"
        fi
    else
        command vagrant "$@"
    fi
}

alias v='vagrant'
alias vs='vagrant status'
alias vh='TERM=xterm-color vagrant ssh'
# 만약 alias 안에서 function을 호출하기 위해 \ 를 붙인다.
alias vu='\vagrant up'
alias vd='\vagrant destroy -f'
alias vp='\vagrant provision'
alias vun='\vagrant up --no-provision'
```

# Kfield 사용환경 구성하기
## VLAN을 사용하는 환경
Kfield의 개발환경은 VLAN을 사용하는 네트워크 모델(i.e., v1 모델)을 기본으로 하고 있으며, VLAN환경에서는 기본적으로 5개의 VM을 생성한다.
각 VM에는 그 목적(i.e., DB, Controller, Compute Node, Switft, LB)에 따라 Openstack 서비스를 구성한다.
Kfield는 Vagrant를 이용하여 VM을 생성하고 사전에 정의된 내용(i.e., Chef cookbook)에 따라 필요한 패키지나 소스등을 설치한다.
아래의 명령어를 통해서 Openstack 서비스들이 설치될 VM들을 생성한다.
(node의 구성은 `$KFIELD/config/vms-minimal.json` 파일을 참조)

기본적인 knife를 생성하고 chef-zero를 실행한다. (위의 bash function을 세팅했으면 넘어간다.)
```Shell
KFIELD=${KFIELD:-/home/deploy/kfield}
cd $KFIELD

if [[ ! -f knife.rb ]]; then
    echo """chef_server_url 'http://$(hostname -i):4000'
node_name 'zero-host'
client_key './.chefzero/fake.pem'""" | tee knife.rb
fi

server=$(curl -is http://$(hostname -i):4000/ | awk '/^Server: /{print $2}')
if [[ "$server" != "chef-zero" ]]; then
    /opt/chefdk/embedded/bin/chef-zero --host $(hostname -i) --port 4000 -d
fi
```

관련 쿡북을 다운로드 및 업로드 한다. (위의 bash function을 세팅했으면 넘어간다.)
```Shell
p=http://proxy.server.io:8080;
n=localhost,127.0.0.1,$(hostname -i);
http_proxy=$p https_proxy=$p HTTP_PROXY=$p HTTPS_PROXY=$p no_proxy=$n NO_PROXY=$n berks install
# 두번 업로드 한다.
http_proxy=$p https_proxy=$p HTTP_PROXY=$p HTTPS_PROXY=$p no_proxy=$n NO_PROXY=$n berks install
berks upload --force
```

관련 role과 environment를 업로드 한다.  (위의 bash function을 세팅했으면 넘어간다.)
```Shell
knife role from file roles/*.rb
knife environment from file environments/*.rb
```

VM을 생성 및 배포한다.
```Shell
vagrant up
```

만약 개별적으로 실행하려면 다음과 같은 순서로 진행하면 좋다.
다음의 명령어를 통해서 각 VM의 기능에 알맞는 Openstack 서비스와 관련된 패키지들을 설치(provisioning)한다.
```Shell
vagrant up db0.stack
vagrant up lb0.stack

vagrant up control0.stack
vagrant up compute000.stack
vagrant up swift0.stack
```

## Hostroute를 사용하는 환경
Kfield 개발환경에서 hostroute를 사용하는 네트워크 모델(i.e., v2 모델)을 구성하고자 한다면 사용자는 아래와 같이 환경변수를 설정하여 구성할 수 있다.

```Shell
export VAGRANT_VMS_CONFIG=vms-minimal32.json
export VAGRANT_PROVIDER_NETWORK=provider-network-32bit.json
```

이후 v1 모델과 동일하게 `vagrant up`을 실행하여 Kfield 개발환경을 설정한다.

### Quagga 설정하기
hostroute를 사용하는 개발환경에서는 개발장비(i.e., sandbox)가 TOR(Top of the Rack) switch / router의 역할을 한다. 이 역할을 하기 위해서 아래와 같이 개발 장비에 quagga 라는 software routing suite daemon을 설치하고 설정한다.
```Shell
cd ${KFIELD}/playbook
cp hosts.sample hosts
ansible-playbook -i hosts --connection=local quagga_bgp.yml
```

ansible이 설치되어 있지 않았다면 아래의 명령어로 ansible를 설치한다.
```Shell
sudo apt-get install ansible
```

## Kfield 사용하기
### 호스트에서 Openstack 서비스 VM으로 접속하기
```Shell
vagrant ssh $NODE_NAME
```

또는 [SSH Config](#ssh_config) 했다면 아래와 같이 접속이 가능하다.
```Shell
ssh $NODE_NAME
```

# Openstack 사용해보기
이로서 Kfield를 이용한 Openstack 테스트 환경을 구축하였다. 사용자는 필요에 따라서:
* Network zone 생성 및 Availability zone 정의 및 VM Instance(s) 생성 (`$KFIELD/utils/nova_setup.sh` 참조, control 서버에서 /vagrant/utils/nova_setup.sh 실행)
* swift 설정 (`$KFIELD/utils/swift_setup.sh` 참조, swift 서버에서 /vagrant/utils/swift_setup.sh 실행)

등을 실습 / 테스트 할 수 있다.

# Troubleshooting
## Delete warning
`vagrant up` 중에 아래의 메세지가 거슬린다면:
```sh-session
W, [2015-02-11T15:14:19.058573 #19603]  WARN -- : Terminating task: type=:finalizer, meta={:method_name=>:__shutdown__}, status=:receiving
    Celluloid::TaskFiber backtrace unavailable. Please try `Celluloid.task_class = Celluloid::TaskThread` if you need backtraces here.
W, [2015-02-11T15:14:19.067521 #19603]  WARN -- : Terminating task: type=:finalizer, meta={:method_name=>:__shutdown__}, status=:receiving
    Celluloid::TaskFiber backtrace unavailable. Please try `Celluloid.task_class = Celluloid::TaskThread` if you need backtraces here.
W, [2015-02-11T15:14:19.071279 #19603]  WARN -- : Terminating task: type=:finalizer, meta={:method_name=>:__shutdown__}, status=:receiving
    Celluloid::TaskFiber backtrace unavailable. Please try `Celluloid.task_class = Celluloid::TaskThread` if you need backtraces here.
```
`~/.vagrant.d/gems/gems/celluloid-0.16.0/lib/celluloid/tasks.rb` 를 편집기로 열어서 아래와 같이 해당 부분을 comment-out 한다.
```Ruby
115: def terminate
116:  raise "Cannot terminate an exclusive task" if exclusive?
117:
118:   if running?
119:     #Logger.with_backtrace(backtrace) do |logger|
120:     #  logger.warn "Terminating task: type=#{@type.inspect}, meta=#{@meta.inspect}, status=#{@status.inspect}"
121:     #end
122:     exception = Task::TerminatedError.new("task was terminated")
123:     exception.set_backtrace(caller)
```

