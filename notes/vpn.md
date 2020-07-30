- choose a droplet
- reset root password (unless you know it)
- currently on standard-3rjfy
- give vpn firewall in do dashboard
  - if it doesn't exist, networking -> firewall -> create firewall -> ssh + custom tcp 1194
- ssh root@<ip for droplet>
- add dns record pointing vpn to the ip

- export OVPN_DATA="ovpn-data"
- docker volume create --name $OVPN_DATA
- docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u tcp://vpn.techby.org:1194
- docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn ovpn_initpki
- start: (may also need `export OVPN_DATA="ovpn-data"`)
- docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn

- docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full techbyvpn
- docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient techbyvpn > techbyvpn.ovpn
- cat techbyvpn.ovpn
- copy file over to secrets
- need to add "comp-lzo" after "remote-cert-tls server"
- sudo ovpn techbyvpn.ovpn


to point to scylla
  - kubectl port-forward elasticsearch-0 9200
elasticsearch
  - kubectl port-forward scylla-0 9042