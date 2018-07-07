ssh_agent_env=~/.ssh/ssh_agent_env

# verify the environment variables point to a running ssh-agent
verify_ssh_agent_process() {
    test -e "$SSH_AUTH_SOCK" \
        && test "$SSH_AGENT_PID" \
        && ps -p $SSH_AGENT_PID -o pid=,comm= | grep -q ' ssh-agent$'
}

start_ssh_agent_if_needed() {
    verify_ssh_agent_process && return

    if test -f "$ssh_agent_env"; then
        . "$ssh_agent_env"
        verify_ssh_agent_process && return
    fi

    ssh-agent > "$ssh_agent_env"
    . "$ssh_agent_env"
}

start_ssh_agent_if_needed
ssh-add -L &>/dev/null || ssh-add
