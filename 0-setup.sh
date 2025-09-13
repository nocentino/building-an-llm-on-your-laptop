
echo "Pulling SQL Server Docker images..."
docker pull mcr.microsoft.com/mssql/server:2025-RC0-ubuntu-24.04

echo "Starting SQL Server 2025 RC0 container on port 1433..."
docker run \
    --env 'ACCEPT_EULA=Y' \
    --env 'MSSQL_SA_PASSWORD=S0methingS@Str0ng!' \
    --name 'sql_2025_llm' \
    --volume sqldata_2025:/var/opt/mssql \
    --volume sqlbackups:/var/opt/mssql/backups \
    --publish 1433:1433 \
    --platform=linux/amd64 \
    --detach mcr.microsoft.com/mssql/server:2025-RC0-ubuntu-24.04

