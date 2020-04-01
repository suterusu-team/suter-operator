This repo contains various scripts to create and manage suterusu nodes.

# Quick start

## Provision with terraform
To create 3 ec2 instances for suterusu node in the region `ap-northeast-1`, run
```shell
terraform apply -var instance_count=3 -var aws_region=ap-northeast-1 ec2
```
This will also copy files under `caddy` to `~/.suter/node/` which can be used to set up suter node.

## Change dns record
Set up A-records for the newly created instances. This is required for wss access to the node server.

## Setup node and websocket access
Copy the files under the directory `caddy` to the server, and specify the domain for websocket access, with environment variable `TLS_DOMAIN`, then run

```shell
export TLS_DOMAIN=node.cluster.suterusu.io TLS_EMAIL=contact@suterusu.io SUTER_NODE_ EXTRA_ARGUMENTS="--bootnodes /dns4/alice.cluster.suterusu.io/tcp/30333/p2p/QmVe2vHDbgpXWTmgpkmG51DeaFTPWxanU2LqzHp7ZHqoTa"
docker-compose up
```

## Connect to node with suter_cli
Compile suter_cli with [suter_cli](https://github.com/suterusu-team/suter_cli/) and run
```shell
./wsclient.native -url https://node.cluster.suterusu.io -f ./tests/get_runtime_version.sut
```
