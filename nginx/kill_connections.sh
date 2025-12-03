#!/bin/bash

# Script to kill all connections to vLLM backend servers
# Usage: ./kill_connections.sh [--force]

set -e

PORTS=(8000 8001 8002 8003)
FORCE=false

# Parse arguments
if [[ "$1" == "--force" ]]; then
    FORCE=true
fi

echo "Stopping nginx to prevent new connections..."
systemctl stop nginx 2>/dev/null || true

echo "Finding vLLM processes..."
VLLM_PIDS=$(ps aux | grep -E "vllm|VLLM" | grep -v grep | awk '{print $2}' | sort -u)

if [ -z "$VLLM_PIDS" ]; then
    echo "No vLLM processes found."
else
    echo "Found vLLM processes: $VLLM_PIDS"
    
    if [ "$FORCE" = true ]; then
        echo "Force killing vLLM processes..."
        echo $VLLM_PIDS | xargs -r kill -9
    else
        echo "Sending SIGTERM to vLLM processes for graceful shutdown..."
        echo $VLLM_PIDS | xargs -r kill -TERM
        
        echo "Waiting 5 seconds for graceful shutdown..."
        sleep 5
        
        # Check if processes are still running
        REMAINING=$(ps aux | grep -E "vllm|VLLM" | grep -v grep | awk '{print $2}' | wc -l)
        if [ "$REMAINING" -gt 0 ]; then
            echo "Some processes still running, force killing..."
            ps aux | grep -E "vllm|VLLM" | grep -v grep | awk '{print $2}' | xargs -r kill -9
        fi
    fi
fi

echo "Checking connections to backend ports..."
for port in "${PORTS[@]}"; do
    CONNECTIONS=$(ss -tn 2>/dev/null | grep ":$port" | grep -E "ESTAB|CLOSE-WAIT" | wc -l)
    if [ "$CONNECTIONS" -gt 0 ]; then
        echo "  Port $port: $CONNECTIONS connections found"
        
        if [ "$FORCE" = true ]; then
            # Force close connections using iptables or tcpkill if available
            echo "  Attempting to close connections on port $port..."
            # Close connections by killing the processes that have them open
            lsof -ti :$port 2>/dev/null | xargs -r kill -9 2>/dev/null || true
        fi
    else
        echo "  Port $port: No active connections"
    fi
done

# Final check
echo ""
echo "Final status:"
REMAINING_CONNECTIONS=$(ss -tn 2>/dev/null | grep -E ":8000|:8001|:8002|:8003" | grep -E "ESTAB|CLOSE-WAIT" | wc -l)
REMAINING_PROCESSES=$(ps aux | grep -E "vllm|VLLM" | grep -v grep | wc -l)

if [ "$REMAINING_CONNECTIONS" -eq 0 ] && [ "$REMAINING_PROCESSES" -eq 0 ]; then
    echo "✓ All connections closed and processes terminated"
else
    echo "⚠ Remaining connections: $REMAINING_CONNECTIONS"
    echo "⚠ Remaining processes: $REMAINING_PROCESSES"
    echo "  Run with --force flag if you need to force kill remaining connections"
fi

echo "Done!"

