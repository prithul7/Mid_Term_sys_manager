#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as root (use sudo).${NC}"
  exit 1
fi

add_users() {
  file="$1"
  [ ! -f "$file" ] && echo -e "${RED}File not found!${NC}" && exit 1
  while read -r user; do
    if id "$user" &>/dev/null; then
      echo -e "${YELLOW}$user already exists.${NC}"
    else
      useradd -m "$user"
      echo -e "${GREEN}User $user created.${NC}"
    fi
  done < "$file"
}

setup_projects() {
  user="$1"; num="$2"
  id "$user" &>/dev/null || { echo -e "${RED}User not found!${NC}"; exit 1; }
  base="/home/$user/projects"
  mkdir -p "$base"
  for ((i=1; i<=num; i++)); do
    dir="$base/project$i"
    mkdir -p "$dir"
    echo "Project $i by $user on $(date)" > "$dir/README.txt"
    chmod 755 "$dir"; chmod 640 "$dir/README.txt"
    chown -R "$user":"$user" "$dir"
  done
  echo -e "${GREEN}$num projects created for $user.${NC}"
}

sys_report() {
  out="$1"
  {
    echo "System Report - $(date)"
    echo "====================="
    echo "Disk Usage:"; df -h
    echo; echo "Memory Info:"; free -h
    echo; echo "CPU Info:"; lscpu | head -n 5
    echo; echo "Top 5 Memory Processes:"; ps -eo pid,comm,%mem --sort=-%mem | head -6
    echo; echo "Top 5 CPU Processes:"; ps -eo pid,comm,%cpu --sort=-%cpu | head -6
  } > "$out"
  echo -e "${GREEN}Report saved to $out${NC}"
}

process_manage() {
  user="$1"; action="$2"
  case "$action" in
    list_zombies) echo -e "${BLUE}Zombie Processes:${NC}"; ps -u "$user" -o pid,stat,cmd | grep 'Z' ;;
    list_stopped) echo -e "${BLUE}Stopped Processes:${NC}"; ps -u "$user" -o pid,stat,cmd | grep 'T' ;;
    kill_zombies) echo -e "${YELLOW}Cannot kill zombies directly.${NC}" ;;
    kill_stopped) ps -u "$user" -o pid,stat | grep 'T' | awk '{print $1}' | xargs -r kill; echo -e "${GREEN}Stopped processes killed.${NC}" ;;
    *) echo -e "${RED}Invalid action.${NC}" ;;
  esac
}

perm_owner() {
  user="$1"; path="$2"; perm="$3"; owner="$4"; group="$5"
  [ ! -e "$path" ] && echo -e "${RED}Invalid path!${NC}" && exit 1
  chmod -R "$perm" "$path"
  chown -R "$owner":"$group" "$path"
  echo -e "${GREEN}Permissions updated for $path${NC}"
}

help_menu() {
  echo -e "${YELLOW}Usage:${NC}"
  echo "./sys_manager.sh add_users <file>"
  echo "./sys_manager.sh setup_projects <username> <num>"
  echo "./sys_manager.sh sys_report <output_file>"
  echo "./sys_manager.sh process_manage <username> <action>"
  echo "./sys_manager.sh perm_owner <username> <path> <perm> <owner> <group>"
  echo "./sys_manager.sh help"
}

case "$1" in
  add_users) add_users "$2" ;;
  setup_projects) setup_projects "$2" "$3" ;;
  sys_report) sys_report "$2" ;;
  process_manage) process_manage "$2" "$3" ;;
  perm_owner) perm_owner "$2" "$3" "$4" "$5" "$6" ;;
  help|*) help_menu ;;
esac


	

