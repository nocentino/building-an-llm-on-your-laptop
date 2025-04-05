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


############################################################################################################
# Connect to the Azure SQL Database using dbatools
# If you don't have a Azure SQL Database up and running run the code in 0-setup.ps1 first
############################################################################################################
$myipaddress = (Invoke-WebRequest ifconfig.me/ip).Content
$startIp = $myipaddress
$endIp = $myipaddress
$adminSqlLogin = "SqlAdmin"
$password = "S0methingS@Str0ng!"
$databaseName = "AdventureWorksLT"

$SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force)


# Create a server firewall rule to allow access from the current IP
$SqlDbServer = Get-AzSqlServer -ResourceGroupName "building-an-llm" | Where-Object { $_.ServerName -like "server-*" }


$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName "building-an-llm" `
    -ServerName $SqlDbServer.ServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp 


# Import dbatools module and connect to the SQL instance
$SqlInstance = Connect-DbaInstance -SqlInstance $($SqlDbServer.FullyQualifiedDomainName) -SqlCredential $SqlCredential
$SqlInstance


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
# First, query the database to retrieve product data
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



############################################################################################################
# Generate embeddings for each row in the datatable
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
# Write the updated data back to the database
############################################################################################################
$checkTable = Get-DbaDbTable -SqlInstance $SqlInstance -Database $databaseName -Table "MyEmbeddings" -ErrorAction SilentlyContinue
if ($checkTable) {
    Remove-DbaDbTable -SqlInstance $SqlInstance -Database $databaseName -Table "MyEmbeddings" -Force
}

# Write the updated data back to the database, using this method for better than row by row for performance
$ds | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $databaseName -Table "MyEmbeddings" -AutoCreateTable

# Check the data in the MyEmbeddings table
$query = @"
    SELECT TOP(10) * FROM [dbo].[MyEmbeddings];
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

############################################################################################################
# Update the Product table with the generated embeddings that we just created
############################################################################################################

$query = @"
    UPDATE p
    SET p.embeddings = CONVERT(VECTOR(768), e.embeddings), 
    p.chunk = e.chunk
    FROM [SalesLT].[Product] p
    JOIN [dbo].[MyEmbeddings] e ON p.ProductID = e.ProductID;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

############################################################################################################
# Check the data in the Product table to verify the embeddings were added
############################################################################################################

$query = @"
    SELECT TOP(10) * FROM [SalesLT].[Product];
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName

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
$searchEmbedding = ($response.embeddings | ConvertTo-Json -Depth 10 -Compress) # Store as JSON string
$searchEmbedding

# Query the database for similar embeddings
$query = @"
    DECLARE @search_vector VECTOR(768) = '$searchEmbedding';

    SELECT TOP(10)
        p.ProductID,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance,
        p.Name,
        p.chunk
    FROM [SalesLT].[Product] p
    ORDER BY distance ASC;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName


############################################################################################################
# Clean up resources
############################################################################################################
Remove-AzResourceGroup -Name $resourceGroupName -Force -Confirm:$false

# Disconnect from the Azure SQLDB server
Disconnect-DbaInstance