#!/bin/bash

function isonline() {
        SOL_MANAGER_OPTS="--host=$1 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"
        docker-compose run --rm dsi-runtime /dsi-cmd serverManager isonline $SOL_MANAGER_OPTS
}

function isSolutionReady() {
        SOL_MANAGER_OPTS="--host=$1 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester"
        docker-compose run --rm dsi-runtime /dsi-cmd solutionManager isready simple_solution $SOL_MANAGER_OPTS
}

function setvar {
        VALUE="${@:2}"
        eval export $1=\"$VALUE\"
        echo "$1=$VALUE"
}

function timeout {
        let TIMEOUTCOUNT=$TIMEOUTCOUNT+1
        if [ "$TIMEOUTCOUNT" == "$1" ] ; then
                echo "exiting on timeout" 
                exit 1
        fi
        echo "retry $TIMEOUTCOUNT / $1 "
}


cd `dirname $0`
setvar SRC_DIR `pwd`

echo "Starts DSI Runtime Cluster"
setvar RUNTIME_NB 3
setvar INBOUND_NB 2
setvar OUTBOUND_NB 2

docker-compose up -d --scale dsi-runtime=$RUNTIME_NB  \
        --scale dsi-runtime-inbound=$INBOUND_NB \
        --scale dsi-runtime-outbound=$OUTBOUND_NB

# wait until DSI inbound connectivity is ready
TIMEOUTCOUNT=0
until [ "$INBOUND_READY" == "$INBOUND_NB" ]
do
        echo "Waiting 5s before checking that we have $INBOUND_NB inbound services ready"
        sleep 5
        setvar INBOUND_READY `docker-compose logs dsi-runtime-inbound | grep CWWKT0016I | wc -l `
        timeout 100
done


echo "Deploys solution"
$SRC_DIR/solution_deploy.sh 

# waiting the solution to be ready
setvar DSI_IP `docker-compose logs dsi-runtime | egrep "IP of the DSI server is" | awk '{print $NF}' | sed "s/\n/ /" | perl -ne 's/\n/ /g;print'`
TIMEOUTCOUNT=0
until [ "$ISSOLREADY" == "1" ]
do
echo "Waiting 5s before checking that the solution is ready"
        sleep 5
        ISSOLREADY=`isSolutionReady $DSI_IP >/dev/null && echo 1 || echo 0`
        echo "Is solution ready result: $ISSOLREADY"
        timeout 100
done

LIST=( "Amanda" "Bob" "Cindy" "Dimitri" "Eva" "Fabio" "Ginni" "Hugh" "Irene" "Keanu" )
for PERSON in "${LIST[@]}" ; do 
        echo "Create $PERSON"
        $SRC_DIR/create_person.sh  $PERSON
done
