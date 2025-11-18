#!/bin/bash


# Stop any existing ollama instances
pkill -f "ollama serve"


# Start ollama instances on different ports
OLLAMA_HOST=127.0.0.1:11434 ollama serve &
OLLAMA_HOST=127.0.0.1:11435 ollama serve &
OLLAMA_HOST=127.0.0.1:11436 ollama serve &
OLLAMA_HOST=127.0.0.1:11437 ollama serve &


# Wait for a few seconds to ensure all instances are up
sleep 10


# Pull model on all instances
OLLAMA_HOST=127.0.0.1:11434 ollama pull nomic-embed-text &
OLLAMA_HOST=127.0.0.1:11435 ollama pull nomic-embed-text &
OLLAMA_HOST=127.0.0.1:11436 ollama pull nomic-embed-text &
OLLAMA_HOST=127.0.0.1:11437 ollama pull nomic-embed-text &



# List pulled models on all instances
OLLAMA_HOST=127.0.0.1:11434 ollama list nomic-embed-text:latest
OLLAMA_HOST=127.0.0.1:11435 ollama list nomic-embed-text:latest
OLLAMA_HOST=127.0.0.1:11436 ollama list nomic-embed-text:latest
OLLAMA_HOST=127.0.0.1:11437 ollama list nomic-embed-text:latest


# Use curl to verify each instance is running and load the models on each instance by sending a test request
curl -k -X POST http://localhost:11434/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "test message for instance 11434"
  }'

curl -k -X POST http://localhost:11435/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "test message for instance 11435"
  }'

(curl -k -X POST http://localhost:11436/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "test message for instance 11436"
  }'
)
curl -k -X POST http://localhost:11437/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "test message for instance 11437"
  }'



# Examine the docker-compose.yml file to see our nginx load balancer and SQL Server 2025 setup
code docker-compose.yml


# Examine the nginx.conf file to see how the load balancing is configured
code ./config/nginx.conf


# Start nginx and SQL Server
docker-compose up --build -d


echo "Started 4 ollama instances, nginx load balancer, and SQL Server 2025"


# Use curl to verify the nginx load balancer is working by sending a test request to port 443
curl -k -X POST https://localhost:443/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "test message for instance 443"
  }'


# Use curl to verify the nginx single backend is working by sending a test request to port 444
curl -k -X POST https://localhost:444/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "test message for instance 444"
  }'



# Go download StackOverflow2013 database from https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/
# I'm using the medium version which is ~50GB


# Copy the MDF and LDF files to the SQL Server container
docker cp StackOverflow2013_1.mdf   sql-server:/var/opt/mssql/data/ &
docker cp StackOverflow2013_2.ndf   sql-server:/var/opt/mssql/data/ &
docker cp StackOverflow2013_3.ndf   sql-server:/var/opt/mssql/data/ &
docker cp StackOverflow2013_4.ndf   sql-server:/var/opt/mssql/data/ &
docker cp StackOverflow2013_log.ldf sql-server:/var/opt/mssql/data/ &


# Change ownership of the files to the mssql user
docker exec -it -u 0 sql-server chown mssql:mssql /var/opt/mssql/data/StackOverflow2013_1.mdf
docker exec -it -u 0 sql-server chown mssql:mssql /var/opt/mssql/data/StackOverflow2013_2.ndf
docker exec -it -u 0 sql-server chown mssql:mssql /var/opt/mssql/data/StackOverflow2013_3.ndf
docker exec -it -u 0 sql-server chown mssql:mssql /var/opt/mssql/data/StackOverflow2013_4.ndf
docker exec -it -u 0 sql-server chown mssql:mssql /var/opt/mssql/data/StackOverflow2013_log.ldf



# Use docker exec to launch sqlcmd inside the SQL Server container to attach the databases and trust the certificate
docker exec -it sql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'S0methingS@Str0ng!' -C -d master -Q \
  "CREATE DATABASE StackOverflow_Embeddings_Small ON \
  (FILENAME = N'/var/opt/mssql/data/StackOverflow2013_1.mdf'), \
  (FILENAME = N'/var/opt/mssql/data/StackOverflow2013_2.ndf'), \
  (FILENAME = N'/var/opt/mssql/data/StackOverflow2013_3.ndf'), \
  (FILENAME = N'/var/opt/mssql/data/StackOverflow2013_4.ndf') \
  LOG ON (FILENAME = N'/var/opt/mssql/data/StackOverflow2013_log.ldf') FOR ATTACH;"


# Head over to vector-demos.sql and run the SQL script to generate vector embeddings for all posts in the StackOverflow_Embeddings_Small database
code vector-demos.sql


# Stop ollama instances
pkill -f "ollama serve"


echo "Stopped ollama instances"


# remove all docker resources, add --volumes if you want to remove volumes too
# docker compose down 
