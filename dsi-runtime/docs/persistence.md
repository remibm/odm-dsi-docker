# Run a DSI Runtime using persistence

## Oracle and DB2 support 

The following instructions assume we can access a running Oracle or DB2 with DSI tables created, and that we have a DSI runtime Docker image in our local Docker registry.

Ensure you are in directory `dsi-runtime`.

Copy the Oracle or db2 JDBC driver into the directory
`$DSI_DOCKER_GIT/dsi-runtime/jdbc/` (or to any other location set in .env with variable `DSI_JDBC_DIR`)

In `$DSI_DOCKER_GIT/dsi-runtime/.env`, 
  * set `DSI_DB_TYPE` to `ORACLE` or `DB2`. This will enable persistence.
  * set `DSI_DB_HOSTNAME` to hostname or ip adress of your database server.
  * set `DSI_DB_PORT` to exposed port of your database server.
  * set `DSI_DB_NAME` to database name.
  * set `DSI_DB2_SCHEMA` to schema used (ignored in case or Oracle database).
  * set `DSI_DB_USER` and `DSI_DB_PASSWORD` to credentials granting access to DSI database.

The templates will typically form URL similar to : `jdbc:oracle:thin:@${dsi.db.hostname}:${dsi.db.port}/${dsi.db.name}`.

Optional advanced database setup is available in `.env`. They are documented in `.env` file and [DSI knowledge center: Configuring Decision Server Insights persistence in JDBC](https://www.ibm.com/support/knowledgecenter/en/SSQP76_8.9.2/com.ibm.odm.itoa.config/topics/tsk_register_loader_callback_prod.html).

Run the DSI single runtime container:

`docker-compose up -d`

The output (`docker-compose logs`) will end up showing: 
```
dsi-runtime_1  | [WARNING ] CWMBE2540W: The outbound queue monitor is currently unable to retrieve the list of active solutions. The grid state is "PRELOAD".
```

Load the persisted data with the usual DSI dataloadManager script and start the DSI Runtime.

`docker-compose exec dsi-runtime ./dsi-cmd dataLoadManager autoload --disableServerCertificateVerification=true --disableSSLHostnameVerification=true`

Once preload is completed, the output should show:

```
dsi-runtime_1  | [WARNING ] CWMBE2540W: The outbound queue monitor is currently unable to retrieve the list of active solutions. The grid state is "ONLINE".
```


