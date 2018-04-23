<server description="DSI Runtime">

    <featureManager>
        <feature>jdbc-4.0</feature>
    </featureManager>

        <dataSource id="DB2" jndiName="jdbc/dsi">
            <connectionManager/>
            <jdbcDriver>
                <library>
                    <fileset dir="/jdbc/" includes="db2*.jar"/>
                </library>
            </jdbcDriver>
            <properties.db2.jcc
                serverName="${dsi.db.hostname}"
                portNumber="${dsi.db.port}"
                databaseName="${dsi.db.name}" 
                user="${dsi.db.user}" 
                password="${dsi.db.password}" 
                currentSchema="${dsi.db.schema}" 
                />
        </dataSource>

        <ia_persistence databaseType="DB2" datasourceName="jdbc/dsi"/>
</server>
