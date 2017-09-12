## /32 네트워크 sandox 환경

                   L3 S/W(sandbox, quagga, router-id 10.252.200.254)
                                       |
                                       |
                  -----------------------------------------  IBGP AS 10101
                  |                                        |
                  |                                        |
compute001(router-id 10.252.200.200)      compute002(router-id 10.252.200.201)

### 요구 사항

2개 이상의 compute host구성(compute000, compute001)으로 각각의 host는 neutron-dhcp-agent role 적용

## 구성

### vm configuration

```
export VAGRANT_VMS_CONFIG=vms-minimal32.json
export VAGRANT_PROVIDER_NETWORK=provider-network-32bit.json
```

### rack switch에 대응되는 sandbox에 quagga 구성

vagrant up, provision이 끝난 후

```
cd playbook
cp hosts.sample hosts
ansible-playbook -i hosts --connection=local quagga_bgp.yml
```

### /32를 위한 neutron network 생성

controller host에서

```
. /root/openrc
export NET_TYPE=32bit
export IP_POOL=10.252.101.10,10.252.101.250
/root/bin/os-vm-create.sh
```

### host-aggreate 편집

```
nova aggregate-create 32net 32net
nova aggregate-add-host 32net compute000
nova aggregate-set-metadata 32net networks=32net
```

### vm 생성 

```
nova keypair-add default > root.pem
chmod 600 root.pem
nova boot --flavor m1.small --image ubuntu-14.04 --availability_zone 32net --key-name default 32inst01
```

## 결과 확인
### 외부 환경(macbook) -> vm으로 ping 확인  

### vm간 ping 확인 
