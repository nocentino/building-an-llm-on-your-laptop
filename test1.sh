#!/bin/bash
# This script sets up and runs the Ollama service
#curl -fsSL https://ollama.com/install.sh | sh
brew install ollama


# Start up ollama, examine the logs to see if the GPU is being used, by default ollama is listening on http://127.0.0.1:11434
ollama serve & 


# Check the status of the Ollama service, the ollama cli tool interacts with the rest API on the localhost
ollama ps


# List all available models on this instance of ollaam
ollama list


# Pull the llama3.1 model (if not already pulled)
ollama pull llama3.1 
ollama pull llama3
ollama pull nomic-embed-text


# Show details of the nomic-embed-text model
ollama show nomic-embed-text


# Show details of the llama3.1 model, define
#   Model
#    architecture        llama     
#    parameters          8.0B      
#    context length      131072    
#    embedding length    4096      
#    quantization        Q4_K_M  
ollama show llama3.1 


# Test a private model with a JSON payload using curl
curl -k http://localhost:11434/api/generate \
     -H "Content-Type: application/json" \
     -d '{ 
           "model":  "llama3.1", 
           "prompt": "Who is Anthony Nocentino" 
          }'

############################################################################################################
##   response: empty if the response was streamed, if not streamed, this will contain the full response
##   context: an encoding of the conversation used in this response, this can be sent in the next request to keep a conversational memory
##   total_duration: time spent generating the response
##   load_duration: time spent in nanoseconds loading the model
##   prompt_eval_count: number of tokens in the prompt
##   prompt_eval_duration: time spent in nanoseconds evaluating the prompt
##   eval_count: number of tokens in the response
##   eval_duration: time in nanoseconds spent generating the response
############################################################################################################
