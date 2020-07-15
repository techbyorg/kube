https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes

http challenge didn't work, so had to use dns 
  - https://stackoverflow.com/questions/61797014/error-broken-header-get-well-known-acme-challeng-with-letsencrypt-on-kuberna
  - use cloudflare dns, not digitalocean though https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/

kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/do/deploy.yaml


kubectl create -f ingresses/issuers/prod_issuer.yaml
kubectl create -f ingresses/issuers/staging_issuer.yaml
kubectl create -f services/main_ingress.yaml
kubectl apply -f ingresses/main_ingress.yaml

kubectl get certificates
kubectl get ingresses