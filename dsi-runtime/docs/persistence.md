# Run a DSI Runtime using persistence

## Oracle support 

The following instructions assume we can access a running Oracle with a `DSI` database, and that we have a DSI runtime Docker image in our local Docker registry.

Copy the Oracle JDBC driver into the directory
`$DSI_DOCKER_GIT/dsi-runtime/.jdbc/`.

In `$DSI_DOCKER_GIT/dsi-runtime/.env`, 
  * set `DSI_DATABASE` to `ORACLE`
  * set `DSI_DB_HOSTNAME` to Oracle hostname or ip adress
  * set `DSI_DB_USER` and `DSI_DB_PASSWORD` to Oracle credentials granting access to access `DSI` database

Run the DSI Runtime container:

`docker-compose up -d`

The output (`docker-compose logs`) will end up showing: 
```
dsi-runtime_1  | [WARNING ] CWMBE2540W: The outbound queue monitor is currently unable to retrieve the list of active solutions. The grid state is "PRELOAD".
```

Load the persisted data with the usual DSI dataloadManager script and start the DSI Runtime.

`docker exec `docker-compose ps -q` ./dsi-cmd dataLoadManager autoload --disableServerCertificateVerification=true --disableSSLHostnameVerification=true`

Once preload is completed, the output should show:

```
dsi-runtime_1  | [WARNING ] CWMBE2540W: The outbound queue monitor is currently unable to retrieve the list of active solutions. The grid state is "ONLINE".
```

