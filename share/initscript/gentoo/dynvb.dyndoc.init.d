#!/sbin/runscript

start() {
ebegin "Starting dyndoc server"
start-stop-daemon --start --background --name dyndoc-SERVER --pidfile /var/run/dyndoc-server.pid --make-pidfile  --user ${DYNDOC_USER} --chdir /export/dyndoc-server -e GEM_HOME=${GEM_HOME} --exec ${DYNDOC_SERVER} -- ${DYNDOC_SERVER_OPTS} 
##> /dev/null 2&>1
eend $?
}
stop() {
ebegin "Stopping dyndoc server"
start-stop-daemon --stop  --pidfile /var/run/dyndoc-server.pid
eend $?
}
