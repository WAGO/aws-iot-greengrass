#!/bin/sh

set -e

#Only necessary for use behind a corporate firewall
curl -ksSL $(curl -ksSL $(curl -ksSL https://artifactory.wago.local/api/storage/certs-generic-prod-local/wago-intercept-certificates?lastModified | jq -r .'uri') | jq -r .'downloadUri') -o /usr/local/share/ca-certificates/wago.crt; exit 0
update-ca-certificates

/greengrass/ggc/core/greengrassd start

daemon_pid=`cat /var/run/greengrassd.pid`
# block docker exit until daemon process dies.
while [ -d /proc/$daemon_pid ]
do
 # Sleep for 1s before checking that greengrass daemon is still alive
 daemon_cmdline=`cat /proc/$daemon_pid/cmdline`
 if [[ $daemon_cmdline != ^/greengrass/ggc/packages/$GG_VERSION/bin/daemon.* ]]; then 
  sleep 1;
 else
  break;
 fi;
done 
