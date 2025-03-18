if [ ! -f /tmp/app-initialized ]; then
    #wait for the SQL Server to come up    
    sleep 15s    
    #run the setup script to create the DB and the schema in the DB
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $MSSQL_SA_PASSWORD -C -d master -i umbraco-db-init.sql -v UMBRACO_DB_NAME="$MSSQL_UMBRACO_DB_NAME" UMBRACO_DB_USER_LOGIN="$MSSQL_UMBRACO_DB_USER" UMBRACO_DB_USER_PASSWORD="$MSSQL_UMBRACO_DB_PASSWORD" UMBRACO_DB_USER_NAME="$MSSQL_UMBRACO_DB_USER"
    # Note that the container has been initialized so future starts won't wipe changes to the data
    touch /tmp/app-initialized
fi