https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes

kubectl create namespace cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/do/deploy.yaml

kubectl apply -f ingresses/issuers/prod_issuer.yaml
kubectl apply -f ingresses/issuers/staging_issuer.yaml
kubectl apply -f ingresses/main_ingress.yaml

- https://www.digitalocean.com/community/questions/how-do-i-correct-a-connection-timed-out-error-during-http-01-challenge-propagation-with-cert-manager
  - kubectl patch service ingress-nginx-controller -n=ingress-nginx -p '{"metadata": {"annotations": {"service.beta.kubernetes.io/do-loadbalancer-hostname": "dns.techby.org"}}}'
    - dns.techby.org points to loadbalancer ip
  - if that doesn't work
    - kubectl patch service ingress-nginx-controller -n=ingress-nginx -p '{"spec": {"externalTrafficPolicy": "Cluster"}}'

kubectl get certificates
kubectl get ingresses

---

- if using dns challenge:
  - https://stackoverflow.com/questions/61797014/error-broken-header-get-well-known-acme-challeng-with-letsencrypt-on-kuberna
  - use cloudflare dns, not digitalocean though https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/
