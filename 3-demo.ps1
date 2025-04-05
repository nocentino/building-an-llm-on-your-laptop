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
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroup.ResourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

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







# Connect to the Azure SQLDB server using dbatools
Import-Module dbatools
$server = Connect-DbaInstance -SqlInstance $serverName -SqlCredential $credential


#Now, let's take this and extend it to a database




# Create a table




# Let's insert a couple rows of data into our database using descriptions exported from WideWorldImporters as a CSV




# Read out the rows we just created into a datatable object




# Add a vector column, make sure the length matches the embeddings dimension




# Generate embeddings for each of our rows




# Update those rows in our database with our generated embeddings



# Generate an embedding for a prompt to use as our search



# Search the database using VECTOR_DISTANCE and our prompt's embedding 






# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
