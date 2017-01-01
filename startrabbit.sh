#!/bin/bash

# RABBITMQ_DEFAULT_USER=`env username`
# RABBITMQ_DEFAULT_PASS=`env password`
# CLUSTER_WITH=`env CLUSTER_WITH`
HOSTNAME=`env hostname`

echo $RABBITMQ_DEFAULT_USER
echo $RABBITMQ_DEFAULT_PASS
echo $HOSTNAME
echo $CLUSTER_WITH

change_default_user() {	
	if [ -z $RABBITMQ_DEFAULT_USER ] && [ -z $RABBITMQ_DEFAULT_PASS ]; then
		echo "Maintaining default 'guest' user"
	else 
		echo "Removing 'guest' user and adding ${RABBITMQ_DEFAULT_USER}"
		# rabbitmq-server -detached
		rabbitmqctl delete_user guest
		rabbitmqctl add_user $RABBITMQ_DEFAULT_USER $RABBITMQ_DEFAULT_PASS
		rabbitmqctl set_user_tags $RABBITMQ_DEFAULT_USER administrator
		rabbitmqctl set_permissions -p / $RABBITMQ_DEFAULT_USER ".*" ".*" ".*"
		echo "End adding ${RABBITMQ_DEFAULT_USER}"
	fi
}

chmod 400 /var/lib/rabbitmq/.erlang.cookie
chown -R rabbitmq /var/lib/rabbitmq/
ls -al /var/lib/rabbitmq/

if [ -z "$CLUSTERED" ]; then
	# if not clustered then start it normally as if it is a single server
	echo 'Start Rabbitmq Server'
	# rabbitmq-server start
	# rabbitmqctl status
	# rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
	# tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log
	change_default_user	
	rabbitmq-server
else
	echo 'Start Rabbitmq CLUSTER'
	if [ -z "$CLUSTER_WITH" ]; then
		echo 'CLUSTER_WITH EXISTS'
		# If clustered, but cluster with is not specified then again start normally, could be the first server in the
		# cluster
		# /usr/sbin/rabbitmq-server&
		# rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
		# tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log
		rabbitmq-server
	else
		echo 'NOT CLUSTER_WITH EXISTS'
		# /usr/sbin/rabbitmq-server & rabbitmqctl wait
		/usr/sbin/rabbitmq-server &
		rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
		rabbitmq-server -detached
		# rabbitmqctl cluster_status
		rabbitmqctl stop_app
		rabbitmqctl reset
		if [ -z "$RAM_NODE" ]; then
			echo 'NOT RAM MODE'
			rabbitmqctl join_cluster rabbit@$CLUSTER_WITH
		else
			echo 'RAM MODE'
			rabbitmqctl join_cluster --ram rabbit@$CLUSTER_WITH
		fi
		rabbitmqctl start_app
		rabbitmq-server
                
		# Tail to keep the a foreground process active..
		# tail -f /var/log/rabbitmq/rabbit\@$HOSTNAME.log
	fi
fi

