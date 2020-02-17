### Istio 安装

#### 安装 Helm

```shell
# Helm 可以理解成 kubernetes 的包管理器
wget https://get.helm.sh/helm-v2.16.3-linux-arm64.tar.gz
tar -zxf helm-v2.16.3-linux-arm64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```

#### 安装服务端 Tiller

```shell
# 注意安装的版本要一致 如：helm-v2.16.3  tiller:v2.16.3
helm init --service-account tiller --tiller-image registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.16.3 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```

### 给 Tiller 授权

```shell
vi rabc-tiller.yml
# 输入如下内容保存
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
# 完
kubectl apply -f rabc-tiller.yml
```

#### 查看是否授权成功

```shell
kubectl get deploy --namespace kube-system tiller-deploy --output yaml | grep serviceAccount
# 输出如下
serviceAccount: tiller
serviceAccountName: tiller
```

#### 验证是否安装完成

```shell
kubectl -n kube-system get pods | grep tiller
# 输出如下
tiller-deploy-6d74cd8c9d-v6zg4              1/1     Running   0          10m
# 查看 helm 版本信息
helm version
```

#### 使用 helm 安装 Istio

```shell
# 添加istio库
helm repo add istio.io https://storage.googleapis.com/istio-release/releases/1.5.0/charts/

# 安装istio-init图表以引导所有Istio的CRD
helm install istio.io/istio-init --name istio-init --namespace istio-system	

# 打印出23就完成
kubectl get crds | grep 'istio.io' | wc -l

# 安装istio
helm install istio.io/istio --name istio --namespace istio-system

# 查看是否安装完成 STATUS为Completed或Running即可
watch kubectl get pods -n istio-system
```

