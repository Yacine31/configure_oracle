#!/bin/bash

## On entre seulement pour certains utilisateurs.
if [ $USER = "grid" ] || [ $USER = "oracle" ] || [ $USER = "root" ] ; then
    
     # Certaines operations ne sont pas a realiser pour root
     # les limites sont laissees par defaut
     # ainsi que le masque de creation de fichier ou le stty break.
    if [ $USER != "root" ] ; then
        # ajustement des limites
        if [ $SHELL = "/bin/ksh" ] ; then
            ulimit -p 16384
            ulimit -n 65536
            ulimit -s 32768
        else
            ulimit -u 16384 -n 65536
        fi
        ulimit -Hs 32768
        ulimit -Ss 10240

        # Masque de création des fichiers    
        umask 022

        # Pour prévention SSH
        if [ -t 0 ]; then
            stty intr ^C
        fi

        # Alias RL Wrap si disponible
        if [ `/bin/rpm -qa |grep -i rlwrap | wc -l` -eq 1 ] ; then
            alias sqlplus="rlwrap sqlplus"
            alias rman="rlwrap rman"
            alias asmcmd="rlwrap asmcmd"
            alias adrci="rlwrap adrci"      
            alias dgmgrl="rlwrap dgmgrl"
        fi
    fi

    # prompt coloré
    vert=$(tput setaf 2)
    bleu=$(tput setaf 4)
    gras=$(tput bold)
    rouge=$(tput setaf 1)
    reset=$(tput sgr0)

fi

export PS1='[\[$bleu\]\u\[$reset\]@\[$vert\]\h\[$reset\] \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
