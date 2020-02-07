### 安装 Ubuntu 18.04 

#### 下载镜像

```shell
wget http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.3-preinstalled-server-armhf+raspi3.img.xz
```

#### 解压并安装

```shell
# 找出TF卡挂载的路径
diskutil list
# 卸载TF卡
diskutil unmount /Volumes/usb
# 使用dd将镜像写入TF卡
# 参数if- 镜像文件名称
# 参数of- 输出地址
# 参数bs- 同时设置读写块的大小，单位是bytes
# 稍微要个十来分钟，完成后无提示
sudo dd if=${input} of=${output} bs=${block size}
# 例：if=./ubuntu-18.04.3-preinstalled-server-armhf+raspi3.img of=/dev/disk2 bs=4m
```

### 配置 Ubuntu 环境

#### 使用 SSH 连接树莓派

```shell
# 初次连接 密码默认ubuntu 初次登陆会让你修改密码
ssh ubuntu@${ip}

# 配置ssh免密登陆 
echo 'ssh-rsa ***' >> .ssh/authorized_keys 

# 配置Wi-Fi连接
sudo apt install ifupdown
sudo vim /etc/network/interfaces

# 在文件末尾加入如下内容
auto lo
iface lo inet loopback
iface eth0 inet dhcp
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-ssid "${ssid}"
wpa-psk "${pwd}"

# 改名 会要输入密码
hostnamectl set-hostname ${name}

# 重启以后就可以拔掉网线了
sudo reboot
```

#### 配置清华大学镜像

```
# 建议收藏 国内 18.04 arm 镜像挺少的
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释 
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-proposed main restricted universe multiverse
```

#### 安装 docker-ce
```shell
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
# 安装 GPG 证书
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# 新增软件源信息
sudo add-apt-repository "deb [arch=armhf] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

#### 配置 Docker 加速器
```shell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://uqvzue7x.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```


#### 安装 kubelet kubeadm kubectl
```shell
curl -fsSL 'https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg' | sudo apt-key add - 
sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl
```

### 安装 HAProxy + Keepalived

#### 安装HAProxy

```shell
#!/bin/bash
# 修改为你自己的 Master 地址
MasterIP1=192.168.141.150
MasterIP2=192.168.141.151
MasterIP3=192.168.141.152
# 这是 kube-apiserver 默认端口，不用修改
MasterPort=6443

# 容器将 HAProxy 的 6444 端口暴露出去
docker run -d --restart=always --name HAProxy-K8S -p 6444:6444 \
        -e MasterIP1=$MasterIP1 \
        -e MasterIP2=$MasterIP2 \
        -e MasterIP3=$MasterIP3 \
        -e MasterPort=$MasterPort \
        wise2c/haproxy-k8s
```

#### 安装Keepalived
```shell
#!/bin/bash
# 修改为你自己的虚拟 IP 地址
VIRTUAL_IP=192.168.141.200
# 虚拟网卡设备名
INTERFACE=ens33
# 虚拟网卡的子网掩码
NETMASK_BIT=24
# HAProxy 暴露端口，内部指向 kube-apiserver 的 6443 端口
CHECK_PORT=6444
# 路由标识符
RID=10
# 虚拟路由标识符
VRID=160
# IPV4 多播地址，默认 224.0.0.18
MCAST_GROUP=224.0.0.18

docker run -itd --restart=always --name=Keepalived-K8S \
        --net=host --cap-add=NET_ADMIN \
        -e VIRTUAL_IP=$VIRTUAL_IP \
        -e INTERFACE=$INTERFACE \
        -e CHECK_PORT=$CHECK_PORT \
        -e RID=$RID \
        -e VRID=$VRID \
        -e NETMASK_BIT=$NETMASK_BIT \
        -e MCAST_GROUP=$MCAST_GROUP \
        wise2c/keepalived-k8s
```

### 配置 kubernetes 集群

#### 配置 master 节点

```shell
# 导出配置文件
sudo kubeadm config print init-defaults --kubeconfig ClusterConfiguration > kubeconfig.yml

sudo vim kubeconfig.yml

……
localAPIEndpoint:
  # 修改为主节点 IP
  advertiseAddress: ${ip}
……
# 要配置高可用集群需在 controllerManager: {} 上添加这一条
controlPlaneEndpoint: "${vip_ip}:6444"
……
# 国内不能访问 Google，修改为阿里云
imageRepository: registry.aliyuncs.com/google_containers
……
networking:
  dnsDomain: cluster.local
  # 配置成 Calico 的默认网段 可能没有podSubnet，自行添加
  podSubnet: "192.168.0.0/16"
……

# kubernetes 初始化 1.15 版本前 --upload-certs 改为 --experimental-upload-certs 
sudo kubeadm init --config=kubeconfig.yml --upload-certs | tee kubeadm-init.log

# 安装网络插件 calico
sudo kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
```

#### 配置 node 节点
```shell
# 在初始化 master 节点时，若成功，在控制台和 kubeadm-init.log 文件中
# 会有如下命令，在安装完 kubeadm kubelet kubectl 后，直接复制输入即可

# 添加 master 节点
sudo kubeadm join ${ip:port} --token ${token} \
    --discovery-token-ca-cert-hash sha256:${sha256}
    --control-plane --certificate-key ${certificate-key}

# 添加 node 节点
sudo kubeadm join ${ip:port} --token ${token} \
    --discovery-token-ca-cert-hash sha256:${sha256}
```