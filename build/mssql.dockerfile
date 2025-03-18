FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

WORKDIR /

COPY ../config/mssql/entrypoint.sh .
COPY ../config/mssql/db-init.sh .
COPY ../config/mssql/umbraco-db-init.sql .

RUN chmod +x /entrypoint.sh
RUN chmod +x /db-init.sh