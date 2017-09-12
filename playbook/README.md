## 지원하는 OS

 * Ubuntu 14.04

## Usage
   

### Kfield 준비
   - hosts 파일 생성. hosts.sample 파일 참고
   - ansible 실행
   
     ```
	 ansible-playbook -i hosts --connection=local site.yml 
     ```
   - 이후 재로그인 필요
     - vms_config=vms-minimal.json로 ~/.bashrc로 설정하는데 이것을 적용함

### 테스트용 VM 준비
  config/vms-minimal.json 기준

	./vagrantup.sh
  
  openstack에서 사용할 network를 생성하기 위해서 control0.stack에 접속해서 gen_vm_network_security.sh를 실해시켜 주어야 함.
  gen_vm_network_security.sh는 직접 vm에 넣어 주세요~
      
    vagrant ssh control0.stack
    sudo su -
    gen_vm_network_security.sh
    
     
  
### OpenVPN Client Setup
사무실 PC에서 IDC에 있는 서버의 Horizon에 접속하기위해서 VPN설정이 필요함.

playbook을 실행하면 아래 위치에 [tunnelblick](https://code.google.com/p/tunnelblick/wiki/DownloadsEntry#Tunnelblick_Beta_Release) 용
설정파일이 있으므로 사무실 PC에 설치한다.

    /etc/openvpn/easy-rsa/deploy.tar.gz
