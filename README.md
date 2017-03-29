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

# join the swarm cluster
vagrant ssh worker
cd /vagrant
sudo ./swarm-join.sh
exit
```
