## Advanced usage of DSI on Docker

## Container parameter customization using docker-compose

DSI containers can be customized with specific parameters specified in `.env` file when running docker-compose.

Customizable variables:
 * `LOGGING_TRACE_SPECIFICATION` sets logging specification in `server.xml` of container. See specific documentation about Liberty logging and trace [here](https://www.ibm.com/support/knowledgecenter/en/SSEQTP_8.5.5/com.ibm.websphere.wlp.doc/ae/rwlp_logging.html).
 
## Persist deployed solutions

As docker containers are stateless, deployed solutions in containers are not persisted.
Following, two different ways to persist the solutions.

### Keep deployed solution in a Docker volume

The preferred way to persist data in docker is to use volumes (https://docs.docker.com/engine/admin/volumes/volumes/).

To avoid the need to redeploy a solution after a container is restarted, a Docker volume can be used to store the DSI data.

First, create a volume:
```sh
docker volume create --name dsi-runtime-volume
```

Run a Docker container using this volume to store the DSI files:
```sh
docker run -p9443:9443 -v dsi-runtime-volume:/opt/dsi/runtime/wlp --name dsi-runtime dsi-runtime
```

Deploy the solution in the running container:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/simple
./solution_deploy.sh $DSI_HOME localhost 9443
```

The solution is now in the volume and can be used by another container.

### Creation of a docker image with a deployed solution

Run a Docker container:
```sh
docker run -p9443:9443 dsi-runtime
```

Deploy the solution in the running container:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/simple
./solution_deploy.sh $DSI_HOME localhost 9443
```

Stop the running DSI runtime in a clean way:
```sh
docker exec -ti dsi-runtime /opt/dsi/runtime/wlp/bin/server stop dsi-runtime
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
Each configuration has to be added in a separate sub-directory under the directory `<DSI_DOCKER_GIT>/templates/servers`.

To add a new DSI configuration in the Docker image:
 * Copy the files in `<DSI_DOCKER_GIT>/templates/servers/dsi-runtime`
   to a new directory, for example `<DSI_DOCKER_GIT>/templates/servers/my-dsi-template`
 * Edit the files in `<DSI_DOCKER_GIT>/templates/servers/my-dsi-template`.
 * Rebuild the Docker image using the script `<DSI_DOCKER_GIT>/builds.sh`.

When running the DSI Docker container, the name of the DSI configuration must
be passed as the first argument of the startup script:

```sh
docker run -p9443:9443 --name my-dsi-runtime /root/start.sh my-dsi-template
```
