# Example gernerating embeddings
# Test the model for embeddings using Invoke-RestMethod
$body = @{
    model = "llama3.1"
    prompt = "Who invented PowerShell and why?"
    task = "embeddings" # Specify the task for embeddings
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request for embeddings
$response = Invoke-RestMethod -Uri "http://localhost:11434/api/embeddings" -Method Post -ContentType "application/json" -Body $body
$response.embeddings


# Create a an Azure SQLDB Database using azure cli

Connect-AzAccount -SubscriptionId 'fd0c5e48-eea6-4b37-a076-0e23e0df74cb'
$resourceGroupName = "building-an-llm-$(Get-Random)"
$location = "centralus"
$adminSqlLogin = "SqlAdmin"
$password = "S0methingS@Str0ng!"
$serverName = "server-$(Get-Random)"
$databaseName = "AdventureWorksLT"
$myipaddress = (Invoke-WebRequest ifconfig.me/ip).Content
$startIp = $myipaddress
$endIp = $myipaddress

$SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force)

# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $SqlCredential

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp 

# Create a blank database with an S0 performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"


Get-AzSqlServer -ResourceGroupName $resourceGroup.ResourceGroupName -ServerName $serverName

# Connect to the Azure SQLDB server using dbatools
Import-Module dbatools
$SqlInstance = Connect-DbaInstance -SqlInstance 'server-1186056776.database.windows.net' -SqlCredential $SqlCredential


#Now, let's take this and extend it to a database

#Query the database to see if it exists
Get-DbaDatabase -SqlInstance $SqlInstance -Database $databaseName

#
$query = @"
SELECT TOP 10 * FROM SalesLT.Product;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName



# Add a vector column, make sure the length matches the embeddings dimension 
# (e.g., 768 for OpenAI's nomic-embed-text
ollama show nomic-embed-text


$query = @"
ALTER TABLE [SalesLT].[Product]
ADD embeddings VECTOR(768), chunk NVARCHAR(2000);
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName 


# Read the ProductID, embedding and chunk from the database as a datatable
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
$dt = $ds.Tables[0] # Get the first table from the dataset
$dt | Format-Table -AutoSize


# Generate embeddings for each row in the datatable
foreach ($row in $dt.Rows) {
    $body = @{
        model = "nomic-embed-text"
        input = $row.chunk
    } | ConvertTo-Json -Depth 10 -Compress

    # Send the POST request for embeddings
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
    $row.embeddings = ($response.embeddings | ConvertTo-Json -Depth 10 -Compress) # Store as JSON string
}

# print the embeddings as a string  
$dt | Format-Table -AutoSize
 


$ds | Write-DbaDbTableData -SqlInstance $SqlInstance -Database $databaseName -Table "MyEmbeddings" -AutoCreateTable -Truncate -Confirm:$false


# Update the database with the embeddings
$query = @"
        UPDATE p
        SET p.embeddings = CONVERT(VECTOR(768), e.embeddings),
            p.chunk = e.chunk
        FROM [SalesLT].[Product] p
        INNER JOIN myembeddings e
        ON p.ProductID = e.ProductID;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName


# Query the database to see if the embeddings were updated
$query = @"
SELECT TOP 10 * FROM SalesLT.Product;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName


# Generate an embedding for the search text


$SearchText = 'I am looking for a red bike and I dont want to spend a lot'

$body = @{
    model = "nomic-embed-text"
    input = $SearchText
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request for embeddings
$response = Invoke-RestMethod -Uri "http://localhost:11434/api/embed" -Method Post -ContentType "application/json" -Body $body
$searchEmbedding = ($response.embeddings | ConvertTo-Json -Depth 10 -Compress) # Store as JSON string
# print the embedding as a string
$searchEmbedding | Format-Table -AutoSize

# Query the database to find the most similar embeddings
$query = @"
DECLARE @search_vector VECTOR(768) = '$searchEmbedding';

SELECT TOP(4)
    p.ProductID,
    p.Name,
    p.chunk,
    vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM [SalesLT].[Product] p
ORDER BY distance;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName



# Drop the vector and chunk columns
$query = @"
ALTER TABLE [SalesLT].[Product]
DROP COLUMN embeddings, chunk;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName


# Delete the resource group and all its resources
Remove-AzResourceGroup -Name $resourceGroupName -Force -Confirm:$false
# Disconnect from the Azure SQLDB server
Disconnect-DbaInstance -SqlInstance $SqlInstance
# Disconnect from Azure
Disconnect-AzAccount