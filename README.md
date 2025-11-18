# Building an LLM on Your Laptop

This repo demonstrates a local LLM workflow using:
- Ollama (multiple local instances)
- NGINX (TLS, load-balanced and single-backend endpoints)
- SQL Server 2025 (vector embeddings, similarity search, change tracking)

Ports:
- NGINX 443 = load balanced → Ollama 11434, 11435, 11436, 11437
- NGINX 444 = single backend → Ollama 11434
- SQL Server 1433

Self-signed TLS certs are used for NGINX (use curl -k or PowerShell -SkipCertificateCheck for testing).

------------------------------------------------------------
## Prerequisites
------------------------------------------------------------
- macOS + Docker Desktop
- Homebrew (for Ollama): brew install ollama
- PowerShell (pwsh) for the .ps1 demos
- dbatools PowerShell module (for SQL client demos): Install-Module dbatools -Scope CurrentUser
- Optional: StackOverflow sample DB files if you run full-scale demos

------------------------------------------------------------
## Overall Flow
------------------------------------------------------------

1) Install and start a single Ollama
- Script: 1-demo.sh
- Does:
  - Installs Ollama
  - Starts the Ollama service locally (ollama serve &)

2) Basic API from PowerShell
- Script: 2-demo.ps1
- Shows:
  - Using Invoke-RestMethod to call a chat/embedding endpoint for quick validation

3) Run four Ollama instances and bring up infra
- Script: 3-demo.sh
- Does:
  - Starts 4 Ollama instances on ports 11434–11437
  - Pulls the nomic-embed-text model on each instance in parallel
  - Spins up Docker services:
    - cert-generator (builds self-signed certs)
    - nginx-lb (terminates TLS, proxies to Ollama)
    - sql-server (SQL Server 2022/2025 container)
  - Verifies endpoints:
    - Load balanced: https://localhost:443/api/embed
    - Single backend: https://localhost:444/api/embed

4) SQL setup and embedding generation
- Script: 4-vector-demos.sql
- Does:
  - Creates a dedicated filegroup for embeddings
  - Creates dbo.PostEmbeddings (VECTOR(768))
  - (If configured) registers external model endpoints (LB and single)
  - Generates embeddings for posts in batches via AI_GENERATE_EMBEDDINGS

5) Client-side semantic search (PowerShell)
- Script: 5-vector-demos.ps1
- Does:
  - Creates a query embedding via Ollama (localhost:11434)
  - Queries SQL Server using VECTOR_DISTANCE('cosine', …)
  - Returns top posts by semantic similarity (Title/Body)

6) Change tracking to drive re-embeddings
- Script: 6-embedding-updates.sql
- Does:
  - Enables Change Tracking on the DB and dbo.Posts
  - Demonstrates an UPDATE that’s captured by Change Tracking
  - Intended flow: a downstream job reads CT rows and refreshes embeddings

7) Cleanup
- Script: 7-cleanup.sh
- Does:
  - Stops Ollama instances and allows you to tear down containers/volumes

------------------------------------------------------------
## Quick Start (macOS)
------------------------------------------------------------

- Install/start Ollama:
  ./1-demo.sh

- Start four Ollama instances and infra:
  ./3-demo.sh
  docker compose ps
  docker compose logs -f nginx-lb

- Test endpoints:
  curl -k -X POST https://localhost:443/api/embed -H "Content-Type: application/json" -d '{"model":"nomic-embed-text","input":"hello"}'
  curl -k -X POST https://localhost:444/api/embed -H "Content-Type: application/json" -d '{"model":"nomic-embed-text","input":"hello"}'

- Run SQL setup and embeddings (inside your SQL client or Azure Data Studio):
  4-vector-demos.sql

- Run semantic search in PowerShell:
  pwsh ./5-vector-demos.ps1

- Change tracking demo:
  6-embedding-updates.sql

- Cleanup:
  ./7-cleanup.sh
  docker compose down

------------------------------------------------------------
## Architecture (high level)
------------------------------------------------------------

- Clients → NGINX (TLS)
  - 443: round-robin to 11434–11437
  - 444: fixed route to 11434
- SQL Server stores embeddings (VECTOR(768)) and supports VECTOR_DISTANCE queries.


This is a demo and not production-ready. Adjust security, certs, error handling, and observability for real deployments.

