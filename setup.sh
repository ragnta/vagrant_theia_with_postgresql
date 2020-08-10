
if ! [ -x "$(command -v docker)" ]; then
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
else
	echo "the engines are already installed."
fi

link_exists() {
	[ -L "$1" ];
}

if link_exists /usr/bin/nodejs && link_exists /usr/bin/yarn ; then
	echo "Node and yarn already installed"
else
	echo "Checkout mvn..."
	git clone https://github.com/creationix/nvm.git ~/.nvm &>/dev/null && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags` &>/dev/null
	source ~/.nvm/nvm.sh
	printf '\n%s\n' 'LINK_TO_NODE=/usr/bin/nodejs
	if test -f "$LINK_TO_NODE"; then
	  sudo rm "$LINK_TO_NODE"
	  sudo ln -s $(whereis node | cut -d " " -f2) /usr/bin/nodejs
	fi' >> ~/.bashrc
	echo "source ~/.nvm/nvm.sh" >> ~/.bashrc
	# install latest stable node.js
	echo "Installing node.js... (please be patient)"
	nvm install stable &> /dev/null
	nvm alias default stable

	LINK_TO_NODE=/usr/bin/nodejs
	if test -f "$LINK_TO_NODE"; then
	  sudo rm "$LINK_TO_NODE"
	fi
	sudo ln -s $(whereis node | cut -d " " -f2) /usr/bin/nodejs
	echo "Installing yarn... (please be patient)"
	curl -o- -L https://yarnpkg.com/install.sh 2>/dev/null | bash &> /dev/null
	sudo ln -s $(whereis yarn | cut -d " " -f2) /usr/bin/yarn
	
	echo "Set watchers... (please be patient)"
	echo fs.inotify.max_user_watches=16384 | sudo tee -a /etc/sysctl.conf &>/dev/null
fi 

FILE=/.dbconnectscript.sh
help_line='echo "use the helper functions: connectdb, helppostgres"'
source_line='source /.dbconnectscript.sh'
if [ -f  "$FILE" ]; then
	# TODO remove in the future
	help_line_tmp='echo "use the helper functions: connectdb, helppostgress"'
	source_line_for_sed='source \/\.dbconnectscript.sh'
	sudo rm /.dbconnectscript.sh
	sudo sed -i "/$source_line_for_sed/d" ~/.bashrc
	sudo sed -i "/$help_line/d" ~/.bashrc
	sudo sed -i "/$help_line_tmp/d" ~/.bashrc
fi
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
	
	function drop_db(){
		docker rm postgresdb --force &> /dev/null
		sudo docker run --name postgresdb --net devnetwork --ip 172.18.0.23 --restart=always -e POSTGRES_PASSWORD=mysecretpassword -d postgres &> /dev/null
	}
" >> /.dbconnectscript.sh
echo $source_line >> ~/.bashrc
echo $help_line >> ~/.bashrc