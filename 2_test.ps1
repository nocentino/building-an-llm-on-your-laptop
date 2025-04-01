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



##TODO: Write PowerShell to handle the streaming


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



# How do I manage the context and hand it back and forth
$body = @{
    model = "llama3.1"
    prompt = "Who is Jeffery Snover?"
    stream = $false # Disable streaming for this request
} | ConvertTo-Json -Depth 10 -Compress

# Send the POST request for embeddings
$response_snover_who = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body
$response_snover_who


# Maintaining context in a chat, using context
# TODO: This is deprecated, update this to a newer experience

# We can use the returned context to keep the conversation going
$response_initial_streaming.context

$body = @{
    model = "llama3.1"
    prompt = "Who is Jeffery Snover?"
    stream = $false # Disable streaming for this request
    context = $response_intial_streaming.context
} | ConvertTo-Json -Depth 10 -Compress

$response_that_snover = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -ContentType "application/json" -Body $body
$response_that_snover

