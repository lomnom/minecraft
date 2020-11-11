#!/bin/bash
function backup {

  echo Backing up $2...

  cp -r "$1" /home/minecraft/backups/"$3"

  #actualsize=$(wc -c <"$1")
  echo $actualsize
  if [ $? -ne "0" ] ;
  then
    echo ERROR! Backup of overworld FAILED
  fi

}
now="$(date)"
server_dir=/home/minecraft/
backup $server_dir'The Official 6.1 Java Edition Server' overworld $now
backup $server_dir'The Official 6.1 Java Edition Server_nether' nether $now
backup $server_dir'The Official 6.1 Java Edition Server_the_end' end $now
