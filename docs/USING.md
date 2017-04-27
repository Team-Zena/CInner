This repository can be cloned and placed on a server and served by a webserver such that github can index.php

Configuration variables for the script can be set in ```./config_vars.sh``` (a sample is provided as config_vars_sample.sh),
 similarly configuration variables for index.php can be set in ```./config.inc.php``` (a sample is provided as config.inc.sample.php).

The log folder can be password protected.
(For apache, http://httpd.apache.org/docs/current/howto/auth.html)

Hook for push can be added to github project webhook.

Permission for this folder and files (as well as for the folder and files that are used by git and the test framework) should be such that the user that executes the script can access it.

For setting up the git repo (for which testing is being done) a github OAuth Token can be used in the remote:
https://github.com/blog/1270-easier-builds-and-deployments-using-git-over-https-and-oauth
