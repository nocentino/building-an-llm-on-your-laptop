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


# Create a an Azure SQLDB Database using powershell
# Create a SQL Server and Database
$serverName = "your-server-name"
$databaseName = "your-database-name"
$resourceGroupName = "your-resource-group-name"
$location = "your-location" # e.g., "East US"
 

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

