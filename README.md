# TechBy Kube

Auth: 
- kubectl
  - `doctl kubernetes cluster kubeconfig save tech-by`
  - for ease of use
    - `kubectl config set-context --current --namespace=production`
- docker
  - `doctl registry login`

Kube-ui
- kubectl proxy
- http://127.0.0.1:8001/ui
- or just use version in DO dashboard

- create namespaces
  - kubectl apply -f namespaces/production.yaml
  - kubectl apply -f namespaces/staging.yaml

- create services (production)
  - `kubectl apply -f ./services --namespace="production"`

- create deployments (production)
  - `kubectl apply -f $(./template.sh production deployments/redis_cache.yaml)`
  - `kubectl apply -f $(./template.sh production deployments/elasticsearch.yaml)`
  - `kubectl apply -f $(./template.sh production deployments/scylla.yaml)`
  - `kubectl apply -f $(./template.sh production deployments/cassandra_web.yaml)`
  - `kubectl apply -f $(./template.sh production deployments/elasticsearch_hq.yaml)`
  - `kubectl apply -f $(./template.sh production deployments/scylla_proxy.yaml)`
  - yolo the rest (or deploy.sh update latest if container exists)




---
Initial setup stuff not listed above
- allow kubernetes to pull containers from DO registry
  - `doctl registry kubernetes-manifest --namespace=staging | kubectl apply -f - -n=staging`
  - `doctl registry kubernetes-manifest --namespace=production | kubectl apply -f - -n=production`
  - `kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-tech-by"}]}' -n=production`
  - `kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-tech-by"}]}' -n=staging`
