#/usr/local/bin/bash

www_hostname="www01"
repo_hostname="repo01"

www_jid=`jls | grep ${www_hostname} | awk '{ print $1 }'`
repo_jid=`jls | grep ${repo_hostname} | awk '{ print $1 }'`


while getopts "bDvn:d:" optname; do
    case "$optname" in
        v ) vhost=1          ;;
        b ) blog=1 ; vhost=1 ;;
        D ) delete=1         ;;
        n ) nuser=$OPTARG    ;;
        d ) domain=$OPTARG   ;;
        ? ) echo "-- Unknown option $OPTARG --"
        ;;
    esac
done


shift $(( OPTIND - 1 ))

show_help() {
            echo; echo
            echo "      +--- required flags ---------+"
            echo "      | -n  new username           |"
            echo "      | -d  domain name for vhosts |" 
            echo "      +----------------------------+"
            echo
<<<<<<< HEAD
            echo "      +--- functionality ----|---- creates/destroys------------+"
            echo "      | -v  create new vhost |  www01:  user, home dir, vhost  |"
            echo "      | -b  create new blog  |  www01:  git, ssh keys          |"
            echo "      |                      |  repo01: user, ro-user, home    |"
            echo "      +----------------------+---------------------------------+" 
            echo "      | -d  delete [-b|-v]   |  users, user-ro, homes, vhost   |"
            echo "      +----------------------+---------------------------------+" 
=======
            echo "      +--- functionality ----|---- creates ----------------------------+"
            echo "      | -v  create new vhost |   www01: user/directory/vhost           |"
            echo "      +----------------------+-----------------------------------------+"
            echo "      | -b  create new blog  |   www01: -user/directory/vhost/ssh keys |"
            echo "      |                      |   repo01: user/ro-user/git/ssh keys     |"
            echo "      +----------------------+-----------------------------------------+" 
>>>>>>> d754db6381a8a1edc3286f1b16d94cfdc744afdc
            echo; echo
            exit
}

create_user() {

        ### usertype
          # 0 = "vhost"     - create user/dirs on www01 for the <Processor> directive
          # 1 = "blog"      - create user/user-ro/dirs/ssh-keys on repo01 for git,
          #                     - create ssh keys for www01 and repo01

        utype=$1


        if [ "${utype}" -eq "0" ]; then
            echo -e "[*]  ${www_hostname}\t\t- creating user ${nuser}"

            jexec ${www_jid} pw groupadd ${nuser}
            jexec ${www_jid} pw useradd -n ${nuser} -d /home/${nuser} -g ${nuser} -m -M 700 -s /sbin/nologin

        elif [ "${utype}" -eq "1" ]; then
            echo -e "[*]  ${repo_hostname}\t\t- creating user ${nuser}"

            jexec ${repo_jid} pw groupadd ${nuser}
            jexec ${repo_jid} pw useradd -n ${nuser} -d /home/${nuser} -g ${nuser} -m -M 770 -s /usr/local/bin/git-shell

            echo -e "[*]  ${www_hostname}/${repo_hostname}:\t- generating ssh keys"

            for i in ${www_jid} ${repo_jid}; do
                jexec $i mkdir /home/${nuser}/.ssh
#                jexec $i mkdir /home/${nuser}/${domain}/
                jexec $i ssh-keygen -t rsa -b 4096 -f /home/${nuser}/.ssh/id_rsa -N "" > /dev/null
                jexec $i chown -R ${nuser}:${nuser} /home/${nuser}/
            done;

            echo -e "[*]  ${repo_hostname}\t\t- creating user ${nuser}-ro"
            ### Create a read-only account on ${repo_hostname} for <user>@${www_hostname} to use for git-over-ssh.
            jexec ${repo_jid} pw useradd -n ${nuser}-ro -d /home/${nuser} -g ${nuser} -s /usr/local/bin/git-shell
                
            ### Create .ssh/config for www01
            echo Host ${repo_hostname} > /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/config
            echo "    Hostname 10.0.0.3" >> /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/config
            echo "    Port 22003" >> /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/config
            echo "    User ${nuser}-ro" >> /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/config
            echo "    IdentityFile /home/${nuser}/.ssh/id_rsa" >> /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/config
            echo "    StrictHostKeyChecking no" >> /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/config

           jexec ${www_jid} chown -R ${nuser}:${nuser} /home/${nuser}/.ssh
           jexec ${www_jid} chmod -R 600 /home/${nuser}/.ssh

            ### Copy public key for www01:<user>-ro to repo01
            cat /usr/jails/${www_hostname}/usr/home/${nuser}/.ssh/id_rsa.pub \
                > /usr/jails/${repo_hostname}/usr/home/${nuser}/.ssh/authorized_keys

            ### Add repo01 
            cat /usr/jails/${repo_hostname}/usr/home/${nuser}/.ssh/id_rsa.pub \
                >> /usr/jails/${repo_hostname}/usr/home/${nuser}/.ssh/authorized_keys


            ### Let read-only user read .ssh/authorized_keys
              # For some reason the files/dirs are unreadable at 640.. :-/
            jexec ${repo_jid} chmod 770 /home/${nuser}
            jexec ${repo_jid} chmod 770 /home/${nuser}/.ssh
            jexec ${repo_jid} chown ${nuser}:${nuser} /home/${nuser}/.ssh/authorized_keys
            jexec ${repo_jid} chmod 770 /home/${nuser}/.ssh/authorized_keys
            jexec ${www_jid} chmod -R 700 /home/${nuser}/.ssh

            jexec ${repo_jid} chmod 770 /home/${nuser}/.ssh
        fi


}
create_vhost() {

    if ! [ -d "/usr/jails/${www_hostname}/usr/local/etc/apache22/extra/vhosts" ]; then
        install_configs
    fi

    echo -e "[*]  ${www_hostname}\t\t- creating extra/vhosts/${domain}-vhost.conf"

    jexec ${www_jid} mkdir /home/${nuser}/public_html
    echo "-- ${domain} --" > /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/index.html
    jexec ${www_jid} chmod -R 755 /home/${nuser}/public_html

    cp /usr/jails/${www_hostname}/usr/local/etc/apache22/extra/vhosts/blank.vhost \
        /usr/jails/${www_hostname}/usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf

    jexec ${www_jid} sed -i "" "s/__USER__/${nuser}/g" \
         /usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf

    jexec ${www_jid} sed -i "" "s/__URL__/${domain}/g" \
         /usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf 

    jexec ${www_jid} /usr/local/etc/rc.d/apache22 reload > /dev/null 2>&1
}

install_configs() {

    echo -e "[*]  ${www_hostname}\t\t- fetching new apache configs"

    jexec ${www_jid} fetch -o /tmp/apache-configs.tar.gz http://10.0.0.2/files/apache-configs.tar.gz 
    jexec ${www_jid} tar xvzf /tmp/apache-configs.tar.gz -C /usr/local/etc/apache22
    
    jexec ${www_jid} sed -i "" "s/__USER__/${nuser}/g" \
         /usr/local/etc/apache22/httpd.conf

    jexec ${www_jid} sed -i "" "s/__URL__/${domain}/g" \
         /usr/local/etc/apache22/httpd.conf
    
    echo -e "[*]  ${repo_hostname}\t\t- \"StrictModes yes\" >> /etc/ssh/sshd_config"

    echo "sshd_enable=\"YES\"" >  /usr/jails/${repo_hostname}/etc/rc.conf
    echo "apache22_enable=\"YES\"" >  /usr/jails/${www_hostname}/etc/rc.conf

    ### Just adding 'StrictModes no' so that the read-only users have read permissions
      # to real users .ssh/authorized_keys files
    if grep --quiet "#StrictModes yes" /usr/jails/${repo_hostname}/etc/ssh/sshd_config; then
        sed -i "" 's/^#StrictModes yes/StrictModes no/' /usr/jails/${repo_hostname}/etc/ssh/sshd_config
        jexec ${repo_jid} /etc/rc.d/sshd restart > /dev/null
    fi


    if ! grep --quiet ${repo_hostname} /usr/jails/${www_hostname}/etc/hosts; then
        echo "10.0.0.3          ${repo_hostname}" > /usr/jails/${www_hostname}/etc/hosts
    fi
}

create_blog() {

    echo -e "[*]  ${repo_hostname}\t\t- creating new git repo at /home/${nuser}/${domain}.git"

    jexec ${www_jid} rm -rf /home/${nuser}/public_html

    jexec ${repo_jid} git init --shared=0740 --bare /home/${nuser}/${domain} > /dev/null
    jexec ${repo_jid} chown -R ${nuser}:${nuser} /home/${nuser}/${domain}

    echo -e "[*]  ${www_hostname}\t\t- cloning into ${repo_hostname}:/home/${nuser}/${domain}.git"
    jexec ${www_jid} pw usermod ${nuser} -s /bin/sh
    jexec ${www_jid} su ${nuser} -c "cd && git clone ${repo_hostname}:/home/${nuser}/${domain} public_html > /dev/null 2>&1"
    jexec ${www_jid} pw usermod ${nuser} -s /sbin/nologin

    echo "-- ${domain} --" > /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/index.html

    ### Script will be run from a cronjob, probably will add more stuffs later.
    ### Its in its own shell script because im too dumb to make cron work the right way
    ### "* * * * * su -s /bin/sh ${nuser} -c 'cd /path/git/ && git pull'
    ### ^^^^^ wouldnt work, didnt care to research why
     
    echo "#!/bin/sh" > /usr/jails/${www_hostname}/home/${nuser}/update.sh
    echo "cd /home/${nuser}/${domain}" >> /usr/jails/${www_hostname}/home/${nuser}/update.sh
    echo "git pull" >> /usr/jails/${www_hostname}/home/${nuser}/update.sh

#    echo "* * * * * ${nuser} sh /home/${nuser}/update.sh > /dev/null 2>&1" \
#        >> /usr/jails/${www_hostname}/etc/crontab

    ### Copy public key for repo01:<user> to docroot
    cat /usr/jails/${repo_hostname}/usr/home/${nuser}/.ssh/id_rsa \
         >> /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/id_rsa_${domain}

    echo "Host ${domain}" > /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/ssh-config
    echo -e "\tUser ${nuser}" >> /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/ssh-config
    echo -e "\tPort 22003" >> /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/ssh-config
    echo -e "\tIdentityFile ~/.ssh/id_rsa_${domain}" >> /usr/jails/${www_hostname}/usr/home/${nuser}/public_html/ssh-config

    jexec ${www_jid} chown -R ${nuser}:${nuser} /home/${nuser}/public_html
    jexec ${www_jid} chmod -R 755 /home/${nuser}/public_html

    echo "[+]  -- done --"
    echo "[!]  fetch ~/.ssh/id_rsa - http://${domain}/id_rsa_${domain}"
    echo "[!]  fetch ~/.ssh/config - http://${domain}/ssh-config"

    echo; echo;

}

### probably the most retarded way i could possibly validate arguments

if ! [ "${nuser}" ] || ! [ "${domain}" ]; then
    show_help
fi

if ! [ "${blog}" ] && ! [ "${vhost}" ]; then
    show_help
fi


echo; echo;
echo -e "[+]  ${www_hostname}\t\t- jid: ${www_jid}"
echo -e "[+]  ${repo_hostname}\t\t- jid: ${repo_jid}"
echo "------------------ vhost ----------------------"

echo "DELETE: ${delete}"

### continued
if [ "${vhost}" ] ; then

    # if -d, rm shit and bail
    if [ "${delete}" ]; then
        echo -e "[!]  ${www_hostname}\t\t- cleaning up"
        jexec ${www_jid} pw userdel ${nuser}
        jexec ${www_jid} rm -rf /home/${nuser}
        jexec ${www_jid} rm /usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf
        jexec ${www_jid} /usr/local/etc/rc.d/apache22 reload > /dev/null 2>&1
        echo -e "[!]  ${www_hostname}\t\t- deleted ( user: ${nuser} - vhost: ${domain} )"
    else
        if ! grep --quiet c${nuser} /usr/jails/${www_hostname}/etc/passwd; then
            create_user 0
        else
            echo -e "[!] ${www_hostname}\t\t- user ${nuser} exists... skipping"
        fi
        if ! [ -e /usr/jails/${www_hostname}/usr/local/etc/apache22/extra/vhosts/${domain}-vhost.conf ]; then
            create_vhost
        else
            echo -e "[-] ${www_hostname}\t\t- vhost ${domain} exists... skipping"; 
        fi
    fi
fi

if [ "${blog}" ]; then

    echo "--------------- repository --------------------"

    # if -d, rm shit and bail
    if [ "${delete}" ]; then
        echo -e "[!]  ${repo_hostname}\t\t- cleaning up"
        jexec ${repo_jid} pw userdel ${nuser}
        jexec ${repo_jid} pw userdel ${nuser}-ro
        jexec ${repo_jid} pw groupdel ${nuser}
        jexec ${repo_jid} rm -rf /home/${nuser}

        echo -e "[!]  ${repo_hostname}\t\t- deleted ( user: ${nuser} - repository: ${domain} )"
        echo; echo; 
        exit
    fi

    if ! [ -e /usr/jails/${repo_jid}/home/${nuser} ]; then
        create_user 1
    else
        echo "[-] ${repo_hostname}\t\t- user ${nuser} exists"; echo; echo;
        exit
    fi

    create_blog
fi


