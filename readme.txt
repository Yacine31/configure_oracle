ansible sur le poste à configurer 
s'inspirer de l'exemple screen !

===

yum install -y wget bzip2

wget https://github.com/ownport/portable-ansible/releases/download/v0.4.2/portable-ansible-v0.4.2-py2.tar.bz2
tar xvfj portable-ansible-v0.4.2-py2.tar.bz2

ln -s ansible ansible-playbook

creer un fichier hosts.oracle avec le contenu suivant 

[local]
localhost ansible_connection=local

scp mes playbooks dans /root

merlin@Dell-E7440:~/scripts/configure_oracle $ scp -r * root@192.168.1.241:/root

ou rsync : 
merlin@Dell-E7440:~/scripts/configure_oracle $ rsync -av * root@192.168.1.241:/root

python ansible-playbook book-config-oel-6-7.yml -i hosts.oracle

