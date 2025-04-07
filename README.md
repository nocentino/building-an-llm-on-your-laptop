# Building an LLM on Your Laptop

This project demonstrates how to set up and run a local environment for working with Large Language Models (LLMs). It includes scripts for setting up an Azure SQL Database, running the Ollama service, generating embeddings, and querying data. The project is designed for experimentation and learning, enabling you to explore LLMs without requiring cloud resources or powerful GPUs.

---

## Features

- **Azure SQL Database Setup**: Automates the creation of a database with sample data.
- **Ollama Service**: Runs a local LLM service for generating embeddings and interacting with models.
- **Embedding Generation**: Demonstrates how to generate embeddings for text data and store them in a database.
- **Database Queries**: Includes examples of querying and updating data in the Azure SQL Database.
- **Modular Scripts**: Step-by-step scripts for Windows and Unix-like systems.

---

## Prerequisites

- **PowerShell Core** (for `.ps1` scripts)
- **Bash** (for `.sh` scripts)
- **Azure Account** (for creating and managing Azure SQL Database)
- **Ollama** (a local service for running LLMs)
- **dbatools PowerShell Module** (for interacting with SQL Server instances)
- Basic familiarity with scripting and the command line

---

## Repository Structure

```
building-an-llm-on-your-laptop/
├── 0-setup.ps1         # PowerShell setup script to set up an Azure SQL Database
├── 1-demo.sh           # Bash demo script to explore ollama at the command line
├── 2-demo.ps1          # PowerShell LLM demo part 1 learn how to interact with the ollama API
├── 3-demo.ps1          # PowerShell LLM demo part 2 learn how to store embeddings in Azure SQL DB in a RAG pattern
```

---

## Setup Instructions

### Step 1: Set Up Azure SQL Database
Use the `0-setup.ps1` script to create an Azure SQL Database.

### Step 2: Install and Run Ollama
Use the `1-demo.sh` script to install Ollama and start the service.

### Step 3: Interact with the Chat Model
Use the `2-demo.ps1` script to interact with the chat model API.

### Step 4: Generate Embeddings and Query Data
Use the `3-demo.ps1` script to generate embeddings, store them in the Azure SQL Database, and query the data

# Remove the Azure Resource Group
To clean up resources, run the following command:
```
Remove-AzResourceGroup -Name "building-an-llm" -Force -Confirm:$false
```

## Notes

- This project is experimental and educational.
- It may use small-scale LLMs or simulated inference for demo purposes.
- No sensitive data should be used in the demos.

