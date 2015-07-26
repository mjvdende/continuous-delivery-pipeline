# Continuous Delivery Pipeline 

Prerequisites

- [Vagrant](https://www.vagrantup.com/) + [VirtualBox](https://www.virtualbox.org/)

Given:

    git clone https://github.com/xebia/xta-dynamic-builds.git 
    cd coreos-vagrant

When:

    $ vagrant up

Then:

    start building!

It can take a while before services are running because docker is downloading images from the docker hub.
Therefor you can follow the progress of services booting when logging on to a core, for example core-02.

    $ vagrant ssh core-02
    $ journalctl -u jenkins.service -f

## Services Provided

### core-01

- docker.service
- docker-registry.service - URL: http://172.17.8.101:5000
- docker-registry-web.service - URL: http://172.17.8.101:8181
- gitbucket.service - URL: http://172.17.8.101:8282 (login:root-root)

### core-02

- docker.service
- jenkins.service - URL: http://172.17.8.102:8888

### core-03

- docker.service
- TODO

### Todo

- clean up exited containers
- make jenkins and docker registry data persistent 
- sonar, xlrelease, xlview 

## Config 

To start our cluster, we need to provide some config parameters in cloud-config format via the ```user-data``` file and set the number of machines in the cluster in ```config.rb```.
For each core a user-data file exists. Our cluster will use an etcd discovery URL to bootstrap the cluster of machines and elect an initial etcd leader. 
Be sure to replace <token> with your own URL from https://discovery.etcd.io/new in each user-data file. More info: [coreos - vagrant](https://github.com/coreos/coreos-vagrant)

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.network "private_network", ip: "172.17.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

