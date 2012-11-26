settab() { echo -ne "\e]1;$1\a" }
settabh() { settab `hostname | cut -d. -f1` }
settabh
export PROMPT_COMMAND="settabh;$PROMPT_COMMAND"
