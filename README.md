# gbavatar

GitBucket Mass Avatar Updater

This quick-n-dirty script assumes you have a website where you host the users' pictures with the same names as in your GitBucket instance. I.e. if your user's GitBucket username is `john.smith`, you host the picture as `https://portal.foobar.com/images/members/john.smith.jpg` or similar. It also assumes you host your GitBucket instance in Tomcat, and that your users use LDAP authentication, but you can modify the script to your needs accordingly.
