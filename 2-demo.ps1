############################################################################################################
# Test the model with a JSON payload using Invoke-RestMethod against the generate endpoint
$body = @{
    model = "llama3.1"
    prompt = "Who invented PowerShell and why?"
} | ConvertTo-Json -Depth 10 -Compress


# Send the POST request, so RESTful...with tee-object we can see the response and save it to a variable
Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body | Tee-Object -Variable response_initial



# Output the response, notice how the return is broken into chunks and returned...this is called streaming
$response_initial


# Use Get-Member to examine the response, notice how its just one giant string
$response_initial | Get-Member
############################################################################################################


############################################################################################################
# Test the model with a JSON payload using HttpWebRequest
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
while ($null -ne ($line = $streamReader.ReadLine())) {
    # Append each chunk of the response to the string
    Write-Output $line
}

# Clean up
$streamReader.Close()
$responseStream.Close()
############################################################################################################





############################################################################################################
# If you want to process the steaming output, you can do so like this
$body = @{
    model = "llama3.1"
    prompt = "Who invented PowerShell and why?"
    stream = $false # disable streaming    
} | ConvertTo-Json -Depth 10 -Compress


# Send the POST request
$response_initial_streaming = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body 


#Now, let's look at the object's data
$response_initial_streaming 


#Use Get-Member to examine the response
$response_initial_streaming | Get-Member
############################################################################################################



############################################################################################################
# Initialize the conversation history
$conversationHistory = @(
    @{
        role    = "system"
        content = "You are a travel assistant who helps users plan trips."
    },
    @{
        role    = "user"
        content = "I want to plan a trip to Italy for 6 days in the summer. Can you help me?"
    }
)

# First call: Initialize the conversation history with the first two roles
$body_part1 = @{
    model = "llama3.1"
    messages = $conversationHistory
    stream = $false # Disable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Send the first POST request
$response_part1 = Invoke-RestMethod -Uri "http://localhost:11434/api/chat" -Method Post -ContentType "application/json" -Body $body_part1

# Output the response from the first call
Write-Output $response_part1
############################################################################################################


############################################################################################################
# Add the assistant's response to the conversation history
$conversationHistory +=   @(
    @{
        role = "assistant"
        content = $response_part1.message.content
    },
    @{
        role    = "user"
        content = "I’m planning to go in June, and I’d like to visit museums and try local food, 
                   and we love wine, so we must go to a salumaria in Rome."
    }
)

# Second call: Continue the conversation with the next two roles
$body_part2 = @{
    model = "llama3.1"
    messages = $conversationHistory
    stream = $false # Disable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Send the second POST request
$response_part2 = Invoke-RestMethod -Uri "http://localhost:11434/api/chat" -Method Post -ContentType "application/json" -Body $body_part2

# Output the response from the second call
Write-Output "Response from second call:"
Write-Output $response_part2
############################################################################################################


############################################################################################################
# Third call: Continue the conversation with the next two roles
$conversationHistory +=   @(
    @{
        role = "assistant"
        content = $response_part2.message.content
    },
    @{
        role    = "user"
        content = "Can you skip Florance and in Positano, and then output a day by day itinerary in a table form by date and city?"
    }
)
$body_part3 = @{
    model = "llama3.1"
    messages = $conversationHistory
    stream = $false # Disable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Send the third POST request
$response_part3 = Invoke-RestMethod -Uri "http://localhost:11434/api/chat" -Method Post -ContentType "application/json" -Body $body_part3

# Output the response from the third call
Write-Output $response_part3
############################################################################################################
