############################################################################################################
# This script sets up and runs the Ollama service
# curl -fsSL https://ollama.com/install.sh | sh
brew install ollama




############################################################################################################
# Start the Ollama service
############################################################################################################
ollama serve &



############################################################################################################
# Interacting with Ollama at the command line
############################################################################################################
# Run the llama3.1 model
ollama run llama3.1 


# Ask, What is PowerShell and who invented it?
ollama run llama3.1 "What is PowerShell and who invented it?"


# Go examine the output in the ollama server
# At this point in time the model is loaded into memory on the server
# Look for the following...Closely look at the GPU details to ensure things are properly configured for your hardware
# ggml_metal_init: found device: Apple M2

# Go examine the GPU, disk, and memory usage to see if the model is being used correctly
# The model should be using the GPU and not the CPU


# Check the status of the Ollama service, the ollama cli tool interacts with the rest API on the localhost
ollama ps


# List all available models on this instance of ollaam
ollama list


# Pull the llama3.1 model (if not already pulled)
ollama pull llama3.1 
ollama pull llama3
ollama pull nomic-embed-text
############################################################################################################



############################################################################################################
# Show details of the nomic-embed-text model
############################################################################################################
ollama show llama3.1 
ollama show llama3
ollama show nomic-embed-text


############################################################################################################
# architecture: 
#     The type of model architecture being used (e.g., llama, bert, etc.). 
#     This defines the structure of the neural network and how it processes data.
#
# parameters: 
#     The number of trainable parameters in the model (e.g., 8.0B means 8 billion parameters). 
#     Larger models typically have more capacity to learn and generate complex outputs but require more resources.
#
# context length: 
#     The maximum number of tokens (words, subwords, or characters) the model can process in a single input. 
#     For example, 131072 means the model can handle up to 131,072 tokens in one request.
#
# embedding length: 
#     The size of the vector representation for each token or input. 
#     For example, 4096 means each token is represented as a 4,096-dimensional vector.
#
# quantization: 
#     The method used to reduce the size of the model for faster inference and lower memory usage. 
#     For example, Q4_K_M refers to a specific quantization technique that reduces precision while maintaining accuracy.
############################################################################################################



############################################################################################################
# Test a private model with a JSON payload using curl
############################################################################################################
curl -k http://localhost:11434/api/generate \
     -H "Content-Type: application/json" \
     -d '{ 
           "model":  "llama3.1", 
           "prompt": "Who is Jeffery Snover" 
          }'

##   response: empty if the response was streamed, if not streamed, this will contain the full response
##   context: an encoding of the conversation used in this response, this can be sent in the next request to keep a conversational memory
##   total_duration: time spent generating the response
##   load_duration: time spent in nanoseconds loading the model
##   prompt_eval_count: number of tokens in the prompt
##   prompt_eval_duration: time spent in nanoseconds evaluating the prompt
##   eval_count: number of tokens in the response
##   eval_duration: time in nanoseconds spent generating the response
############################################################################################################
