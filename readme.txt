ansible sur le poste à configurer 

===

$ pwd = /root

$ yum install -y wget bzip2 unzip git
# git clone https://github.com/Yacine31/configure_oracle
$ tar xfj configure_oracle/portable-ansible-v0.4.2-py2.tar.bz2
# ln -s ansible ansible-playbook
# python ansible-playbook configure_oracle/book-config-oel-6-7.yml -i configure_oracle/hosts.oracle
