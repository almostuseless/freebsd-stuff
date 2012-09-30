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
</pre>
