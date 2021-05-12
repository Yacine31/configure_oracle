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
# git clone https://github.com/Yacine31/configure_oracle


# python ansible-playbook configure_oracle/book-config-oel-6-7.yml -i hosts.oracle
