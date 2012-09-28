<font face="monospace, courier">
freebsd-stuff
=============

a collection of functional but inelegent scripts for freebsd stuff


apachies.sh
-----------
<pre>[root@demeter /usr/local/src/freebsd-stuff]# ./apachies.sh 


      +--- required flags ---------+
      | -n  new username           |
      | -d  domain name for vhosts |
      +----------------------------+

      +--- functionality ----|---- creates ----------------------------+
      | -v  create new vhost |   www01: user/directory/vhost           |
      +----------------------+-----------------------------------------+
      | -b  create new blog  |   www01: -user/directory/vhost/ssh keys |
      |                      |   repo01: user/ro-user/git/ssh keys     |
      +----------------------+-----------------------------------------+</pre>
</font>
