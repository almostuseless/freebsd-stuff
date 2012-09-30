freebsd-stuff
=============

a collection of functional but inelegent scripts for freebsd stuff


<<<<<<< HEAD
0x00 - apachies.sh
------------------
<pre># ./apachies.sh 
=======
apachies.sh
-----------
<pre>[root@demeter /usr/local/src/freebsd-stuff]# ./apachies.sh 
>>>>>>> d754db6381a8a1edc3286f1b16d94cfdc744afdc


      +--- required flags ---------+
      | -n  new username           |
      | -d  domain name for vhosts |
      +----------------------------+

<<<<<<< HEAD
      +--- functionality ----|---- creates/destroys------------+
      | -v  create new vhost |  www01:  user, home dir, vhost  |
      | -b  create new blog  |  www01:  git, ssh keys          |
      |                      |  repo01: user, ro-user, home    |
      +----------------------+---------------------------------+
      | -d  delete [-b|-v]   |  users, user-ro, homes, vhost   |
      +----------------------+---------------------------------+</pre>
=======
      +--- functionality ----|---- creates ----------------------------+
      | -v  create new vhost |   www01: user/directory/vhost           |
      +----------------------+-----------------------------------------+
      | -b  create new blog  |   www01: -user/directory/vhost/ssh keys |
      |                      |   repo01: user/ro-user/git/ssh keys     |
      +----------------------+-----------------------------------------+</pre>
>>>>>>> d754db6381a8a1edc3286f1b16d94cfdc744afdc
