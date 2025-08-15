#!/bin/bash
set -m # Enable job control

# Start the Empyrion server in the background
wine "./DedicatedServer/EmpyrionDedicated.exe" -batchmode -nographics -dedicated empyriondedicated-eah.yaml -logFile - &
SERVER_PID=$!
echo "Empyrion server started with PID $SERVER_PID"

sleep 15

# Check if EAH is enabled
if [ "$EAHEnabled" = "True" ]; then
    echo "EAH is enabled. Starting..."

    # Configure the EPM Mod
    EPM_MOD_DIR="./Content/Mods/EPM"
    EPM_CONFIG_FILE="$EPM_MOD_DIR/Config.txt"
    mkdir -p "$EPM_MOD_DIR"
    echo "Port:$EAHAPIPort" > "$EPM_CONFIG_FILE"
    echo "EPM Mod configured to use port $EAHAPIPort"

    # Start EAH in the background
    if [ -f "./DedicatedServer/EmpyrionAdminHelper/EmpyrionAdminHelper.exe" ]; then
        wine "./DedicatedServer/EmpyrionAdminHelper/EmpyrionAdminHelper.exe" &
        EAH_PID=$!
        echo "EAH started with PID $EAH_PID"
    else
        echo "EAH executable not found. Continuing without it."
    fi
else
    echo "EAH is disabled. Skipping."
fi

# Function to clean up background processes on exit
cleanup() {
    echo "Caught exit signal. Cleaning up..."
    if jobs -p | grep -q "^${SERVER_PID}$"; then
        kill $SERVER_PID
    fi
    if [ -n "$EAH_PID" ] && jobs -p | grep -q "^${EAH_PID}$"; then
        kill $EAH_PID
    fi
    wait
    echo "Cleanup complete."
}

# Trap exit signals to run cleanup
trap cleanup SIGINT SIGTERM

# Wait for the primary server process
wait $SERVER_PID
EXIT_CODE=$?

# If the server exits, kill EAH too.
if [ -n "$EAH_PID" ] && jobs -p | grep -q "^${EAH_PID}$"; then
    kill $EAH_PID
fi

# Wait for all background jobs to finish
wait
echo "All processes finished."
exit $EXIT_CODE
