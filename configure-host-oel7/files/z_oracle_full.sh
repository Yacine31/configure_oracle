#!/bin/bash
#########################################################################
#########################################################################
## Fichier de configuration d'environnement Oracle
## Pour infrastructure cluster ou standalone.
## Versions testees: 12.1, 11.2 GI et SA, flex/normal
##
## 2014-08-13   YOM   Correction de l'emplacement des journaux cluster vers ADR en 12c
## 2014-08-13   YOM   Correction concernant la détection Restart en 12c (olsnodes réponds...)
## 2014-08-20   YOM   Correction des alias crsstat et crsstati pour implémenter les variables ORA_CRS car elles ne doivent pas être laissées dans l'environnement
## 2014-12-02   YOM   Correction du prompt par défaut
## 2014-12-03   YOM   Suppression des alias crsstat et crsstati pour les transformer en scripts
## 2014-12-04   YOM   Ajout de l'alias OH pour un « cd $ORACLE_HOME »
## 2015-01-21   YOM   Test si le terminal est interractif pour éviter les erreurs TPUT en v7
## 2016-02-15   YOM   Ajout de l'alias « cdt » sur demande de PIL
## 2016-02-16   YOM   Paramétrage de la mise à niveau de l'invite de commande
## 2016-02-25   YOM   Modifications comportementales pour faciliter l'execution
## 2016-03-29   YOM   12.2 : changement de la conf ulimit pour être OK préco (fonction ajustement_limites)
## 2016-03-04   YOM   . Modification du test de démarrage du cluster à cause de la 12c qui change le comportement olsnodes
##                    . Ajout d'un critère supplémentaire lié à l'alias cdt si le cluster est arrêté
## 2016-04-07   YOM   . Ajout de l'alias SID pour la gestion facile de l'environnement
##                    . Ajustement de la zone d'exploitation
## 2016-06-28   YOM   Rectification d'un problème si le cluster est arrêtée qui provoquait unn affichage d'erreur bash non voulu
## 2016-09-05   YOM   Changement de l'alias « alert » pour limiter la largeur de ligne d'affichage
## 2016-09-16   YOM   Utilisation des fichiers du vocabulaire RLWrap si ils sont présents (demande de THT)
## 2017-05-16   YOM   Modification de la présentation de fonction (retrait des ()) pour une meilleure compatibilité
## 2017-08-23   YOM   Création d'un fichier qui stocke la configuration repérée afin de ne pas systématiquement recalculer l'ensemble du paramétrage
## 2019-01-08   THT   Arret de l'utilisation de local dans la fonction charge pour la variable lNODE_INFO, car l'utilisation de local donnait toujours un code retour à 0
## 2019-01-23   THT   Ajout de opatch dans le PATH de grid  et oracle
#########################################################################

## Activation des echo pour DEBUG si mis à 1
DEBUG=0

## Invite de commande sympa à activer (1 pour activé, 0 pour dormant) :
ORAC_INV_C=1
GRID_INV_C=1
ROOT_INV_C=1

## Contexte
APP_CTX=z_oracle.sh
HOSTNAME_SIMPLE=`hostname -s`

## Shell interactif ou non ?
fd=0
if [[ $- = *i* ]]
then
  INTERACTIF=OUI
else
  INTERACTIF=NON
fi

## Ajustement des limites (préconisations Oracle)
function ajustement_limites {
    decho fonction ajustement limites
    if [ $SHELL = "/bin/ksh" ] ; then
        ulimit -p 16384
        ulimit -n 65536
        ulimit -s 32768
    else
        ulimit -u 16384 -n 65536
    fi
    ulimit -Hs 32768
    ulimit -Ss 10240
}

## Affichage des messages de sortie de debug
function decho {
    if [ $DEBUG -eq 1 ] ; then
        echo $APP_CTX: $*
    fi
}

######## Préparation fichier d'historique des informations de contexte
FICH_INFOS=/tmp/.z_oracle
# Obsolescence parr défaut: 24h
FICH_OBS=24
## Gestion de l'obsolescence du fichier d'historique de configuration
# Si il n'existe pas, aucun problème. Sinon, il faut traiter
#ls -lrta $FICH_INFOS
#ls -lrts /tmp/.z_oracle
if [ -r $FICH_INFOS ] ; then
    # Si obsolete
    decho "Fichier $FICH_INFOS trouvé"
    NB_SEC_DEPUIS_EPOCH=`PATH=\`getconf PATH\` awk 'BEGIN{srand();print srand()}'`
    NB_SEC_DEPUIS_EPOCH_FICHIER=`stat -c %Y $FICH_INFOS`
    NB_SEC_ECOULEES_MOD=`expr $NB_SEC_DEPUIS_EPOCH - $NB_SEC_DEPUIS_EPOCH_FICHIER`
    HEURES_MOD=`expr $NB_SEC_ECOULEES_MOD / 3600`
    if [ $HEURES_MOD -ge $FICH_OBS ] ; then
        decho "Suppression $FICH_INFOS : obsolète (+${FICH_OBS}h)"
        rm -f $FICH_INFOS 1>/dev/null 2>&1
        touch $FICH_INFOS
        chmod 666 $FICH_INFOS
    fi
else
    decho "fichier $FICH_INFOS non trouvé"
    touch $FICH_INFOS
    chmod 666 $FICH_INFOS
fi

# Fonction qui charge une information, soit depuis le contexte, soit depuis le fichier d'infos
function charge {
    # Premier paramètre: le nom de l'élément recherché, identique au nom de la variable d'env du script
    if [ $# -ne 1 ] ; then
        decho charge: manque de paramétrage
        exit 0
    fi
    # Afin d'éviter la globalisation des variables de recherche et ne pas alourdir "l'unset" final, utilisation de variables locales pour la recherche
    local __varRecherche=$1
    # Déjà connu via le fichier d'infos pour chargement rapide et pas reclacul
    if [ `egrep "^${1}=" $FICH_INFOS | wc -l` -eq 1 ] ; then
        # OUI
        local lRep=`egrep "^$1" $FICH_INFOS | cut -d= -f2` 
        eval $__varRecherche="'$lRep'"
    else
        # NON : on calcule et on pérénise
        case $1 in
            NODE_INFO)
                lNODE_INFO=`$ORA_CRS_HOME/bin/olsnodes -l -n -a`
                if [ $? -ne 0 ] ; then
                    # En cluster 11, on n'a pas de -a (mode cluster flex/normal)
                    lNODE_INFO=`$ORA_CRS_HOME/bin/olsnodes -l -n`
                fi
                echo "NODE_INFO=$lNODE_INFO" >> $FICH_INFOS
                eval $__varRecherche="'$lNODE_INFO'"
            ;;
            ORA_CRS_CLUSTER_NAME)
                local lORA_CRS_CLUSTER_NAME=`$ORA_CRS_HOME/bin/olsnodes -c`
                echo "ORA_CRS_CLUSTER_NAME=$lORA_CRS_CLUSTER_NAME" >> $FICH_INFOS
                eval $__varRecherche="'$lORA_CRS_CLUSTER_NAME'"
            ;;
            ORA_CRS_ACTIVEVERSION)
                local lORA_CRS_ACTIVEVERSION=`$ORA_CRS_HOME/bin/crsctl query crs activeversion | cut -d[ -f2 | cut -d. -f1`
                echo "ORA_CRS_ACTIVEVERSION=$lORA_CRS_ACTIVEVERSION" >> $FICH_INFOS
                eval $__varRecherche="'$lORA_CRS_ACTIVEVERSION'"
            ;;
            ORA_CRS_CLUSTERMODE)
                local lORA_CRS_CLUSTERMODE=`$ORA_CRS_HOME/bin/crsctl get cluster mode config |cut -d\" -f2`
                echo "ORA_CRS_CLUSTERMODE=$lORA_CRS_CLUSTERMODE" >> $FICH_INFOS
                eval $__varRecherche="'$lORA_CRS_CLUSTERMODE'"
            ;;
        esac
    fi
}
########

decho "Terminal en mode interactif: $INTERACTIF"

## On entre seulement pour certains utilisateurs.
## root een  fait partie pour la composante cluster, crsctl, ...
if [ $USER = "SED_ORACLE_TARGET__" ] || [ $USER = "SED_GRID_TARGET__" ] || [ $USER = "root" ] ; then
    
     decho $USER login profile

     # Certaines operations ne sont pas a realiser pour root
     # les limites sont laissees par defaut
     # ainsi que le masque de creation de fichier ou le stty break.
    if [ $USER != "root" ] ; then
        ajustement_limites

        decho umask et stty break
        # Masque de création des fichiers    
        umask 022

        # Pour prévention SSH
        if [ -t 0 ]; then
            stty intr ^C
        fi
    fi

    # préparation pour l'inventaire
    # Si l'installation a ete realisee, on a un inventaire accessible que l'on peut traiter
    OLR_LOC=/etc/oracle/olr.loc
    ORA_INVENTORY_CFFILE=/etc/oraInst.loc
    decho OLR: $OLR_LOC
    decho Inventaire: $ORA_INVENTORY_CFFILE

    # Si l'installation n'est pas faite... on ignore cette partie
    if [ -f $ORA_INVENTORY_CFFILE ] ; then
        decho Installation trouvee
        # On recupere les informations de l'inventaire, pour traitement eventuel
        ORA_INVENTORY=`grep inventory_loc $ORA_INVENTORY_CFFILE | cut -d= -f2`
        ORA_INVENTORY_XMLFILE=$ORA_INVENTORY/ContentsXML/inventory.xml

        # Recuperation de l'emplacement du répertoire prive de l'utilisateur premier oracle
        ORA_EXPL_DIR=SED_EXPL_REP__
        ORA_EXPL_BIN=$ORA_EXPL_DIR/bin
        ORA_EXPL_SQL=$ORA_EXPL_DIR/sql
        ORA_EXPL_TMP=$ORA_EXPL_DIR/tmp
        ORA_EXPL_RLWVOC=$ORA_EXPL_DIR/rlwrap_vocabulaire
        # Préparation des informations de complément pour RLWrap par rapport aux fichiers de vocabulaire, si présents
        if [ -r "$ORA_EXPL_RLWVOC/adrci" ] ; then
            RLW_COMP_ADRCI=" -i -f $ORA_EXPL_RLWVOC/adrci "
        fi
        if [ -r "$ORA_EXPL_RLWVOC/asmcmd" ] ; then
            RLW_COMP_ASMCMD=" -i -f $ORA_EXPL_RLWVOC/asmcmd "
        fi
        if [ -r "$ORA_EXPL_RLWVOC/dgmgrl" ] ; then
            RLW_COMP_DGMGRL=" -i -f $ORA_EXPL_RLWVOC/dgmgrl "
        fi
        if [ -r "$ORA_EXPL_RLWVOC/rman" ] ; then
            RLW_COMP_RMAN=" -i -f $ORA_EXPL_RLWVOC/rman "
        fi
        if [ -r "$ORA_EXPL_RLWVOC/sqlplus" -a -d "$ORA_EXPL_RLWVOC/sqlplus" ] ; then
            LISTE_COMPLEMENTS=`ls $ORA_EXPL_RLWVOC/sqlplus | sed -e "s|^| -f $ORA_EXPL_RLWVOC/sqlplus/|g" | tr '\n' ' '`
            RLW_COMP_SQLPLUS=" -i $LISTE_COMPLEMENTS "
            unset LISTE_COMPLEMENTS
        fi

        # Test pour savoir si GI installée
        if [ -f $OLR_LOC ] ; then
            decho GI installee
            # Mise en place du pointeur de racine CRS
            export ORA_CRS_HOME=`grep crs_home /etc/oracle/olr.loc|cut -d= -f2`
            decho ORA_CRS_HOME = $ORA_CRS_HOME

            # On utilise olsnodes qui "sors" rapidement pour aussi valider que la couche est UP
            # sinon on perds un temps phénoménal pour rien avec les timeout crsctl
            # La remarque n'est plus valable avec la 12C. Donc, ajout d'un test via la ressource ora.crsd
            $ORA_CRS_HOME/bin/crsctl stat res ora.crsd -init  | grep STATE | grep ONLINE 1>/dev/null 2>&1
            if [ $? -eq 0 ] ; then
              # C'est démarré, on peut traiter.  
                charge NODE_INFO
                export ORA_CRS_NODE_NUM=`echo $NODE_INFO | awk '{print $2}'`
                export ORA_CRS_NODE_TYPE=`echo $NODE_INFO | awk '{print $3}'`
                decho ORA_CRS_NODE_NUM = $ORA_CRS_NODE_NUM
                decho ORA_CRS_NODE_TYPE = $ORA_CRS_NODE_TYPE

                charge ORA_CRS_CLUSTER_NAME
                decho ORA_CRS_CLUSTER_NAME=$ORA_CRS_CLUSTER_NAME

                # Si le cluster n'a pas de nom, c'est que nous sommes en Oracle Restart. Donc pas de query activeversion!
                if [ "$ORA_CRS_CLUSTER_NAME" != "" ] ; then
                    # Alias qui permet à partir du nom de la base de fixer dynamiquement le SID (depuis ORACLE_SID via oraenv)
                    if [ "$USER" != "root" ] ; then
                        # Ajout d'un alias pour adapter le nom de base vers le sid
                        # le nom de la base est localisé dans le fichier oratab et le nom de l'instance dépend de la configuration
                        alias sid='egrep "^$ORACLE_SID:" /etc/oratab 1>/dev/null 2>&1 && export ORACLE_SID=`LANG=C srvctl status instance -d $ORACLE_SID -n \`hostname -s\`| cut -d" " -f2`'
                    fi
                    charge ORA_CRS_ACTIVEVERSION
                    if [ "$ORA_CRS_ACTIVEVERSION" -eq "12" ] ; then
                        # On peut attendre un cluster flex ou non
                        charge ORA_CRS_CLUSTERMODE
                        # On raccourcis "standard" en "std" si besoin
                        if  [ "$ORA_CRS_CLUSTERMODE" = "standard" ] ; then
                            export ORA_CRS_CLUSTERMODE=std
                        fi
                    else
                        export ORA_CRS_CLUSTERMODE=std
                    fi
                else
                    ORA_CRS_CLUSTERMODE=rst
                fi    
                decho Mode: $ORA_CRS_CLUSTERMODE


            else
                decho Clusterware OFFLINE.
                # Est-on en RESTART ???!!!
                if [ `cat /etc/oracle/ocr.loc | grep "local_only=TRUE" |wc -l` -eq 1 ] ; then
                    decho certainement GI standalone pour RESTART
                    ORA_CRS_CLUSTERMODE=rst
                fi
            fi

            # Alias manipulation
            if [ $USER = "SED_ORACLE_TARGET__" ] ; then
                # pointeur facile pour crsctl...
                decho Alias crsctl cree
                alias crsctl='$ORA_CRS_HOME/bin/crsctl'
            elif [ $USER = "root" ] ; then
                    decho Ajustement path user root
                    # On ajoute le chemin du cluster dans le PATH 
                    export PATH=$ORA_CRS_HOME/bin:$ORA_EXPL_BIN:$PATH
            elif [ $USER = "SED_GRID_TARGET__" ] ; then
                decho environnement GI
                export ORACLE_HOME=$ORA_CRS_HOME
                export ORACLE_BASE=`$ORACLE_HOME/bin/orabase`
                export SQLPATH=$ORA_EXPL_SQL
                export PATH=$ORA_CRS_HOME/bin:$ORA_CRS_HOME/OPatch:$ORA_EXPL_BIN:$PATH
                if [ `ps -ef | grep -E 'pmon.*\+A' | grep -v grep | cut -d_ -f3- | wc -l` -gt 0 ] ; then
                    export ORACLE_SID=`ps -ef | grep -E 'pmon.*\+A' | grep -v grep | cut -d_ -f3- | sort | tail -1`
                fi
            fi
            ## Accès direct aux logs
            if [ "$INTERACTIF" = "OUI" ] ; then
                DRT_LI=`tput lines`
            else
                DRT_LI=100
            fi
            ## On teste la présence de fichiers "11" hors ADR.
            if [ -r $ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/ohasd/ohasd.log ] ; then
                ## Configuration ancienne
                OHASD_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/ohasd/ohasd.log
                CSSD_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/cssd/ocssd.log
                CRSD_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/crsd/crsd.log
                ALERT_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/alert$HOSTNAME_SIMPLE.log
            else
                ## Configuration nouvelle ADR pour les journaux cluster
                OB=`ORACLE_HOME=$ORA_CRS_HOME ${ORA_CRS_HOME}/bin/orabase`
                OHASD_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/ohasd.trc
                CSSD_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/ocssd.trc
                CRSD_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/crsd.trc
                ALERT_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/alert.log
            fi
            ## Cluster Alert log
            alias alertgen="tail -${DRT_LI}f $ALERT_LOG"
            ## LOG - OHASD
            alias ohasd="tail -${DRT_LI}f $OHASD_LOG"
            ## LOG - CSSD
            alias cssd="tail -${DRT_LI}f $CSSD_LOG"
            ## LOG - CRSD
            alias crsd="tail -${DRT_LI}f $CRSD_LOG"
            ## Alert global watch
            
            ## Aucun intérêt dans un terminal non interactif
            if [ "$INTERACTIF" = "OUI" ] ; then
                DRT_LI=`expr $DRT_LI / 10 - 1`
                DRT_LI2=`expr $DRT_LI \* 3`
                DRT_LI6=`expr $DRT_LI \* 6`
                NORMAL=$(tput sgr0)
                ROUGE=$(tput setaf 1)
                alias alert="while :; do   clear ;  R=\`tput cols\` ; echo -e \"${ROUGE}ALERT********${NORMAL}\" ;   tail -$DRT_LI $ALERT_LOG | cut -c -\$R ;   echo -e \"${ROUGE}CRSD*********${NORMAL}\" ;   tail -$DRT_LI2 $CRSD_LOG | cut -c -\$R ;   echo -e \"${ROUGE}OCSSD********${NORMAL}\" ;   tail -$DRT_LI6 $CSSD_LOG | cut -c -\$R ;   echo -e \"${ROUGE}OHASD********${NORMAL}\" ;   tail -$DRT_LI $OHASD_LOG | cut -c -\$R ;   sleep 1; done"
            fi
        else
            decho GI non installee
            ORA_CRS_CLUSTERMODE=sa
        fi

        # Alias CDT valable pour tous environnements
        # Attention, cluster ou non.
        if [ "$ORA_CRS_CLUSTERMODE" = "rst" -o "$ORA_CRS_CLUSTERMODE" = "sa" ] ; then
            # Sans GI ou en Restart
            if [ $USER = "SED_ORACLE_TARGET__" ] ; then
                alias cdt='cd $ORACLE_BASE/diag/rdbms/`echo $ORACLE_SID | tr [:upper:] [:lower:]`/$ORACLE_SID/trace'
            elif [ $USER = "SED_GRID_TARGET__" ] ; then
                alias cdt='cd $ORACLE_BASE/diag/asm/`echo $ORACLE_SID | tr [:upper:] [:lower:]`/$ORACLE_SID/trace'
            fi
        elif [ ! -z "$ORA_CRS_CLUSTERMODE" ] ; then
            # En cluster, donc
            if [ $USER = "SED_ORACLE_TARGET__" ] ; then
                alias cdt='cd $ORACLE_BASE/diag/rdbms/`echo ${ORACLE_SID%?} | tr [:upper:] [:lower:]`/$ORACLE_SID/trace'
            elif [ $USER = "SED_GRID_TARGET__" ] ; then
                alias cdt='cd $ORACLE_BASE/diag/asm/`echo ${ORACLE_SID%?} | tr [:upper:] [:lower:]`/$ORACLE_SID/trace'
            fi
        else
            decho "Type cluster non calculé"
        fi

        # Env oracle avec ou hors GI
        if [ $USER = "SED_ORACLE_TARGET__" ] ; then
          export SQLPATH=$ORA_EXPL_SQL
          # Si 1 seul OH dans l'inventaire, on set. Non déterminable si GI non cluster (manque le CRS=true pour identifier)
            if [ `grep '<HOME NAME' $ORA_INVENTORY_XMLFILE | grep -v 'CRS' | grep -v "${ORA_CRS_HOME:-xxxxxxxxxx}" | wc -l` -eq 1 ] ; then
                export ORACLE_HOME=`grep '<HOME NAME' $ORA_INVENTORY_XMLFILE | grep -v 'CRS' | grep -v "${ORA_CRS_HOME:-xxxxxxxxxx}" | sed -e 's/.*LOC=//g' | cut -d'"' -f2`
                export ORACLE_BASE=`$ORACLE_HOME/bin/orabase`
                if [ "$ORACLE_HOME" = "$ORA_CRS_HOME" ] ; then
                    # Installation en suspens
                    unset ORACLE_HOME ORACLE_BASE
                else
                    export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$ORA_EXPL_BIN:$PATH
                    decho ORACLE_HOME=$ORACLE_HOME
                    # On va essayer de se positionner dans l'environnement de la première base dispo.
                    DB_TARGET=`cat /etc/oratab | grep -Ev '^$|^#' | grep $ORACLE_HOME | cut -d: -f1 | head -1`
                    decho DB_TARGET=$DB_TARGET
                    if [ ! -z $DB_TARGET ] ; then
                        # DB trouvée, on cherche l'instance
                        if [ "$ORA_CRS_CLUSTERMODE" = "sa" ] ; then
                            # Si c'est une install SA, on teste sans ID d'instance
                            decho SA
                            DEC_INST=`ps -ef | grep -E "pmon_${DB_TARGET}$" | grep -v grep | cut -d_ -f3-`
                        else
                            # Sinon, sans complément, on vois
                            decho CL
                            DEC_INST=`ps -ef | grep -E "pmon_${DB_TARGET}(\_*[0-9]|[0-9]|$)" | grep -v grep | cut -d_ -f3-`
                        fi
                        decho $DEC_INST
                        if [ ! -z $DEC_INST ] ; then
                            export ORACLE_SID=$DEC_INST
                        fi
                    fi
                fi
            fi
        fi

        # Alias RL Wrap si disponible
        if [ `/bin/rpm -qa |grep -i rlwrap | wc -l` -eq 1 ] ; then
            alias sqlplus="rlwrap $RLW_COMP_SQLPLUS sqlplus"
            alias rman="rlwrap $RLW_COMP_RMAN rman"
            alias asmcmd="rlwrap $RLW_COMP_ASMCMD asmcmd"
            alias adrci="rlwrap $RLW_COMP_ADRCI adrci"      
            alias dgmgrl="rlwrap $RLW_COMP_DGMGRL dgmgrl"
        fi

        # Ajout d'un alias pour aller dans l'OH
        alias oh='cd $ORACLE_HOME'
    else
        decho NON INSTALLE
    fi
    # Mise en place d'un prompt sympa
    # Aucun intérêt hors d'un terminal interactif
    if [ "$INTERACTIF" = "OUI" ] ; then
        vert=$(tput setaf 2)
        bleu=$(tput setaf 4)
        gras=$(tput bold)
        rouge=$(tput setaf 1)
        reset=$(tput sgr0)
    fi

    decho prompt set
    ## Ici, on sait être oracle, grid ou root. On filtre donc selon le cas. Avec plusieurs utilisateurs oracle
    ## Le filtrage a du être vu comme ça
    ## Si on est grid et couleur => on change
    ## Sinon si on est root et couleur ==> on change
    ## Sinon on est alors forcément oracle. si couleur ==> on change
    if [ $USER = "SED_GRID_TARGET__" -a $GRID_INV_C -eq 1 ] || [ $USER = "root" -a $ROOT_INV_C -eq 1 ] || [ $ORAC_INV_C -eq 1 -a $USER != "SED_GRID_TARGET__" -a $USER != "root" ] ; then
        decho Invite en couleur
        if [ "$ORA_CRS_CLUSTERMODE" = "flex" ] ; then
            export PS1='[\[$bleu\]\u\[$reset\]@\[$vert\]\h\[$reset\] ($ORA_CRS_CLUSTERMODE $ORA_CRS_CLUSTER_NAME $ORA_CRS_NODE_TYPE:$ORA_CRS_NODE_NUM) \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
        elif [ "$ORA_CRS_CLUSTERMODE" = "std" ] ; then
            export PS1='[\[$bleu\]\u\[$reset\]@\[$vert\]\h\[$reset\] ($ORA_CRS_CLUSTERMODE $ORA_CRS_CLUSTER_NAME:$ORA_CRS_NODE_NUM) \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
        elif [ "$ORA_CRS_CLUSTERMODE" = "sa" -o "$ORA_CRS_CLUSTERMODE" = "rst" ] ; then
            export PS1='[\[$bleu\]\u\[$reset\]@\[$vert\]\h\[$reset\] ($ORA_CRS_CLUSTERMODE) \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
        else
            export PS1='[\[$bleu\]\u\[$reset\]@\[$vert\]\h\[$reset\] \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
        fi
    fi

    # Mode eMacs d'édition de ligne par défaut. Possible de passer en mode vi si nécessaire.
    set -o emacs

fi

unset charge ajustement_limites decho APP_CTX HOSTNAME_SIMPLE DEBUG OLR_LOC ORA_INVENTORY ORA_INVENTORY_XMLFILE ORA_INVENTORY_CFFILE ORA_USER_HOME ORA_EXPL_DIR ORA_EXPL_BIN ORA_EXPL_SQL ORA_EXPL_TMP DRT_LI DRT_LI2 DRT_LI6 NODE_INFO DB_TARGET DEC_INST ORA_CRS_HOME INTERACTIF
