# Configure the SQL Server connection
$adminSqlLogin = "sa"
$password = "S0methingS@Str0ng!"
$databaseName = "StackOverflow_Embeddings_Small"
$SqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, (ConvertTo-SecureString -String $password -AsPlainText -Force)


# Import dbatools module and connect to the SQL instance
$SqlInstance = Connect-DbaInstance -SqlInstance localhost -SqlCredential $SqlCredential -TrustServerCertificate
$SqlInstance


# Verify the database connection
Get-DbaDatabase -SqlInstance $SqlInstance -Database $databaseName


Get-DbaDbTable -SqlInstance $SqlInstance -Database $databaseName -Table "PostEmbeddings"

############################################################################################################
# Query the database to find the most similar embeddings using vector search
############################################################################################################

# Generate an embedding for the search text
$SearchText = 'Find me posts about sql server performance'
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
        pe.PostID,
        vector_distance('cosine', @search_vector, pe.Embedding) AS distance,
        p.Title,
        p.Body
    FROM [dbo].[PostEmbeddings] pe
    JOIN [dbo].[Posts] p ON pe.PostID = p.Id
    ORDER BY distance ASC;
"@
Invoke-DbaQuery -SqlInstance $SqlInstance -Query $query -Database $databaseName


