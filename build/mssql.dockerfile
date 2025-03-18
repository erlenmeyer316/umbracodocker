ARG MSSQL_VER

FROM mcr.microsoft.com/mssql/server:$MSSQL_VER

USER root

WORKDIR /

COPY ../../local/config/mssql/entrypoint.sh .
COPY ../../local/config/mssql/db-init.sh .
COPY ../../local/config/mssql/umbraco-db-init.sql .

RUN chmod +x /entrypoint.sh
RUN chmod +x /db-init.sh