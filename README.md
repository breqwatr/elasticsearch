# Elasticsearch

## Build Image
Clone this repo and run following command to build elasticsearch docker image.
```
docker build . -t <image-name>:<image-tag>
```

## Max map count
Now check the max map count value on the host on which elasticsearch container will be running.
```
sysctl vm.max_map_count
```
It should be equal to 262144. Run following command if it has a different value.
```
sysctl -w vm.max_map_count=262144
```

## Elasticsearch.yml and data directory
Create elasticsearch.yml file but don't add xpack configurations in it. These configurations should be there in elasticsearch.yml:
```
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
```

Also create a data directory and 
set 777 permission for it.
```
mkdir data
chmod 777 data
```

## Elasticsearch container
Elasticsearch container can be created with authentication enabled or disabled.

### Elasticsearch without Password Auth
```
# Can omit SECURITY_ENABLE=false --env HEAP_SIZE=<heap-size>
# Default value of SECURITY_ENABLE is false (no password authentication)
docker run  -d -it  --name <container-name> \
  --env SECURITY_ENABLE=false --env HEAP_SIZE=<heap-size> \
  --network host \
  -v /<path-to>/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
  -v /<path-to>/data/:/var/lib/elasticsearch <image-name>:<tag>
```

### Elasticsearch with Password Auth
```
docker run  -d -it  --name <container-name> \
  --env SECURITY_ENABLE=true --env HEAP_SIZE=<heap-size> \
  --network host \
  -v /<path-to>/elasticsearch.yml:/etc/elasticsearch/elasticsearch.yml \
  -v /<path-to>/data/:/var/lib/elasticsearch <image-name>:<tag>
```
After a minute or so, `/passwords` file will be created inside container. 
That file contains passwords for all user. Copy that file to host.

```
docker cp <container-name>:/passwords . 
```
Verify if authentication is enabled.
`curl <elasticsearch-ip>:<port>` will fail.
Now run it with username and password.
```
# Use any user for passwords file
curl <elasticsearch-ip>:<port> -u <username>:<password>
```

## Connecting fluentd with elasticsearch (Kolla-ansible)
Open globals file and comment central logging related configs which includes elasticsearch and kibana.
Then put following configs in globals.yml.
```
enable_central_logging: "no"
fluentd_elasticsearch_user: "elastic"
fluentd_elasticsearch_password: <elastic-user-pass>
elasticsearch_address: <elasticsearch-ip>
elasticsearch_port: "9200"
```
Then reconfigure the cloud.
