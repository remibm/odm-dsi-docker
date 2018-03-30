# Run an ODM DSI Runtime Cluster on Docker

## Prerequisites

You can use the provided materials on MacOS or Ubuntu 16.04 LTS 64-bit. And you can use any Linux VM with a recent version of Docker. Before you start, make sure you have installed the following software:

* IBM ODM Decision Server Insights V8.9.2
* Docker 17.09
* Docker Compose 1.17
* Curl 7.47.0
* A Docker image of the DSI runtime, see instructions in the section
  "Build the Docker Image" of the [Run ODM DSI Runtime on Docker documentation](../../README.md).

OK, let's continue...

### Start and test a DSI cluster

The directory `samples/cluster` contains an example of a DSI cluster based on
Docker Compose. Used with Docker Swarm, the cluster can be hosted on multiple servers.
The topology of the sample cluster is using 1 catalog server, 3 runtime servers, 1 inbound and 1
outbound server. It can be modified by changing the file `docker-compose.yaml`.
The dsi-runtime image used can be customized with environement variable `DSI_IMAGE` which default value is stored in `samples/cluster/.env`.
For instance, for MacOS, `DSI_IMAGE=dsi-runtime-ibmjava`.

To start the DSI cluster:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/cluster
docker-compose up
```

Wait until the cluster is ready, the output should end with:
```
dsi-runtime-container2    | [AUDIT   ] CWMBD9737I: Waiting for backing store to become available
dsi-runtime-container1    | [AUDIT   ] CWMBD0000I: IBM Decision Server Insights version 8.9.1.201710162214
dsi-runtime-container3    | [AUDIT   ] CWMBD0000I: IBM Decision Server Insights version 8.9.1.201710162214
dsi-runtime-container1    | [AUDIT   ] CWWKF0012I: The server installed the following features: [ia:iaRuntime-8.9.1, jsp-2.2, servlet-3.1, ia:iaRulesEngineApi-1.4.0, ssl-1.0, jndi-1.0, ia:iaCommon-8.9.1, eXtremeScale.client-1.1, ia:iaAnalytics-8.9.1, appSecurity-2.0, jaxrs-1.1, restConnector-1.0, blueprint-1.0, ia:iaGateway-8.9.1, json-1.0, eXtremeScale.server-1.1, distributedMap-1.0, wab-1.0, ia:iaDispatcher-8.9.1, ia:iaRulesEngine-1.30.2, ia:iaRulesEngine-1.40.3].
dsi-runtime-container1    | [AUDIT   ] CWWKF0011I: The server dsi-runtime-container is ready to run a smarter planet.
dsi-runtime-container3    | [AUDIT   ] CWWKF0012I: The server installed the following features: [ia:iaRuntime-8.9.1, jsp-2.2, servlet-3.1, ia:iaRulesEngineApi-1.4.0, ssl-1.0, jndi-1.0, ia:iaCommon-8.9.1, eXtremeScale.client-1.1, ia:iaAnalytics-8.9.1, appSecurity-2.0, jaxrs-1.1, restConnector-1.0, blueprint-1.0, ia:iaGateway-8.9.1, json-1.0, eXtremeScale.server-1.1, distributedMap-1.0, wab-1.0, ia:iaDispatcher-8.9.1, ia:iaRulesEngine-1.30.2, ia:iaRulesEngine-1.40.3].
dsi-runtime-container3    | [AUDIT   ] CWWKF0011I: The server dsi-runtime-container is ready to run a smarter planet.
dsi-runtime-container1    | [AUDIT   ] CWWKT0016I: Web application available (default_host): http://2165c0eef080:9080/ibm/ia/rest/
dsi-runtime-container1    | [AUDIT   ] CWWKT0016I: Web application available (default_host): http://2165c0eef080:9080/IBMJMXConnectorREST/
dsi-runtime-container3    | [AUDIT   ] CWWKT0016I: Web application available (default_host): http://aea79a14dc33:9080/ibm/ia/rest/
dsi-runtime-container3    | [AUDIT   ] CWWKT0016I: Web application available (default_host): http://aea79a14dc33:9080/IBMJMXConnectorREST/
dsi-runtime-outbound      | [WARNING ] CWMBD9684W: The following warning message is being suppressed. It has occurred 20 times in the last 20,074 milliseconds. Message: CWMBE2540W: The outbound queue monitor is currently unable to retrieve the list of active solutions. The grid state is "UNKNOWN".
dsi-runtime-container2    | [AUDIT   ] CWMBD9737I: Waiting for backing store to become available
dsi-runtime-container1    | [AUDIT   ] CWWKT0016I: Web application available (default_host): http://2165c0eef080:9080/ibm/insights/
dsi-runtime-container3    | [AUDIT   ] CWWKT0016I: Web application available (default_host): http://aea79a14dc33:9080/ibm/insights/
dsi-runtime-container2    | [AUDIT   ] CWMBD9738I: Backing store is available
```

Deploy the "simple" solution:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/cluster
./solution_deploy.sh
```

The command deploys the solution to all the DSI runtimes and the connectivity to the DSI inbound
server. The HTTPS port of the first DSI runtime is bound to the port 9443 of the host.

Then you can send an event using:
```sh
cd $DSI_DOCKER_GIT/dsi-runtime/samples/cluster
./create_person.sh jeanfi
```

Finally, verify that it has created the entity, by opening a browser and entering the
URL https://localhost:9443/ibm/ia/rest/solutions/simple_solution/entity-types/simple.Person.
