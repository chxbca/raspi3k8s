echo 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-security main restricted universe multiverse' > sources.list
sudo rm /etc/apt/sources.list
sudo mv sources.list /etc/apt/sources.list
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
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo echo '{
  "registry-mirrors": [
    "https://registry.docker-cn.com"
  ]
}' >> daemon.json
sudo mv daemon.json /etc/docker/
sudo rm /usr/share/maven/conf/settings.xml 
sudo mv settings /usr/share/maven/conf
curl -fsSL 'https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg' | sudo apt-key add - 
sudo echo 'deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main' >> kubernetes.list
sudo mv kubernetes.list /etc/apt/sources.list.d/
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl