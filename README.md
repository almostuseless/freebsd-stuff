freebsd-stuff
=============

a collection of functional but inelegent scripts for freebsd stuff


apachies.sh
-----------
<pre># ./apachies.sh 


      +--- required flags ---------+
      | -n  new username           |
      | -d  domain name for vhosts |
      +----------------------------+

      +--- functionality ----|---- creates/destroys------------+
      | -v  create new vhost |  www01:  user, home dir, vhost  |
      | -b  create new blog  |  www01:  git, ssh keys          |
      |                      |  repo01: user, ro-user, home    |
      +----------------------+---------------------------------+
      | -d  delete [-b|-v]   |  users, user-ro, homes, vhost   |
      +----------------------+---------------------------------+


# ./apachies.sh -n example -d por-ejemplo.com -b 

[+]  www01              - jid: 16
[+]  repo01             - jid: 12
------------------ vhost ----------------------
[*]  www01              - creating user example
[*]  www01              - creating extra/vhosts/por-ejemplo.com-vhost.conf
--------------- repository --------------------
[*]  repo01             - creating user example
[*]  www01/repo01:      - generating ssh keys
[*]  repo01             - creating user example-ro
[*]  repo01             - creating new git repo at ~/por-ejemplo.com
------------- fetch credentials ---------------
[!]  http://por-ejemplo.com/id_rsa_por-ejemplo.com  - create ~/.ssh/id_rsa_por-ejemplo.com
[!]  http://por-ejemplo.com/config_por-ejemplo.com  - create/append ~/.ssh/config

[!]  Press enter once you have completed 0x06 on your local machine
[!]  (from http://almostuseless.info/2012/10/10/blogging-with-freebsd-and-jekyll)
[*]  www01              - checking out _site from repo01:/home/example/por-ejemplo.com
[+]  done</pre>
