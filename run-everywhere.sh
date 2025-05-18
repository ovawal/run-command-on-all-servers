#!/bin/bash

# Script to run a command on all the servers. 
# View usage information with option -u

# A list of servers to run the command, one per line.
SERVER_LIST='/home/servers.txt'

# Options for the ssh command.
SSH_OPTIONS='-o ConnectTimeout=2'

usage() {
  # Display the usage and exit.
  echo "Usage:$(basename ${0}) [-nsv] [-f FILE] COMMAND" >&2
  echo 'Execute COMMAND as a single command on every server.' >&2
  echo "  -f FILE  Use FILE for the list of servers. Default ${SERVER_LIST}"
  echo '  -n       Dry run mode. Display the COMMAND that would have been executed and execute it.' >&2
  echo '  -s       Execute the COMMAND using sudo on the remote server.' >&2
  echo '  -v       Verbose mode. Displays the server name before executing COMMAND.' >&2
  echo '  -u       View usage information.' >&2
  exit 1
}

# Make sure the script does not use superuser privilages.
if [[ ${UID} -eq 0 ]];
then
 echo 'Do not execute this script as root. Use the -s option instead.' >&2
 usage
fi
# Parse the options
while getopts f:nsvu OPTION
do
  case ${OPTION} in
    f) SERVER_LIST="${OPTARG}" ;;
    n) DRY_RUN='true';;
    s) SUDO='sudo' ;;
    v) VERBOSE='true' ;;
    u) USEAGEINFO='true' ;;
    ?) usage ;;
  esac
done

# Remove the options while leaving the rmaining arguments.
shift "$(( OPTIND -1 ))"

# If the user doen't supply at least one argument, give them help.
if [[ "${#}" -lt 1 ]];
then
  usage
fi
# Anything that remains on the command line should be treated as a single command.
COMMAND="${@}"

# Make sure the SERVER_LIST file exixts.
if [[ ! -e "${SERVER_LIST}" ]]
then
  echo "Cannot open server list file ${SERVER_LIST}." >&2
  exit 1
fi

# Expect the best, prepare for the worst.
EXIT_STATUS='0'

# Loop throuth the SERVEER_LIST
for SERVER in $(cat ${SERVER_LIST})
do
  if [[ "${USEAGEINFO}" = 'true' ]];
  then
	  usage
  fi

  if [[ "${VERBOSE}" = 'true' ]];
  then
    echo "${SERVER}"
  fi

  SSH_COMMAND="ssh ${SSH_OPTIONS} ${SERVER} ${SUDO} ${COMMAND}"

  # If its a dry run, dont execute anything, just echo it.
  if [[ "${DRY_RUN}" = 'true' ]];
  then
    echo "DRY RUN: ${SSH_COMMAND}"
  else
    ${SSH_COMMAND}
    SSH_EXIT_STATUS="${?}"

    # Capture any non_zero exit status from the SSH_COMMAND and report to the user.
   if [[ "${SSH_EXIT_STATUS}" -ne 0 ]];
   then
    EXIT_STATUS="${SSH_EXIT_STATUS}"
    echo "Execution on ${SERVER} failed." >&2
    fi
  fi
done

exit ${EXIT_STATUS}
