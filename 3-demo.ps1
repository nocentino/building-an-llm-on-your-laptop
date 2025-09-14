############################################################################################################
# Script: Generating embeddings and working with SQL Server 2025 in Docker
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



    ### go to 3-demo.sql










    

# Configure the SQL Server connection
$adminSqlLogin = "sa"
$password = "S0methingS@Str0ng!"
$databaseName = "AdventureWorks2025"
$SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, (ConvertTo-SecureString -String $password -AsPlainText -Force)


# Import dbatools module and connect to the SQL instance
$SqlInstance = Connect-DbaInstance -SqlInstance localhost -SqlCredential $SqlCredential -TrustServerCertificate
$SqlInstance


# Copy the AdventureWorks2025_FULL.bak file to the SQL Server container
docker cp AdventureWorks2025_FULL.bak sql_2025_llm:/var/opt/mssql/data/AdventureWorks2025_FULL.bak


# Restore the AdventureWorksLT database from the backup file
Restore-DbaDatabase -SqlInstance $SqlInstance -Path "/var/opt/mssql/data/AdventureWorks2025_FULL.bak" -DatabaseName $databaseName -WithReplace -Verbose


# Verify the database connection
Get-DbaDatabase -SqlInstance $SqlInstance -Database $databaseName

############################################################################################################
# Create a new table for storing product embeddings
############################################################################################################

$query = @"
    CREATE TABLE [SalesLT].[ProductEmbeddings] (
        ProductID INT PRIMARY KEY,
        embeddings VECTOR(768),
        chunk NVARCHAR(2000)
    );
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

############################################################################################################
# Generate embeddings for each product and update the database
# Query the database to retrieve product data for embedding generation
############################################################################################################

# Query the database to retrieve product data
$query = @"
    SELECT p.ProductID, embeddings, p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') AS Chunk
    FROM [SalesLT].[ProductCategory] c,
        [SalesLT].[ProductModel] m,
        [SalesLT].[Product] p
    LEFT OUTER JOIN [SalesLT].[ProductEmbeddings] pe ON p.ProductID = pe.ProductID
    LEFT OUTER JOIN [SalesLT].[vProductAndDescription] d
    ON p.ProductID = d.ProductID AND d.Culture = 'en'
    WHERE p.ProductCategoryID = c.ProductCategoryID AND p.ProductModelID = m.ProductModelID
"@
$ds = Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName -As DataSet

# Read the datatable
$dt = $ds.Tables[0]
$dt | Format-Table -AutoSize

############################################################################################################
# Generate embeddings for each row in the datatable and update the embeddings column
############################################################################################################
foreach ($row in $dt.Rows) {
    $body = @{
        model = "nomic-embed-text"
        input = $row.chunk
    } | ConvertTo-Json -Depth 10 -Compress

    # Send the POST request for embeddings
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
    $row.embeddings = ($response.embeddings | ConvertTo-Json -Depth 10 -Compress) # Store as JSON string
}

$dt | Format-Table -AutoSize
############################################################################################################

############################################################################################################
# Write the embeddings data to the ProductEmbeddings table
############################################################################################################

# Write the data to the ProductEmbeddings table
$dt | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $databaseName -Table "ProductEmbeddings" -Schema "SalesLT"

# Check the data in the ProductEmbeddings table
$query = @"
    SELECT TOP(10) * FROM [SalesLT].[ProductEmbeddings];
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

############################################################################################################
# Query the database to find the most similar embeddings using vector search
############################################################################################################

# Generate an embedding for the search text
$SearchText = 'I am looking for a long-sleeve microfiber shirt size XL'
$body = @{
    model = "nomic-embed-text"
    input = $SearchText
} | ConvertTo-Json -Depth 10 -Compress

$response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
$searchEmbedding = ($response.embeddings | ConvertTo-Json -Depth 10 -Compress) # Store as JSON string
$searchEmbedding

# Query the database for similar embeddings
$query = @"
    DECLARE @search_vector VECTOR(768) = '$searchEmbedding';

    SELECT TOP(10)
        pe.ProductID,
        vector_distance('cosine', @search_vector, pe.embeddings) AS distance,
        p.Name,
        pe.chunk
    FROM [dbo].[ProductEmbeddings] pe
    JOIN [SalesLT].[Product] p ON pe.ProductID = p.ProductID
    ORDER BY distance ASC;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName




# Clean up resources by removing the SQL Server container
############################################################################################################
docker rm sql_2025_llm model-web -f
docker network rm llmnet
docker volume rm sqldata_2025_llm
############################################################################################################