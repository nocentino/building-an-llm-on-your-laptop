############################################################################################################
# Cleanup: Stop Ollama instances
############################################################################################################

# Stop all running Ollama server processes
pkill -f "ollama serve"

echo "Stopped ollama instances"

############################################################################################################
# Notes:
# - To remove all Docker resources including volumes, use: docker compose down --volumes
# - Monitor the nginx logs to see load balancing in action
# - Check SQL Server logs for database attachment status
############################################################################################################

# Remove all Docker resources (commented out for safety)
# Add --volumes flag if you want to remove volumes too
# docker compose down
