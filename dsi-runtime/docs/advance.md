## Advanced usage of DSI on Docker

## Deployment of a DSI solution from a Docker container

It is possible to deploy a solution by using the `solutionManager` script
from a DSI runtime container. It avoids the need to have an installation of DSI
on the machine where the .ESA file is hosted.

First, copy the .ESA file `mysol.esa` to a directory `/mylocaldropins`.

Assuming a `docker-compose.yaml` file including `dsi-runtime` service exists in current directory,
the solution can be deployed on `dsi.hostname` with:

```
docker-compose run -v /mylocaldropins:/dropins dsi-runtime /dsi-cmd solutionManager deploy remote /dropins/mysol.esa --host=dsi.hostname --port=9443 --sslProtocol=TLSv1.2 --disableServerCertificateVerification=true --disableSSLHostnameVerification=true --username=tester --password=tester
```

The `dsi-cmd` script can be used to run any usual DSI CLI (`solutionManager`, `propertyManager`, etc.) directly from a Docker container.

## Container parameter customization using docker-compose

DSI containers can be customized with specific parameters specified in `.env` file when running docker-compose.

Customizable variables:
 * `LOGGING_TRACE_SPECIFICATION` sets logging specification in `server.xml` of container. See specific documentation about Liberty logging and trace [here](https://www.ibm.com/support/knowledgecenter/en/SSEQTP_8.5.5/com.ibm.websphere.wlp.doc/ae/rwlp_logging.html).

 * `DSI_USER` and `DSI_PASSWORD` override default DSI credentials.

## Persist deployed solutions

As docker containers are stateless, deployed solutions in containers are not persisted.
Following, two different ways to persist the solutions.

### Keep deployed solution in a Docker volume

The preferred way to persist data in docker is to use volumes (https://docs.docker.com/engine/admin/volumes/volumes/).

To avoid the need to redeploy a solution after a container is restarted, a Docker volume can be used to store the DSI data.

Running `docker-compose up dsi-runtime` will create a volume `dsiruntime_volume-solutions`.

Deploy the solution in the running container:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/simple
./solution_deploy.sh $DSI_HOME localhost 9443
```

The solution is now in the volume and can be used by another container.

### Creation of a docker image with a deployed solution

Run a single DSI runtime with Docker:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime
docker run --name dsi-runtime -p9443:9443 dsi-runtime
```

Deploy the solution in the running container.

Stop the running DSI runtime in a clean way:
```sh
docker exec -ti dsi-runtime /opt/dsi/runtime/wlp/bin/server stop dsi-runtime-single
```

Create an image with the deployed solution:
```sh
docker commit dsi-runtime dsi-runtime-simple-sol
```

Now, you can run a container with the 'simple' solution by using the
docker image you created:
```sh
docker run -p9443:9443 dsi-runtime-simple-sol
```

## Change the default configuration of DSI

Depending on your needs, you might want to use another DSI configuration.
It is possible to add multiple DSI configurations to the same Docker image.
There are 3 ways to do this:

### Add custom templates into the dsi-runtime image

To do this, set the environment variable `DSI_TEMPLATES` to the path where the `servers` directory, which contains the templates, is located.

For example, if the templates are in home/example/servers
```sh
export DSI_TEMPLATES=home/example
```

Then rebuild the Docker image using the script `<DSI_DOCKER_GIT>/build.sh`.

Then, to run the single DSI runtime with a template, edit the `.env` file to define the variable `DSI_TEMPLATE` with the name of the template and simply run `docker-compose up dsi-runtime`.

### Add custom templates into a specific image based on the dsi-runtime image

After having built dsi-runtime image, create another image based on dsi-runtime that copy the templates in /opt/dsi/runtime/wlp/templates/servers.

Create a Dockerfile.
```sh
FROM dsi-runtime
COPY template /opt/dsi/runtime/wlp/templates/servers/template
CMD /root/start.sh
```

Build the image using docker
docker build -t myImage .

### Pass custom templates to a dsi-runtime docker container

Put your templates in the named volume `dsiruntime_volume-templates`.

Then, to run the single DSI runtime with a template, edit the `.env` file to define the variable `DSI_TEMPLATE` with the name of the template and simply run `docker-compose up dsi-runtime`.
