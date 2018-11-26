#!/bin/bash

# This script is called when the docker container of DSI Runtime is started.
# It creates the server configuration files from a WLP configuration template.
# The first argument of the script is the name of the template. By default,
# it is 'dsi-runtime-single'.
# The second argument is the hostname of the catalog server.
# The third optional argument is the hostname of a runtime container, used by connectivity container to check grid availability before starting

set -e

function docker_stop() { 
        myecho "Container is being stopped."
        myecho "Stopping server $DSI_TEMPLATE." 
        /dsi-cmd serverManager shutDown --disableSSLHostnameVerification=true --disableServerCertificateVerification=true 
}

function myecho() {
       echo "[start.sh]" "$@"
}
 
function preloadMode {
        egrep CWMBD9395I /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/logs/messages.log | wc -l | sed "s/ *//g"
}

function jprofile_enable {
        myecho "JProfiler enable"

        wget http://download-keycdn.ej-technologies.com/jprofiler/jprofiler_linux_9_2.tar.gz -P /tmp/

        pushd /tmp
        tar -xvf jprofiler_linux_9_2.tar.gz
        popd

        rm /tmp/jprofiler_linux_9_2.tar.gz

        JPROFILER_AGENT="-agentpath:/tmp/jprofiler9/bin/linux-x64/libjprofilerti.so=offline,id=108,config=/root/jprofiler_config.xml"
        echo "$JPROFILER_AGENT" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/jvm.options
}

DSI_HOME="/opt/dsi"

if [ -z "$JAVA_HOME" ]; then
        export JAVA_HOME="$DSI_HOME/jdk/jre"
fi
myecho "JAVA_HOME=$JAVA_HOME"

export PATH=$JAVA_HOME/bin:$PATH
myecho "PATH=$PATH"

if [ -z "$1" ]; then
        DSI_TEMPLATE="dsi-runtime-single"
else
        DSI_TEMPLATE="$1"
fi

if [ ! -z "$2" ]; then
        DSI_CATALOG_HOSTNAME="$2"
fi

myecho "The DSI template $DSI_TEMPLATE is going to be used."

SRV_XML="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.xml"
SRV_XML_PERSISTENCE_INCLUDE="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/persistence.${DSI_DB_TYPE}.xml"
BOOTSTRAP_FILE="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/bootstrap.properties"
GRID_DEPLOYMENT="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/grids/objectGridDeployment.xml"
GRID_OBJECT="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/grids/objectgrid.xml"
GRID_OBJECT_PERSISTENCE="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/objectgrid.xml.PERSISTENCE"
LOGDIR="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/logs"
CONSOLELOG="$LOGDIR/console.log"


INTERNAL_IP=`hostname -I | sed 's/ //g'`

if [ ! -f "$SRV_XML" ]; then
        echo "JAVA_HOME=$JAVA_HOME" > /opt/dsi/runtime/wlp/etc/server.env

        DSI_VERSION=`/opt/dsi/runtime/wlp/bin/productInfo featureInfo|grep iaRuntime-|sed 's/iaRuntime-\(.*\) .*/\1/g'`
        myecho "DSI_VERSION=$DSI_VERSION"

        find /opt/dsi/runtime/wlp/templates/servers/ -name "server.xml" -exec sed -i "s/_DSI_VERSION_/$DSI_VERSION/g" {} \;

        myecho "Creating DSI server $DSI_TEMPLATE"
        /opt/dsi/runtime/wlp/bin/server create $DSI_TEMPLATE --template=$DSI_TEMPLATE || myecho "$DSI_TEMPLATE was already created"
        myecho "WLP server $DSI_TEMPLATE has been created"
 
        echo "" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.env
        echo "JAVA_HOME=$JAVA_HOME" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.env
        
        if [ ! -z "$DSI_DB_TYPE" ] ; then
                myecho "Setting database support in grid configuration"
                cp "$GRID_OBJECT_PERSISTENCE" "$GRID_OBJECT"
        fi

        if [ ! -z "$DSI_JPROFILER" ]; then
                jprofile_enable
        fi

        if [[ ! -z "$DSI_PARTITIONS_COUNT" && -f "$GRID_DEPLOYMENT" ]]; then
                myecho "Updating DSI_PARTITIONS_COUNT to $DSI_PARTITIONS_COUNT"
                sed -i "s/numberOfPartitions=\"[0-9]*\"/numberOfPartitions=\"$DSI_PARTITIONS_COUNT\"/g" "$GRID_DEPLOYMENT"
        fi

        if [[ ! -z "$MAX_SYNC_REPLICAS" && -f "$GRID_DEPLOYMENT" ]] ; then
                myecho "Updating MAX_SYNC_REPLICAS to $MAX_SYNC_REPLICAS"
                sed -i "s/maxSyncReplicas=\"[0-9]*\"/maxSyncReplicas=\"$MAX_SYNC_REPLICAS\"/g" "$GRID_DEPLOYMENT"
        fi

        if [[ ! -z "$MAX_ASYNC_REPLICAS" && -f "$GRID_DEPLOYMENT" ]] ; then
                myecho "Updating MAX_ASYNC_REPLICAS to $MAX_ASYNC_REPLICAS"
                sed -i "s/maxAsyncReplicas=\"[0-9]*\"/maxAsyncReplicas=\"$MAX_ASYNC_REPLICAS\"/g" "$GRID_DEPLOYMENT"
        fi
else
        myecho "$SRV_XML already exist"
fi

if [ ! -z "$DSI_DB_TYPE" ]; then
        myecho "Updating DSI Database data and credentials in $BOOTSTRAP_FILE"
        sed -i "s/dsi.db.type=*$/dsi.db.type=$DSI_DB_TYPE/" "$BOOTSTRAP_FILE"
        sed -i "s/dsi.db.hostname=.*$/dsi.db.hostname=$DSI_DB_HOSTNAME/" "$BOOTSTRAP_FILE"
        sed -i "s/dsi.db.port=.*$/dsi.db.port=$DSI_DB_PORT/" "$BOOTSTRAP_FILE"
        sed -i "s/dsi.db.name=.*$/dsi.db.name=$DSI_DB_NAME/" "$BOOTSTRAP_FILE"
        sed -i "s/dsi.db.schema=.*$/dsi.db.schema=$DSI_DB2_SCHEMA/" "$BOOTSTRAP_FILE"
        sed -i "s/dsi.db.user=.*$/dsi.db.user=$DSI_DB_USER/" "$BOOTSTRAP_FILE"
        sed -i "s/dsi.db.password=.*$/dsi.db.password=$DSI_DB_PASSWORD/" "$BOOTSTRAP_FILE"

        sed -i "s/ia_runtime\(.*\)databaseInitScript=[^ ]* /ia_runtime\1/g" "$SRV_XML"
        if [ ! -z "$DSI_DB_DATABASEINITSCRIPT" ]; then
                myecho Updating databaseInitScript to "$DSI_DB_DATABASEINITSCRIPT" in "$SRV_XML"
                DSI_DB_DATABASEINITSCRIPT_ESCAPED=`echo $DSI_DB_DATABASEINITSCRIPT | sed "s/\//\\\\\\\\\//g"`
                sed -i "s/ia_runtime\(.*\)\/>/ia_runtime\1 databaseInitScript=\"$DSI_DB_DATABASEINITSCRIPT_ESCAPED\" \/>/" "$SRV_XML"
        fi

        sed -i "s/connectionManager\(.*\)\(maxPoolSize=[^ \/]*\)/connectionManager\1/g"  "$SRV_XML_PERSISTENCE_INCLUDE"
        if [ ! -z "$DSI_DB_MAXPOOLSIZE" ]; then
                myecho Updating maxPoolSize to "$DSI_DB_MAXPOOLSIZE" in "$SRV_XML_PERSISTENCE_INCLUDE"
                sed -i "s/connectionManager\(.*\)\/>/connectionManager\1 maxPoolSize=\"$DSI_DB_MAXPOOLSIZE\"\/>/" "$SRV_XML_PERSISTENCE_INCLUDE"
        fi
        
        sed -i "s/ia_persistence\(.*\)\(deleteBatchSize=[^ \/]*\)/ia_persistence\1/g"  "$SRV_XML_PERSISTENCE_INCLUDE"
        if [ ! -z "$DSI_DB_DELETEBATCHSIZE" ]; then
                 myecho Setting deleteBatchSize to "$DSI_DB_DELETEBATCHSIZE" in "$SRV_XML_PERSISTENCE_INCLUDE"
                 sed -i "s/ia_persistence\(.*\)\/>/ia_persistence\1 deleteBatchSize=\"$DSI_DB_DELETEBATCHSIZE\"\/>/" "$SRV_XML_PERSISTENCE_INCLUDE"
        fi

        sed -i "s/ia_persistence\(.*\)\(deletePauseInterval=[^ \/]*\)/ia_persistence\1/g"  "$SRV_XML_PERSISTENCE_INCLUDE"
        if [ ! -z "$DSI_DB_DELETEPAUSEINTERVAL" ]; then
                myecho Setting deletePauseInterval to "$DSI_DB_DELETEPAUSEINTERVAL" in "$SRV_XML_PERSISTENCE_INCLUDE"
                sed -i "s/ia_persistence\(.*\)\/>/ia_persistence\1 deletePauseInterval=\"$DSI_DB_DELETEPAUSEINTERVAL\"\/>/" "$SRV_XML_PERSISTENCE_INCLUDE"
        fi

        sed -i "s/ia_persistence\(.*\)\(maxBatchSize=[^ \/]*\)/ia_persistence\1/g"  "$SRV_XML_PERSISTENCE_INCLUDE"
        if [ ! -z "$DSI_DB_MAXBATCHSIZE" ]; then
                myecho Setting maxBatchSize to "$DSI_DB_MAXBATCHSIZE" in "$SRV_XML_PERSISTENCE_INCLUDE"
                sed -i "s/ia_persistence\(.*\)\/>/ia_persistence\1 maxBatchSize=\"$DSI_DB_MAXBATCHSIZE\"\/>/" "$SRV_XML_PERSISTENCE_INCLUDE"
        fi

        sed -i "s/ia_persistence\(.*\)\(maxCacheAge=[^ \/]*\)/ia_persistence\1/g"  "$SRV_XML_PERSISTENCE_INCLUDE"
        if [ ! -z "$DSI_DB_MAXCACHEAGE" ]; then
                myecho Setting maxCacheAge to "$DSI_DB_MAXCACHEAGE" in "$SRV_XML_PERSISTENCE_INCLUDE"
                sed -i "s/ia_persistence\(.*\)\/>/ia_persistence\1 maxCacheAge=\"$DSI_DB_MAXCACHEAGE\"\/>/" "$SRV_XML_PERSISTENCE_INCLUDE"
        fi 
fi


if [ ! -z "$DSI_CATALOG_HOSTNAME" ]; then
        myecho "Updating $BOOTSTRAP_FILE with $DSI_CATALOG_HOSTNAME"
        sed -i "s/ia.bootstrapEndpoints=DSI_CATALOG_HOSTNAME:2809/ia.bootstrapEndpoints=$DSI_CATALOG_HOSTNAME:2809/g" "$BOOTSTRAP_FILE"
        myecho "Updating $SRV_XML with $DSI_CATALOG_HOSTNAME"
        sed -i "s/host=\"DSI_CATALOG_HOSTNAME\"/host=\"$DSI_CATALOG_HOSTNAME\"/g" "$SRV_XML"
fi

myecho "The IP of the DSI server is $INTERNAL_IP"

if [ -f "$BOOTSTRAP_FILE" ]; then
        sed -i "s/ia\.host\=localhost/ia\.host\=$INTERNAL_IP/" "$BOOTSTRAP_FILE"
        myecho "Internal IP: $INTERNAL_IP"
fi

if [ ! -z "$LOGGING_TRACE_SPECIFICATION" ] ; then
        myecho Updating traceSpecification with "$LOGGING_TRACE_SPECIFICATION"
        sed -i "s/traceSpecification=\".*\"/traceSpecification=$LOGGING_TRACE_SPECIFICATION/" "$SRV_XML"
fi

if [ ! -z "$DSI_USER" ] ; then
        myecho Updating DSI user with "$DSI_USER"
        sed -i "s/ia.test.user=.*$/ia.test.user=$DSI_USER/" "$BOOTSTRAP_FILE"
fi

if [ ! -z "$DSI_PASSWORD" ] ; then
        myecho Updating DSI password with "$DSI_PASSWORD"
        sed -i "s/ia.test.password=.*$/ia.test.password=$DSI_PASSWORD/" "$BOOTSTRAP_FILE"
fi

if [ ! -z "$3" ]; then
         RUNTIME_HOSTNAME="$3"
         while true ; do
                 myecho Testing availability of grid on runtime server $RUNTIME_HOSTNAME before starting connectivity container
                 GRID_ONLINE=`/dsi-cmd serverManager isonline --host=$RUNTIME_HOSTNAME --disableSSLHostnameVerification=true --disableServerCertificateVerification=true | egrep "is online" | wc -l`
                 if [ "$GRID_ONLINE" -eq 1 ]; then
                         break
                 fi
                 myecho Grid is not yet available, holding for 10 seconds.
                 sleep 10
         done
fi

trap docker_stop 0

mkdir -p $LOGDIR
/opt/dsi/runtime/wlp/bin/server run "$DSI_TEMPLATE" | tee $CONSOLELOG &

if [ "$DSI_DB_AUTOLOAD" == "1" ] ; then
        until [ "$PRELOADMODE" == "1" ]
        do
                myecho "Waiting 5s before checking that the server is in preload mode"
                sleep 5
                PRELOADMODE=`preloadMode`
                myecho "preloadMode result: $PRELOADMODE"
        done
        myecho "Launching dataLoadManager autoload"
        /dsi-cmd dataLoadManager autoload --disableServerCertificateVerification=true --disableSSLHostnameVerification=true
fi

#wait for trapped docker_stop
wait ${!}
