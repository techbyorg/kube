
# Generate ovpn
- Run: `./vpn.sh <your_name_no_spaces>`

# Initial setup
Easiest way to setup openvpn on k8s seems to be with Helm...

- `helm repo add stable http://storage.googleapis.com/kubernetes-charts`
- `kubectl create namespace vpn`
- `helm install stable/openvpn --name-template vpn --namespace vpn --set persistence.size=1Gi`
- optional:
  - wait a few minutes for ip to get set
  - `kubectl get services -n=vpn`
    - add a CNAME for vpn.techby.org to external ip
  - the vpn.sh script right now just points to the ip, not vpn.techby.org

