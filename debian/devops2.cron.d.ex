#
# Regular cron jobs for the devops2 package.
#
0 4	* * *	root	[ -x /usr/bin/devops2_maintenance ] && /usr/bin/devops2_maintenance
