# Run ODM DSI Runtime on Docker

This page shows you how to run a single DSI Runtime on Docker. For some additional usage scenarios, like creating a volume to persist your solutions, see the [advance.md](dsi-runtime/docs/advance.md) documentation.

## Prerequisites

You can use the provided materials on MacOS or Ubuntu 16.04 LTS 64-bit. And you can use any Linux VM with a recent version of Docker.
Before you start, make sure you have installed the following software:
* [IBM ODM Decision Server Insights V8.9.2](https://www.ibm.com/support/knowledgecenter/en/SSQP76_8.9.2/com.ibm.odm.itoa/topics/odm_itoa.html)
* [Docker 17.09](https://www.docker.com/what-docker)
* Curl 7.47.0
* Docker Compose 1.17

Note: To be able to create the Docker image you must have an installation of IBM ODM
Decision Server Insights V8.9.2.

OK, let's continue...

## Build the Docker image

### Install the scripts

The source for this tutorial is available on Github in this
GIT repository: https://github.com/ODMDev/odm-dsi-docker.

Change the current working directory to the location where you want the cloned directory to be made.
Get the source files from Github over the SSH transfer protocol by typing:

``
git clone https://github.com/ODMDev/odm-dsi-docker.git
``

In the following document:
 * `DSI_DOCKER_GIT` designates the directory containing the working copy of
   this GIT repository.
 * `DSI_HOME` designates the directory containing the installation of ODM DSI V8.9.2.

### Create the Docker image

The Docker image can be produced by running the script 'build.sh'. Pass the path of the ODM installation directory as the first
argument. For example:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime
./build.sh $DSI_HOME
```

The output should end with:

```
The docker image dsi-runtime has been created.
```

This message means that the Docker image `dsi-runtime` has been produced.
The command `docker images` can be used to verify that the image is now listed in the local registry of Docker.

### MacOS

On MacOS the build of the image will use the IBM JDK from the 'ibmjava' image, which might be different to the one supported by DSI Runtime.

The name of this image will be `dsi-runtime-ibmjava` instead of `dsi-runtime`.
Before using docker-compose, you will need to set environment variable `DSI_IMAGE` to `dsi-runtime-ibmjava` in `.env` file.

In order to run containers or clusters on MacOS it is strongly advised to increase default values of CPU and memory in Docker menu `Preferences>Advanced`.
Docker memory setting should be consistent with DSI container max memory heap (`-Xmx`) and actual memory use.
With default templates, we recommend at least 2Gb for each dsi-runtime-ibmjava container.

## Run a single DSI runtime with Docker Compose

```sh
cd $DSI_DOCKER_GIT/dsi-runtime
docker-compose up
```

When DSI is started, the output ends with the following lines:
```
[AUDIT   ] CWWKF0011I: The server dsi-runtime-single is ready to run a smarter planet.
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://58de6092c19c:9080/ibm/ia/debug/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://58de6092c19c:9080/ibm/ia/gateway/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://58de6092c19c:9080/IBMJMXConnectorREST/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://58de6092c19c:9080/ibm/ia/rest/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://58de6092c19c:9080/ibm/insights/
```

REST APIs are available by default on host port 9080 with HTTP and on port 9443 with HTTPS.
To change host ports, change `HTTP_PORT` and `HTTPS_PORT` variables in the `.env` file.

## Test a DSI Runtime running in Docker

### Deploy a solution

To deploy a solution and the connectivity configuration,
the usual command line tools `solutionManager` and `connectivityManager` can be used.

In order to avoid using a DSI installation, it is also possible to deploy the
solution by using a DSI runtime container. For more information see [advance.md](dsi-runtime/docs/advance.md).
This is the way used by the script `solution_deploy.sh`

In a separate command shell to the one you used to run the DSI container:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/simple
./solution_deploy.sh $DSI_IP $DSI_PORT
```

The first argument `DSI_IP` is the IP address or the hostname of the DSI
Runtime. The DSI command is ran in the Docker container, so it is not possible
to use the `localhost` or the loopback addresses.

There are multiple ways to determine the IP adress of a container:
* `docker inspect dsiruntime_dsi-runtime_1`
* `docker exec dsiruntime_dsi-runtime_1 hostname -i`


The second argument `DSI_PORT` is the port of the DSI Runtime. By default,
it is `9443`.

The output of the command line should be similar to:
```
Solution successfully deployed.
CWMBE1146I: Reading the input file: ./simple_solution-0.0.esa
CWMBE1475I: The connectivity server configuration file for the solution "simple_solution" contains the configuration required for the specified endpoints.
CWMBE1148I: Writing to the output file: /tmp/simple_solution-inbound.ear7303141339821942454.tmp
CWMBE1452I: Successfully deployed connectivity for the solution "simple_solution".
CWMBE1498I: Number of active inbound endpoints: 1
CWMBE1499I: Number of active outbound endpoints: 0
```

The DSI runtime console should display a message about the solution:
```
[AUDIT   ] CWWKG0017I: The server configuration was successfully updated in 0.407 seconds.
[AUDIT   ] CWWKF0012I: The server installed the following features: [usr:simple_solution-0.0].
[AUDIT   ] CWWKF0008I: Feature update completed in 0.402 seconds.
[AUDIT   ] CWMBD0055I: Solution simple_solution-0.0 installed.
[AUDIT   ] CWWKG0016I: Starting server configuration update.
[AUDIT   ] CWWKG0028A: Processing included configuration resource: /opt/dsi/runtime/wlp/usr/servers/cisDev/simple_solution-config.xml
[AUDIT   ] CWWKG0017I: The server configuration was successfully updated in 0.040 seconds.
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://58de6092c19c:9080/in/
[AUDIT   ] CWWKZ0001I: Application simple_solution-inbound started in 0.097 seconds.
[AUDIT   ] CWMBD0060I: Solution simple_solution-0.0 ready.
```

### Check that the solution is deployed

Open the URL https://localhost:9443/ibm/ia/rest/solutions/simple_solution/.

The REST command returns the following data:

```xml
<object type="com.ibm.ia.admin.solution.Solution">
        <attribute name="entityTypes">
                <collection type="entityTypes">
                        <string>simple.Person</string>
                </collection>
        </attribute>
        <attribute name="eventTypes">
                <collection type="eventTypes">
                        <string>simple.SayHello</string>
                        <string>simple.CreatePerson</string>
                        <string>simple.Message</string>
                </collection>
        </attribute>
        <attribute name="name">
                <string>simple_solution</string>
        </attribute>
        <attribute name="timeZone">
                <object type="java.time.ZoneId">UTC</object>
        </attribute>
</object>
```

### Send an event

To create an entity of the type `simple.Person`, and an event of type `simple.CreatePerson` send REST API calls to the DSI runtime.

The script `create_person.sh` can be used:
```sh
cd $DSI_DOCKER_GIT/samples/simple
./create_person.sh localhost
```

The first argument is the hostname of the DSI runtime.

### View the created entity

The sent event creates an entity instance of 'simple.Person'.

Open the URL https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person.

The REST command returns the following data:

```xml
<object xmlns:xsd="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.ibm.com/ia/Entity" type="Collection[simple.Person]">
  <attribute name="entities">
    <collection>
      <object type="simple.Person">
        <attribute name="$CreationTime">
          <null/>
        </attribute>
        <attribute name="$IdAttrib">
          <string>name</string>
        </attribute>
        <attribute name="description">
          <string>  </string>
        </attribute>
        <attribute name="name">
          <string>jean</string>
        </attribute>
      </object>
    </collection>
  </attribute>
</object>
```

# Issues and contributions
For issues relating specifically to the Dockerfiles and scripts, please use the [GitHub issue tracker](../../issues).
We welcome contributions following [our guidelines](CONTRIBUTING.md).

# License
The Dockerfiles and associated scripts found in this project are licensed under the [Apache License 2.0](LICENSE).

# Notice
© Copyright IBM Corporation 2017.
