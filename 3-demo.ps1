############################################################################################################
# Script: Generating embeddings and working with Azure SQL Database
# This script demonstrates how to generate embeddings, store them in an Azure SQL Database, and query them.
############################################################################################################

# Generate embeddings for a sample prompt using the embedding model
# Note the use of the embedding model "nomic-embed-text" and the input text
$body = @{
    model = "nomic-embed-text"
    input = "Who invented PowerShell and why?"
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request for embeddings
$response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
$response

# if you don't have a sqldb run the code in 0-setup.ps1 first

# Verify the server creation

############################################################################################################
# Connect to the Azure SQL Database using dbatools
############################################################################################################
$myipaddress = (Invoke-WebRequest ifconfig.me/ip).Content
$startIp = $myipaddress
$endIp = $myipaddress


# Create a server firewall rule to allow access from the current IP
$SqlDbServer = Get-AzSqlServer -ResourceGroupName "building-an-llm" -ServerName $serverName


$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName "building-an-llm" `
    -ServerName $SqlDbServer `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp 


# Import dbatools module and connect to the SQL instance
Import-Module dbatools
$SqlInstance = Connect-DbaInstance -SqlInstance $SqlDbServer.FullyQualifiedDomainName -SqlCredential $SqlCredential

# Verify the database connection
Get-DbaDatabase -SqlInstance $SqlInstance -Database $databaseName

############################################################################################################
# Add vector and chunk columns to the Product table
############################################################################################################

$query = @"
ALTER TABLE [SalesLT].[Product]
ADD embeddings VECTOR(768), chunk NVARCHAR(2000);
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

############################################################################################################
# Generate embeddings for each product and update the database
############################################################################################################

# Query the database to retrieve product data
$query = @"
SELECT p.ProductID, embeddings, p.Name + ' ' + ISNULL(p.Color, 'No Color') + ' ' + c.Name + ' ' + m.Name + ' ' + ISNULL(d.Description, '') AS Chunk
FROM [SalesLT].[ProductCategory] c,
     [SalesLT].[ProductModel] m,
     [SalesLT].[Product] p
LEFT OUTER JOIN [SalesLT].[vProductAndDescription] d
ON p.ProductID = d.ProductID AND d.Culture = 'en'
WHERE p.ProductCategoryID = c.ProductCategoryID AND p.ProductModelID = m.ProductModelID
"@
$ds = Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName -As DataSet

# Read the datatable
$dt = $ds.Tables[0]
$dt | Format-Table -AutoSize

# Generate embeddings for each row in the datatable
foreach ($row in $dt.Rows) {
    $body = @{
        model = "nomic-embed-text"
        input = $row.chunk
    } | ConvertTo-Json -Depth 10 -Compress

    # Send the POST request for embeddings
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
    $row.embeddings = ($response.embeddings -join ",") # Convert embeddings to a comma-separated string
}

# Write the updated data back to the database
$ds | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $databaseName -Table "MyEmbeddings" -AutoCreateTable -Truncate -Confirm:$false

############################################################################################################
# Query the database to find the most similar embeddings
############################################################################################################

# Generate an embedding for the search text
$SearchText = 'I am looking for a red bike and I dont want to spend a lot'
$body = @{
    model = "nomic-embed-text"
    input = $SearchText
} | ConvertTo-Json -Depth 10 -Compress

$response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
$searchEmbedding = ($response.embeddings -join ",") # Convert embeddings to a comma-separated string

# Query the database for similar embeddings
$query = @"
DECLARE @search_vector VECTOR(768) = CONVERT(VECTOR(768), '$searchEmbedding');

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

############################################################################################################
# Clean up resources
############################################################################################################

# Drop the vector and chunk columns
$query = @"
ALTER TABLE [SalesLT].[Product]
DROP COLUMN embeddings, chunk;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

# Delete the resource group and all its resources
Remove-AzResourceGroup -Name $resourceGroupName -Force -Confirm:$false

# Disconnect from the Azure SQLDB server and Azure
Disconnect-DbaInstance -SqlInstance $SqlInstance
Disconnect-AzAccount