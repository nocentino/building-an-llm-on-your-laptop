############################################################################################################
# Generating embeddings and working with SQL Server 2025 in Docker
# This script demonstrates how to generate embeddings, store them in a SQL Server 2025 container, and query them.
############################################################################################################

# Generate embeddings for a sample prompt using the embedding model
# Uses the "nomic-embed-text" model and a sample input text
$body = @{
    model = "nomic-embed-text"
    input = "Who invented PowerShell and why?"
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request for embeddings
$response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
$response


############################################################################################################
# Start SQL Server 2025 RC0 in a Docker container
# If you don't have a SQL Server container running, this will pull the image and start it
############################################################################################################
Write-Output "Pulling SQL Server Docker images..."
docker pull mcr.microsoft.com/mssql/server:2025-RC0-ubuntu-24.04
############################################################################################################

# Create a Docker network for the containers
docker network create llmnet --subnet 172.20.0.0/24

# Start NGINX container with SSL certs, proxying to local Ollama
docker run -d `
  --name model-web `
  --volume "$((Get-Location).Path)/config/nginx.conf:/etc/nginx/nginx.conf:ro" `
  --volume "$(Get-Location)/certs:/etc/nginx/certs:ro" `
  --hostname model-web `
  --network llmnet `
  --ip 172.20.0.10 `
  --publish 443:443 `
  --detach nginx:latest

curl -kv https://localhost:443 

docker run `
    --name 'sql_2025_llm' `
    --platform=linux/amd64 `
    --env 'ACCEPT_EULA=Y' `
    --env 'MSSQL_SA_PASSWORD=S0methingS@Str0ng!' `
    --volume "$(Get-Location)/certs/nginx.crt:/var/opt/mssql/security/ca-certificates/public.crt:ro" `
    --volume sqldata_2025_llm:/var/opt/mssql `
    --hostname sql_2025_llm `
    --add-host model-web:172.20.0.10 `
    --network llmnet `
    --publish 1433:1433 `
    --detach mcr.microsoft.com/mssql/server:2025-RC0-ubuntu-24.04


# Copy the AdventureWorks2025_FULL.bak file to the SQL Server container
docker cp AdventureWorks2025_FULL.bak sql_2025_llm:/var/opt/mssql/data/AdventureWorks2025_FULL.bak



