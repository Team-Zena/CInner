# CInner

CInner (pronounced as **Sinner**) is a small CI system built on PHP and Bash scripts.

This repository can be cloned and placed on a server and served by a webserver such that github can call the index.php file.

Configuration variables for the script can be set in `./config_vars.sh` (a sample is provided as `config_vars_sample.sh`), similarly configuration variables for `index.php` can be set in `./config.inc.php` (a sample is provided as `config.inc.sample.php`).

The log folder can be password protected. (For apache, http://httpd.apache.org/docs/current/howto/auth.html)

Hook for push can be added to github project webhook. To learn more about webhooks, go to: https://developer.github.com/webhooks/ .

Permission for this folder and files (as well as for the folder and files that are used by git and the test framework) should be such that the user that executes the script can access it.
