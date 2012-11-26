local _myhosts
_myhosts=( ${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[0-9]*}%%\ *}%%,*} )
_ignore=("cvs");


for host in $_myhosts; do
  for command in $_ignore; do
    if [[ "$host" == "$command" ]] ; then
      continue 2
    fi
  done
  alias $host="ssh $host"
done
