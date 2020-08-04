echo "Install engines, please patient"
sudo apt-get update &> /dev/null

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common &> /dev/null
	
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null

sudo apt-key fingerprint 0EBFCD88 &> /dev/null

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   
sudo apt-get update &> /dev/null
sudo apt-get -y install docker-ce docker-ce-cli containerd.io &> /dev/null

sudo groupadd docker &> /dev/null

sudo usermod -aG docker vagrant &> /dev/null

echo "docker done..."
#echo "install theia"
sudo docker pull kdvolder/sts4-theia-snapshot &> /dev/null
sudo mkdir /home/vagrant/workspace
sudo chmod 777 /home/vagrant/workspace
sudo docker network create --subnet=172.18.0.0/16 devnetwork &> /dev/null
sudo docker run --name spring-theia  --net devnetwork --ip 172.18.0.22 --restart=always --init  -p 3000:3000 -p 8080:8080 -v "/home/vagrant/workspace:/home/project:cached" -d kdvolder/sts4-theia-snapshot:latest &> /dev/null
sudo docker run --name postgresdb --net devnetwork --ip 172.18.0.23 --restart=always -e POSTGRES_PASSWORD=mysecretpassword -d postgres &> /dev/null
echo "install some script"
sudo touch /.dbconnectscript.sh
sudo chmod 777 /.dbconnectscript.sh
echo "
	#!/usr/bin/env bash

	function connectdb() {                                                                                      
		docker exec -it postgresdb psql -U postgres
	} 
	
	function helppostgres(){
		echo '\l - list databases'
		echo '\c [dbname] connect to [dbname] db'
		echo 'SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';
      table_name - list tables of database'
	}
	
	function helpipaddress(){
		docker network inspect bridge
	}
" >> /.dbconnectscript.sh
printf '\n%s\n' 'source /.dbconnectscript.sh' >> ~/.bashrc
printf '\n %s \n' 'echo "use the helper functions: connectdb, helppostgress"' >> ~/.bashrc