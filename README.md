# ubuntu-docker-swarm-setup

Scripts for setting up a Docker Swarm cluster - i.e. not SwarmKit 

- swarm-init.sh
- swarm-join.sh

## Example

```
vagrant up

# initialize the swarm
vagrant ssh manager
cd /vagrant
sudo ./swarm-init.sh
exit
```

![alt init](https://raw.githubusercontent.com/CExBBartolome/ubuntu-docker-swarm-setup/master/swarm-init.png)

```
# join the swarm cluster
vagrant ssh worker
cd /vagrant
sudo ./swarm-join.sh
exit
```

![alt join](https://raw.githubusercontent.com/CExBBartolome/ubuntu-docker-swarm-setup/master/swarm-join.png)

```
# check cluster info
vagrant ssh manager
docker -H :4000 info
```

![alt join](https://raw.githubusercontent.com/CExBBartolome/ubuntu-docker-swarm-setup/master/cluster-info.png)
