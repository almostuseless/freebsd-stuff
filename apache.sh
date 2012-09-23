 #/usr/local/bin/bash

www=`jls | grep www01 | awk '{ print $1 }'`
repo=`jls | grep repo01 | awk '{ print $1 }'`


while getopts "ahsn:d:" optname; do
    case "$optname" in
        a ) apache=1 ;;
        s ) site=1 ;;
        n ) nuser=$OPTARG ;;
        d ) domain=$OPTARG ;;
        ? ) echo "-- Unknown option $OPTARG --" ;;
        h )
        ;;
    esac
done


shift $(( OPTIND - 1 ))


show_help() {
            echo; echo
            echo "      -h  help"
            echo "      -n  REQUIRED: new username"
            echo "      -d  REQUIRED: domain for the new site (example.com)" 
            echo "      -a  OVERWRITE apache configs, create new user and site"  
            echo "      -s  create new site (must specify -n and -u)"
            echo; echo
}

create_site() {

    echo "###    Creating user ${nuser}:${nuser} and ssh keys    ###"
    echo "##########################################################"
    echo; echo

    ### Create users for each jail
    for i in ${www} ${repo}; do
        jexec $i pw groupadd ${nuser}
        jexec $i pw useradd -n ${nuser} -d /home/${nuser} -g ${nuser} -m -M 700 -s /sbin/nologin

        jexec $i mkdir /home/${nuser}/.ssh
        jexec $i mkdir /home/${nuser}/${domain}/
        jexec $i ssh-keygen -t rsa -b 4096 -f /home/${nuser}/.ssh/id_rsa -N "" > /dev/null
        jexec $i chown -R ${nuser}:${nuser} /home/${nuser}/
        jexec $i chmod -R 700 /home/${nuser}/.ssh

    done

    ### Create a read-only account on repo01 for <user>@www01 to use for git-over-ssh.
    jexec ${repo} pw useradd -n ${nuser}-ro -d /home/${nuser} -g ${nuser} -s /usr/local/bin/git-shell


    ### Create .ssh/config for www01
    echo Host repo01 > /usr/jails/www01/usr/home/${nuser}/.ssh/config
    echo "    Hostname 10.0.0.3" >> /usr/jails/www01/usr/home/${nuser}/.ssh/config
    echo "    Port 22003" >> /usr/jails/www01/usr/home/${nuser}/.ssh/config
    echo "    User ${nuser}-ro" >> /usr/jails/www01/usr/home/${nuser}/.ssh/config
    echo "    IdentityFile /home/${nuser}/.ssh/id_rsa" >> /usr/jails/www01/usr/home/${nuser}/.ssh/config
    echo "    StrictHostKeyChecking no" >> /usr/jails/www01/usr/home/${nuser}/.ssh/config

    jexec ${www} chown ${nuser}:${nuser} /home/${nuser}/.ssh/config
    jexec ${www} chmod 600 /home/${nuser}/.ssh/config

    ### Copy public key for <user>-ro to repo01
    cat /usr/jails/www01/usr/home/${nuser}/.ssh/id_rsa.pub \
        >> /usr/jails/repo01/usr/home/${nuser}/.ssh/authorized_keys

    ### Let read-only user read .ssh/authorized_keys
    jexec ${repo} chmod 770 /home/${nuser}
    jexec ${repo} chmod 770 /home/${nuser}/.ssh
    jexec ${repo} chown ${nuser}:${nuser} /home/${nuser}/.ssh/authorized_keys
    jexec ${repo} chmod 770 /home/${nuser}/.ssh/authorized_keys

    ### Set appropriate shells
    jexec ${repo} pw usermod ${nuser} -s /usr/local/bin/git-shell
    jexec ${repo} pw usermod ${nuser}-ro -s /usr/local/bin/git-shell



    cp /usr/jails/www01/usr/local/etc/apache22/extra/vhosts/blank.vhost \
        /usr/jails/www01/usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf

    jexec ${www} sed -i "" "s/__USER__/${nuser}/g" \
         /usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf

    jexec ${www} sed -i "" "s/__URL__/${domain}/g" \
         /usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf 

}

install_configs() {

    echo "###    Fetching/installing apache configs for www01    ###"
    echo "##########################################################"
    echo; echo

    jexec ${www} fetch -o /tmp/apache-configs.tar.gz http://10.0.0.2/files/apache-configs.tar.gz 
    jexec ${www} tar xvzf /tmp/apache-configs.tar.gz -C /usr/local/etc/apache22
    
    jexec ${www} sed -i "" "s/__USER__/${nuser}/g" \
         /usr/local/etc/apache22/httpd.conf

    jexec ${www} sed -i "" "s/__URL__/${domain}/g" \
         /usr/local/etc/apache22/httpd.conf

    
    echo "###    Modifying sshd_config on repo01    ###"
    echo "#############################################"
    echo; echo

    ### Just adding 'StrictModes no' so that the read-only users have read permissions
      # to real users .ssh/authorized_keys files
}

initialize_git() {

    echo; echo
    echo "###    Initializing git repository    ###"
    echo "#########################################"
    echo; echo

#    echo "10.0.0.3          repo01" >> /usr/jails/www01/etc/hosts

    jexec ${repo} git init --shared=0640 /home/${nuser}/${domain} 
    jexec ${repo} chown -R ${nuser}:${nuser} /home/${nuser}/${domain}

    jexec ${www} pw usermod ${nuser} -s /bin/sh
    jexec ${www} su ${nuser} -c "cd && git clone repo01:/home/${nuser}/${domain}"

    ### Script will be run from a cronjob, probably will add more stuffs later.
    ### Its in its own shell script because im too dumb to make cron work the right way
    ### "* * * * * su -s /bin/sh ${nuser} -c 'cd /path/git/ && git pull'
    ### ^^^^^ wouldnt work, didnt care to research why
     
    echo "#!/bin/sh" > /usr/jails/www01/home/${nuser}/update.sh
    echo "cd /home/${nuser}/${domain}" >> /usr/jails/www01/home/${nuser}/update.sh
    echo "git pull" >> /usr/jails/www01/home/${nuser}/update.sh

#    echo "* * * * * ${nuser} sh /home/${nuser}/update.sh > /dev/null 2>&1" \
#        >> /usr/jails/www01/etc/crontab

}

if ! [ "${nuser}" ] || ! [ "${domain}" ]; then
    show_help
fi

if [ "${apache}" ] ; then
    install_configs
    create_site
    initialize_git
    jexec ${www} service apache22 reload
fi


#
#
