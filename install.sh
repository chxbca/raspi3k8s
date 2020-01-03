sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=armhf] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo echo '{
  "registry-mirrors": [
    "https://registry.docker-cn.com"
  ]
}' >> daemon.json
sudo mv daemon.json /etc/docker/

curl -fsSL 'https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg' | sudo apt-key add -
sudo echo 'deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main' >> kubernetes.list
sudo mv kubernetes.list /etc/apt/sources.list.d/
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubeadm kubelet kubectl