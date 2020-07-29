#!/usr/bin/env bash
ml $1
export PATH="/opt/TurboVNC/bin:$PATH"
export WEBSOCKIFY_CMD="/usr/bin/websockify"

SERVER_HOME_DIR="/home/$USER/opt/jupyter"
mkdir -p "$SERVER_HOME_DIR"
cd "$SERVER_HOME_DIR"

# cleanup from last time
rm "${SERVER_HOME_DIR/url.txt}"

# Export useful connection variables
export host
export port

# Generate a connection yaml file with given parameters
create_yml () {
  echo "Generating connection YAML file..."
  (
    umask 077
    echo -e "host: $host\nport: $port\npassword: $password\ndisplay: $display\nwebsocket: $websocket\nspassword: $spassword" > "${SERVER_HOME_DIR}/connection.yml"

    # Also generate file with just the link
    umask 000
    echo "https://greatlakes.arc-ts.umich.edu/node/$host/$port" > "${SERVER_HOME_DIR}/url.txt"
  )
}

# Cleanliness is next to Godliness
clean_up () {
  echo "Cleaning up..."

  vncserver -list | awk '/^:/{system("kill -0 "$2" 2>/dev/null || vncserver -kill "$1)}'
  [[ -n ${display} ]] && vncserver -kill :${display}

  [[ ${SCRIPT_PID} ]] && pkill -P ${SCRIPT_PID} || :
  pkill -P $$
  exit ${1:-0}
}

# Source in all the helper functions
source_helpers () {
  # Generate random integer in range [$1..$2]
  random_number () {
    shuf -i ${1}-${2} -n 1
  }
  export -f random_number

  # Check if port $1 is in use
  port_used () {
    local port="${1#*:}"
    local host=$((expr "${1}" : '\(.*\):' || echo "localhost") | awk 'END{print $NF}')
    nc -w 2 "${host}" "${port}" < /dev/null &> /dev/null
  }
  export -f port_used

  # Find available port in range [$2..$3] for host $1
  # Default: [2000..65535]
  find_port () {
    local host="${1:-localhost}"
    local port=$(random_number "${2:-2000}" "${3:-65535}")
    while port_used "${host}:${port}"; do
      port=$(random_number "${2:-2000}" "${3:-65535}")
    done
    echo "${port}"
  }
  export -f find_port

  # Wait $2 seconds until port $1 is in use
  # Default: wait 30 seconds
  wait_until_port_used () {
    local port="${1}"
    local time="${2:-30}"
    for ((i=1; i<=time*2; i++)); do
      if port_used "${port}"; then
        return 0
      fi
      sleep 0.5
    done
    return 1
  }
  export -f wait_until_port_used

  # Generate random alphanumeric password with $1 (default: 8) characters
  create_passwd () {
      # tr -cd 'a-zA-Z0-9' < /dev/urandom 2> /dev/null | head -c${1:-8}
      echo "$USER"
  }
  export -f create_passwd
}
export -f source_helpers

source_helpers

# Set host of current machine
host=$(hostname -A | awk '{print $1}')

# Setup one-time use passwords and initialize the VNC password
function change_passwd () {
  echo "Setting VNC password..."
  password=$(create_passwd "8")
  spassword=${spassword:-$(create_passwd "8")}
  (
    umask 077
    echo -ne "${password}\n${spassword}" | vncpasswd -f > "${SERVER_HOME_DIR}/vnc.passwd"
  )
}
change_passwd

# Start up vnc server (if at first you don't succeed, try, try again)
echo "Starting VNC server..."
for i in $(seq 1 10); do
  # Clean up any old VNC sessions that weren't cleaned before
  vncserver -list | awk '/^:/{system("kill -0 "$2" 2>/dev/null || vncserver -kill "$1)}'

  # Attempt to start VNC server
  VNC_OUT=$(vncserver -log "vnc.log" -rfbauth "vnc.passwd" -nohttpd -noxstartup  2>&1)
  VNC_PID=$(pgrep -s 0 Xvnc) # the script above will daemonize the Xvnc process
  echo "${VNC_OUT}"

  # Sometimes Xvnc hangs if it fails to find working disaply, we
  # should kill it and try again
  kill -0 ${VNC_PID} 2>/dev/null && [[ "${VNC_OUT}" =~ "Fatal server error" ]] && kill -TERM ${VNC_PID}

  # Check that Xvnc process is running, if not assume it died and
  # wait some random period of time before restarting
  kill -0 ${VNC_PID} 2>/dev/null || sleep 0.$(random_number 1 9)s

  # If running, then all is well and break out of loop
  kill -0 ${VNC_PID} 2>/dev/null && break
done

# If we fail to start it after so many tries, then just give up
kill -0 ${VNC_PID} 2>/dev/null || clean_up 1

# Parse output for ports used
display=$(echo "${VNC_OUT}" | awk -F':' '/^Desktop/{print $NF}')
port=$((5900+display))

echo "Successfully started VNC server on ${host}:${port}..."

[[ -e "${SERVER_HOME_DIR}/before.sh" ]] && source "${SERVER_HOME_DIR}/before.sh"


echo "Script starting..."
DISPLAY=:${display} "${SERVER_HOME_DIR}/script.sh" &
SCRIPT_PID=$!

[[ -e "${SERVER_HOME_DIR}/after.sh" ]] && source "${JUPYTER_HOME_DIR}/after.sh"

# Launch websockify websocket server
echo "Starting websocket server..."
websocket=$(find_port)
${WEBSOCKIFY_CMD:-/opt/websockify/run} -D ${websocket} localhost:${port}

# Set up background process that scans the log file for successful
# connections by users, and change the password after every
# connection
echo "Scanning VNC log file for user authentications..."
while read -r line; do
  if [[ ${line} =~ "Full-control authentication enabled for" ]]; then
    change_passwd
    create_yml
  fi
done < <(tail -f --pid=${SCRIPT_PID} "vnc.log") &


# Create the connection yaml file
create_yml

# Wait for script process to finish
wait ${SCRIPT_PID} || clean_up 1

# Exit cleanly
clean_up



