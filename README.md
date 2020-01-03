### 安装 Ubuntu 18.04 

#### 下载镜像

```
wget http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.3-preinstalled-server-armhf+raspi3.img.xz
```

#### 解压并安装

```
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

```
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
```
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
```
sudo echo '{
  "registry-mirrors": [
    "https://registry.docker-cn.com"
  ]
}' >> daemon.json
sudo mv daemon.json /etc/docker/
```


#### 安装 kubelet kubeadm kubectl
```
curl -fsSL 'https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg' | sudo apt-key add - 
sudo echo 'deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main' >> kubernetes.list
sudo mv kubernetes.list /etc/apt/sources.list.d/
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl
```

### 配置 kubernetes 集群

#### 配置 master 节点

```
# 创建 docker 文件夹
mkdir /usr/local/docker/

# 创建 kubernetes 文件夹
mkdir /usr/local/docker/kubernetes

# 导出配置文件
kubeadm config print init-defaults --kubeconfig ClusterConfiguration > kubeadm.yml

……
localAPIEndpoint:
  # 修改为主节点 IP
  advertiseAddress: ${ip}
……
networking:
  dnsDomain: cluster.local
  # 配置成 Calico 的默认网段 可能没有podSubnet，自行添加
  podSubnet: "192.168.0.0/16"
……

# kubernetes 初始化 1.15版本前 --upload-certs 改为 --experimental-upload-certs 
kubeadm init --config=kubeadm.yml --upload-certs | tee kubeadm-init.log

# 安装网络插件 calico
kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
```

#### 配置 node 节点
```
# 在初始化 master 节点时，若成功，在控制台和 kubeadm-init.log 文件中
# 会有如下命令，在安装完 kubeadm kubelet kubectl 后，直接复制输入即可
kubeadm join ${ip:port} --token ${token} \
    --discovery-token-ca-cert-hash sha256:${sha256}
```