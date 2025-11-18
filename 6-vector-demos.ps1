

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


