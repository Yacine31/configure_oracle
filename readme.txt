ansible sur le poste à configurer 

===

yum install -y wget bzip2 unzip

$ wget https://github.com/ownport/portable-ansible/releases/download/v0.4.2/portable-ansible-v0.4.2-py2.tar.bz2
$ tar xvfj portable-ansible-v0.4.2-py2.tar.bz2

$ ln -s ansible ansible-playbook

creer un fichier hosts.oracle avec le contenu suivant 

[local]
localhost ansible_connection=local


$ pwd = /root
récupérer mes playbooks dans /root
$ wget https://github.com/Yacine31/configure_oracle/archive/2020.09.10.zip

$ unzip 2020.09.10.zip

$ mv configure_oracle-2020.09.10/* .

$ python ansible-playbook book-config-oel-6-7.yml -i hosts.oracle
