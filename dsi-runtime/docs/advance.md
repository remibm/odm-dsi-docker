# Advanced usage of DSI on Docker

## Deployment of a DSI solution from a Docker container

It is possible to deploy a solution by using the `solutionManager` script
from a DSI runtime container. Using the script in a container avoids the need to have an installation of DSI
on the machine where the .ESA file is hosted.

To prepare for deployment of your solution, copy the .ESA file `mysol.esa` to a directory `/mylocaldropins`.

Then, run the following command to deploy the solution on `dsi.hostname`:
```
docker run -ti -v /mylocaldropins:/dropins dsi-runtime /dsi-cmd solutionManager deploy remote /dropins/mysol.esa --host=dsi.hostname --port=9443 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester
```

The `dsi-cmd` script can be used to run any DSI CLI (`solutionManager`, `propertyManager`, etc.) directly from a Docker container.

## Container parameter customization using docker-compose

Using docker-compose, DSI containers can be customized with parameters specified in the `.env` file.
These parameters override corresponding values in the DSI configuration.

Customizable variables:
 * `LOGGING_TRACE_SPECIFICATION` sets the logging specification in the `server.xml` file of a container. For more information, see [Liberty: Logging and trace](https://www.ibm.com/support/knowledgecenter/en/SSEQTP_8.5.5/com.ibm.websphere.wlp.doc/ae/rwlp_logging.html).

 * `DSI_USER` and `DSI_PASSWORD` set DSI credentials.

 * `DSI_PARTITIONS_COUNT` sets the number of partitions for the map set 

 * `MAX_SYNC_REPLICAS` and `MAX_ASYNC_REPLICAS` set the maximum number of synchronous and asynchronous replicas for each partition in the map set.

## Persist deployed solutions

As docker containers are stateless, deployed solutions in containers are not persisted.
You can persist solutions in two different ways.

### Keep deployed solution in a Docker volume

The preferred way to persist data in docker is to use [volumes] (https://docs.docker.com/engine/admin/volumes/volumes/).

To avoid the need to redeploy a solution after a container is restarted, a Docker volume can be used to store the DSI data.

Running `docker-compose up dsi-runtime` creates a volume `dsiruntime_volume-solutions`.

To deploy a solution in the running container use the following command:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/simple
./solution_deploy.sh $DSI_HOME localhost 9443
```

The solution is persisted in the volume and can be used by another container.

### Create a docker image with a deployed solution

1. Run a single DSI runtime with Docker:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime
docker run --name dsi-runtime -p9443:9443 dsi-runtime
```

2. Deploy the solution in the running container.

3. Stop the running DSI runtime:
```sh
docker exec -ti dsi-runtime /opt/dsi/runtime/wlp/bin/server stop dsi-runtime-single
```

4. Create an image with the deployed solution:
```sh
docker commit dsi-runtime dsi-runtime-simple-sol
```

5. Run a container with the 'simple' solution by using the docker image you created:
```sh
docker run -p9443:9443 dsi-runtime-simple-sol
```

## Change the default configuration of DSI

Depending on what you need, you might want to change the default DSI configuration.
It is possible to add multiple DSI configurations to the same Docker image.
There are 3 ways to do this:

### Add custom templates to the dsi-runtime image

To add a custom template, set the environment variable `DSI_TEMPLATES` to the path of the `servers` directory that contains the templates.

For example, if the templates are located in home/example/servers, set the variable to home/example:
```sh
export DSI_TEMPLATES=home/example
```

Then rebuild the Docker image using the `<DSI_DOCKER_GIT>/build.sh` script.

To run the single DSI runtime with a template, edit the `.env` file to define the `DSI_TEMPLATE` variable with the name of the template and then run the following command:
```sh
docker-compose up dsi-runtime
```

### Add custom templates to a specific image based on the dsi-runtime image

You can create another image based on the dsi-runtime image by copying the templates in /opt/dsi/runtime/wlp/templates/servers.

Create a Dockerfile.
```sh
FROM dsi-runtime
COPY template /opt/dsi/runtime/wlp/templates/servers/template
CMD /root/start.sh
```

Build the image using docker:
```sh
docker build -t myImage .
```

### Pass custom templates to a dsi-runtime docker container

Put your templates in the named volume `dsiruntime_volume-templates`.

To run the single DSI runtime with a template, edit the `.env` file to define the `DSI_TEMPLATE` variable with the name of the template and then run the following command:
```sh
docker-compose up dsi-runtime
```
