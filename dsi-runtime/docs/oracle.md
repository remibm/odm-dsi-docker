# Run a DSI Runtime using an Oracle database

Copy the Oracle JDBC driver into the directory
`$DSI_DOCKER_GIT/dsi-runtime/templates/servers/dsi-runtime-oracle`.

Build the Docker image:
```bash
cd $DSI_DOCKER_GIT/dsi-runtime
./build.sh $DSI_HOME
```

Run the DSI Runtime container:

```bash
docker run -p9443:9443 -e DSI_DB_HOSTNAME=$DSI_DB_HOSTNAME -e DSI_DB_USER=$DSI_DB_USER -e DSI_DB_PASSWORD=$DSI_DB_PASSWORD--name my-dsi-runtime dsi-runtime /root/start.sh dsi-runtime-oracle
```

With the following environment variables:
 * DSI_DB_HOSTNAME: the hostname of the Oracle database
 * DSI_DB_PASSWORD: the password of the Oracle database
 * DSI_DB_USER: the user of the Oracle database

The output will be similar to:
```
Launching dsi-runtime-oracle (WebSphere Application Server 8.5.5.9/wlp-1.0.12.cl50920160227-1523) on IBM J9 VM, version pxa6480sr4fp10-20170727_01 (SR4 FP10) (en_US)
[AUDIT   ] CWWKE0001I: The server dsi-runtime-oracle has been launched.
[AUDIT   ] CWWKZ0058I: Monitoring dropins for applications.
[AUDIT   ] CWWKS4104A: LTPA keys created in 0.756 seconds. LTPA key file: /opt/dsi/runtime/wlp/usr/servers/dsi-runtime-oracle/resources/security/ltpa.keys
[WARNING ] CWOBJ0207W: Hostname, 68f784040001, does not appear to be fully qualified. Multi-host connectivity may not function correctly.
[AUDIT   ] CWPKI0803A: SSL certificate created in 1.485 seconds. SSL key file: /opt/dsi/runtime/wlp/usr/servers/dsi-runtime-oracle/resources/security/key.jks
[AUDIT   ] TCPC0001I: TCP Channel XIOInboundTCP-8003915f7281eaba0000ffffac110002 is listening on host *  (IPv6) port 2809.
[WARNING ] CWOBJ0207W: Hostname, 68f784040001, does not appear to be fully qualified. Multi-host connectivity may not function correctly.
[AUDIT   ] CWMBD0000I: IBM Decision Server Insights version 8.9.0.201710162214
[AUDIT   ] CWWKF0012I: The server installed the following features: [ia:iaRuntime-8.9.0, servlet-3.1, ssl-1.0, ia:iaDevelopment-8.9.0, jndi-1.0, eXtremeScale.client-1.1, jdbc-4.0, ia:iaAnalytics-8.9.0, jaxrs-1.1, blueprint-1.0, ia:iaGateway-8.9.0, ia:iaRulesEngine-1.40.3, jsp-2.2, ia:iaRulesEngineApi-1.4.0, ia:iaCommon-8.9.0, ia:iaHTTPGateway-8.9.0, restConnector-1.0, ia:iaConnectivityInboundHTTP-8.9.0, json-1.0, eXtremeScale.server-1.1, distributedMap-1.0, wab-1.0, websocket-1.1, ia:iaConnectivityOutboundHTTP-8.9.0, ia:iaDispatcher-8.9.0, ia:iaRulesEngine-1.30.2].
[AUDIT   ] CWWKF0011I: The server dsi-runtime-oracle is ready to run a smarter planet.
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://68f784040001:9080/ibm/ia/rest/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://68f784040001:9080/ibm/ia/gateway/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://68f784040001:9080/IBMJMXConnectorREST/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://68f784040001:9080/ibm/ia/debug/
[AUDIT   ] CWWKT0016I: Web application available (default_host): http://68f784040001:9080/ibm/insights/
[AUDIT   ] CWMBD9395I: System starting in preload mode
```

Load the persisted data with the usual DSI dataloadManager script and start the DSI Runtime.

Alternatively the following command can be used to do it:
```bash
        samples/dataload_manager.sh ~/softs/IBM/ODMInsights890 localhost autoload
```
