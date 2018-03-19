#!/bash

if [ -z "$1" ]; then
        echo miniTest: missing argument for <buildDir> pointing to current DSI install dir
        exit 1
fi

echo miniTest: removing remaining dsi-runtime containers and images
docker ps -a | egrep dsi-runtime | awk '{print $1}' | xargs docker rm -f 
docker rmi dsi-runtime dsi-runtime-ibmjava dsi-runtime-openjdk

#start fail on error only now because we dont want to file on images/containers cleanup
set -e

echo miniTest: creating dsi-runtime images
./build.sh $1
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        export DSI_IMAGE=dsi-runtime-ibmjava
else
        export DSI_IMAGE=dsi-runtime
fi

echo miniTest running single runtime container
docker-compose up -d

echo miniTest: retrieving container ip
sleep 5
DSI_CONTAINER=`docker-compose logs | egrep "IP of the DSI server is" | awk '{print $NF}'`
echo IP of dsi-runtime service: $DSI_CONTAINER

echo holding until grid is available
while true ; do
         echo Testing availability of grid on runtime server $DSI_CONTAINER before starting connectivity container
         GRID_ONLINE=`docker-compose run dsi-runtime /dsi-cmd serverManager isonline --host=$DSI_CONTAINER --disableSSLHostnameVerification=true --disableServerCertificateVerification=true | egrep "is online" | wc -l`
         if [ "$GRID_ONLINE" -eq 1 ]; then
                 break
         fi
         echo Grid is not yet available, holding for 10 seconds.
         sleep 10
done

echo miniTest: deploying solution
export DROPINSDIR=/tmp/dropins.$$
mkdir $DROPINSDIR
cp ./samples/simple/simple_solution-0.0.esa $DROPINSDIR/mysol.esa
docker-compose run -v $DROPINSDIR:/dropins dsi-runtime /dsi-cmd solutionManager deploy remote /dropins/mysol.esa \
--host=$DSI_CONTAINER --port=9443 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester

echo miniTest:final cleanup
#rm -rf $DROPINSDIR
