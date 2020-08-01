docker run -i --rm --name redis -p 6379:6379 -v /data:/data -t redis:6.0.6
docker run -i --rm --name scylla -p 9042:9042 -v /var/lib/scylla:/var/lib/scylla -t scylladb/scylla:4.1.3
docker run -p 9200:9200 -p 9300:9300 -v /data:/data -e "discovery.type=single-node" -e "cluster.routing.allocation.disk.threshold_enabled=false" -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" docker.elastic.co/elasticsearch/elasticsearch-oss:7.8.1
