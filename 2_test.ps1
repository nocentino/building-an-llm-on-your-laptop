# First up, let's interact with our model using a chat-like experince, we'll build a "Body" of parameters needed to interact with our model. These are defined by the model used. 

# Test the model with a JSON payload using Invoke-RestMethod
$body = @{
    model = "llama3.1"
    prompt = "Who invented PowerShell and why?"
} | ConvertTo-Json -Depth 10 -Compress


# Send the POST request, so RESTful...
$response_initial = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body


# Go examine the output in the ollama server
# At this point in time the model is loaded into memory on the server
# Look for the following...Closely look at the GPU details to ensure things are properly configured for your hardware
# ggml_metal_init: found device: Apple M2


# Go examine the GPU, disk, and memory usage to see if the model is being used correctly


# Output the response, notice how the return is broken into chunks and returned...this is called streaming
$response_initial


# If you want to process the steaming output, you can do so like this
$body = @{
    model = "llama3.1"
    prompt = "Who invented PowerShell and why?"
    stream = $true # Enable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Create the HTTP request
$httpRequest = [System.Net.HttpWebRequest]::Create("http://localhost:11434/api/generate")
$httpRequest.Method = "POST"
$httpRequest.ContentType = "application/json"
$httpRequest.Headers.Add("Accept", "application/json")

# Write the body to the request stream
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
$httpRequest.ContentLength = $bodyBytes.Length
$requestStream = $httpRequest.GetRequestStream()
$requestStream.Write($bodyBytes, 0, $bodyBytes.Length)
$requestStream.Close()

# Get the response and handle streaming
$responseStream = $httpRequest.GetResponse().GetResponseStream()
$streamReader = New-Object System.IO.StreamReader($responseStream)

# Read the response line by line (streaming)
$responseString = "" # Initialize an empty string to store the response
while ($null -ne ($line = $streamReader.ReadLine())) {
    # Append each chunk of the response to the string
    $responseString += $line
}

# Output the complete response after the loop
Write-Output $responseString



# Clean up
$streamReader.Close()
$responseStream.Close()


# try another example but disable streaming
$body = @{
    model = "llama3.1"
    prompt = "Who invented PowerShell and why?"
    stream = $false # Disable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request
$response_initial_streaming = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body -Verbose


#Use Get-Member to examine the response
$response_initial_streaming | Get-Member


#Now, let's look at the object's data
$response_initial_streaming 



# Initialize the conversation history
$conversationHistory = @(
    @{
        role = "system"
        content = "You are a helpful assistant."
    },
    @{
        role = "user"
        content = "Who invented PowerShell and why?"
    },
    @{
        role = "assistant"
        content = $response_snover_who # Use the previous response here
    }
)

# Add the new user prompt to the conversation history
$conversationHistory += @{
    role = "user"
    content = "Who is Jeffrey Snover?"
}

# Convert the conversation history to JSON
$body = @{
    model = "llama3.1"
    messages = $conversationHistory
    stream = $false # Disable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request with the updated conversation history
$response_that_snover = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body
$response_that_snover