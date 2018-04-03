#!/bin/bash

# This script is called when the docker container of DSI Runtime is started.
# It creates the server configuration files from a WLP configuration template.
# The first argument of the script is the name of the template. By default,
# it is 'dsi-runtime-single'.
# The second argument is the hostname of the catalog server.
# The third optional argument is the hostname of a runtime container, used by connectivity container to check grid availability before starting

set -e

function jprofile_enable {
        echo "JProfiler enable"

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

echo "JAVA_HOME=$JAVA_HOME"
export PATH=$JAVA_HOME/bin:$PATH

if [ -z "$1" ]; then
        DSI_TEMPLATE="dsi-runtime-single"
else
        DSI_TEMPLATE="$1"
fi

if [ ! -z "$2" ]; then
        DSI_CATALOG_HOSTNAME="$2"
fi

echo "The DSI template $DSI_TEMPLATE is going to be used."

SRV_XML="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.xml"
BOOTSTRAP_FILE="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/bootstrap.properties"
GRID_DEPLOYMENT="/opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/grids/objectGridDeployment.xml"

INTERNAL_IP=`hostname -I| sed 's/ //g'`

if [ ! -f "$SRV_XML" ]; then
        echo "Create the DSI server $DSI_TEMPLATE"
        echo "JAVA_HOME=$JAVA_HOME" > /opt/dsi/runtime/wlp/etc/server.env
        /opt/dsi/runtime/wlp/bin/server create $DSI_TEMPLATE --template=$DSI_TEMPLATE || echo "$DSI_TEMPLATE was already created"
        echo "WLP server $DSI_TEMPLATE has been created"

        echo "" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.env
        echo "JAVA_HOME=$JAVA_HOME" >> /opt/dsi/runtime/wlp/usr/servers/$DSI_TEMPLATE/server.env

        if [ ! -z "$DSI_DB_HOSTNAME" ]; then
                echo "Update DSI_DB_HOSTNAME to $DSI_DB_HOSTNAME in $SRV_XML"
                sed -i "s/\$DSI_DB_HOSTNAME/$DSI_DB_HOSTNAME/g" "$SRV_XML"
        fi
        if [ ! -z "$DSI_DB_USER" ]; then
                echo "Update DSI_DB_USER to $DSI_DB_USER in $SRV_XML"
                sed -i "s/\$DSI_DB_USER/$DSI_DB_USER/g" "$SRV_XML"
        fi
        if [ ! -z "$DSI_DB_PASSWORD" ]; then
                echo "Update DSI_DB_PASSWORD to $DSI_DB_PASSWORD in $SRV_XML"
                sed -i "s/\$DSI_DB_PASSWORD/$DSI_DB_PASSWORD/g" "$SRV_XML"
        fi

        if [ ! -z "$DSI_JPROFILER" ]; then
                jprofile_enable
        fi

        if [[ ! -z "$DSI_PARTITIONS_COUNT" && -f "$GRID_DEPLOYMENT" ]]; then
                echo "Update DSI_PARTITIONS_COUNT to $DSI_PARTITIONS_COUNT"
                sed -i "s/numberOfPartitions=\"[0-9]*\"/numberOfPartitions=\"$DSI_PARTITIONS_COUNT\"/g" "$GRID_DEPLOYMENT"
        fi

        if [[ ! -z "$MAX_SYNC_REPLICAS" && -f "$GRID_DEPLOYMENT" ]] ; then
                echo "Update MAX_SYNC_REPLICAS to $MAX_SYNC_REPLICAS"
                sed -i "s/maxSyncReplicas=\"[0-9]*\"/maxSyncReplicas=\"$MAX_SYNC_REPLICAS\"/g" "$GRID_DEPLOYMENT"
        fi

        if [[ ! -z "$MAX_ASYNC_REPLICAS" && -f "$GRID_DEPLOYMENT" ]] ; then
                echo "Update MAX_ASYNC_REPLICAS to $MAX_ASYNC_REPLICAS"
                sed -i "s/maxAsyncReplicas=\"[0-9]*\"/maxAsyncReplicas=\"$MAX_ASYNC_REPLICAS\"/g" "$GRID_DEPLOYMENT"
        fi
else
        echo "$SRV_XML already exist"
fi

if [ ! -z "$DSI_CATALOG_HOSTNAME" ]; then
        echo "Modifying $BOOTSTRAP_FILE"
        sed -i "s/ia.bootstrapEndpoints=localhost:2809/ia.bootstrapEndpoints=$DSI_CATALOG_HOSTNAME:2809/g" "$BOOTSTRAP_FILE"
fi

if [ ! -z "$2" ]; then
        while true ; do
                echo Testing availability of catalog server $DSI_CATALOG_HOSTNAME before starting container
                CATALOG_TEST_RESULT=`/opt/dsi/runtime/wlp/bin/xscmd.sh -c showPrimaryCatalogServer --catalogEndPoints $DSI_CATALOG_HOSTNAME:2809 | egrep $DSI_CATALOG_HOSTNAME.*TRUE | wc -l`
                if [ "$CATALOG_TEST_RESULT" -eq 1 ] ; then
                        break
                fi
                echo Catalog is not yet online, holding for 5 seconds.
                sleep 5
        done
fi

if [ ! -z "$3" ]; then
         RUNTIME_HOSTNAME="$3"
         while true ; do
                 echo Testing availability of grid on runtime server $RUNTIME_HOSTNAME before starting connectivity container
                 GRID_ONLINE=`/opt/dsi/runtime/ia/bin/serverManager isonline --host=$RUNTIME_HOSTNAME --disableSSLHostnameVerification=true --disableServerCertificateVerification=true | egrep "is online" | wc -l`
                 if [ "$GRID_ONLINE" -eq 1 ]; then
                         break
                 fi
                 echo Grid is not yet available, holding for 10 seconds.
                 sleep 10
         done
fi

echo "The IP of the DSI server is $INTERNAL_IP"

if [ -f "$BOOTSTRAP_FILE" ]; then
        sed -i "s/ia\.host\=localhost/ia\.host\=$INTERNAL_IP/" "$BOOTSTRAP_FILE"
        echo "Internal IP: $INTERNAL_IP"
fi

if [ "$LOGGING_TRACE_SPECIFICATION" !=  "" ] ; then
        echo updating traceSpecification with "$LOGGING_TRACE_SPECIFICATION"
        sed -i "s/traceSpecification=\".*\"/traceSpecification=$LOGGING_TRACE_SPECIFICATION/" "$SRV_XML"
fi

if [ "$DSI_USER" !=  "" ] ; then
        echo updating DSI user with "$DSI_USER"
        sed -i "s/ia.test.user=.*$/ia.test.user=$DSI_USER/" "$BOOTSTRAP_FILE"
fi

if [ "$DSI_PASSWORD" !=  "" ] ; then
        echo updating DSI password with "$DSI_PASSWORD"
        sed -i "s/ia.test.password=.*$/ia.test.password=$DSI_PASSWORD/" "$BOOTSTRAP_FILE"
fi

/opt/dsi/runtime/wlp/bin/server run "$DSI_TEMPLATE"
