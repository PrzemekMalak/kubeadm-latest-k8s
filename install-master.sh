#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm/

### setup terminal
apt-get install -y binutils
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'alias k=kubectl' >> ~/.bashrc



### install k8s and docker
apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni
apt-get autoremove -y
apt-get install -y etcd-client vim build-essential

systemctl daemon-reload
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt | sed -r 's/^.{1}//')"
apt-get update
apt-get install -y docker.io kubelet=${RELEASE}-00 kubeadm=${RELEASE}-00 kubectl=${RELEASE}-00 kubernetes-cni=0.8.7-00

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

# start docker on reboot
systemctl enable docker
systemctl enable kubelet && systemctl start kubelet


### init k8s
rm /root/.kube/config
kubeadm reset -f
kubeadm init --kubernetes-version=${RELEASE} --ignore-preflight-errors=NumCPU --skip-token-print

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo
echo "### COMMAND TO ADD A WORKER NODE ###"
kubeadm token create --print-join-command --ttl 0