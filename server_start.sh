#! /bin/sh
### BEGIN INIT INFO
# Provides:          minecraft_server
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Minecraft Server control script.
# Description:       Minecraft Server control script.
#   Options
#     start <world>          - Start the Minecraft world server.  Starts all world servers by default.
#     stop <world>           - Stop the Minecraft world server.  Stops all world servers by default.
#     force-stop <world>     - Forcibly stop the Minecraft world server.  Forcibly stops all world servers by default.
#     restart <world>        - Restart the Minecraft world server.  Restarts all world servers by default.
#     force-restart <world>  - Forcibly restart the Minecraft world server.  Forcibly restarts all world servers by default.
#     status <world>         - Display the status of the Minecraft world server.  Displays the status of all world servers by default.
#     send <world> <command> - Send a command to a Minecraft world server.
#     screen <world>         - Display the Screen for the Minecraft world server.
#     watch <world>          - Watch the log file for the Minecraft world server.
#     backup <world>         - Backup the Minecraft world.  Backup all worlds by default.
#     c10t <world>           - Run the c10t mapping software on the Minecraft world.  Maps all worlds by default.
#     update <software>      - Update a software package.  Update the server software and all addons by default.
#                                Available software options
#                                  mcserver - Minecraft server software.
#                                  bukkit   - Craft Bukkit server software.
#                                  c10t     - c10t mapping software.
### END INIT INFO


USER_NAME=minecraft

# The location of server software and data.
LOCATION="/home/pi/mc/java/MC/minecraft"

## Required software.

JAVA=$(which java)
PERL=$(which perl)
SCREEN=$(which screen)
WGET=$(which wget)

## Minecraft software options.

# Generic server options.
INITIAL_MEMORY="500M"
MAXIMUM_MEMORY="1700M"

# Automatically restart the Minecraft server when a SEVERE error is caught.
#   0 - Do not auto restart.
#   1 - Auto restart.
AUTO_RESTART_ON_ERROR=1

# Server software to use.
#   mcserver - Minecraft server software.
#   bukkit   - Craft Bukkit server software.
#SERVER_TYPE="mcserver"
SERVER_TYPE="bukkit"

# Software packages, used for updating.
#   mcserver - Minecraft server software.
#   bukkit   - Craft Bukkit server software.
#   c10t     - c10t mapping software.

# Available software packages.
AVAILABLE_PACKAGES="mcserver bukkit c10t"

# Software packages updated with update command.
UPDATE_PACKAGES="$SERVER_TYPE c10t"

# User Commands that are available to your Minecraft players.
#   motd - Whispers the MOTD to the player, in case they missed it when they logged in.
#   help - Whispers the content of the help file.  A default help file will be generated on the first run.
USER_COMMANDS="motd help"

# Minecraft server options.
MCSERVER_URL="http://www.minecraft.net/download/minecraft_server.jar"
MCSERVER_LOCATION="$LOCATION"
MCSERVER_JAR="$MCSERVER_LOCATION/spigot-1.16.3.jar"
MCSERVER_ARGS="nogui"
MCSERVER_COMMAND="$JAVA -Xms$INITIAL_MEMORY -Xmx$MAXIMUM_MEMORY -jar $MCSERVER_JAR $MCSERVER_ARGS"

# Bukkit server options.
#BUKKIT_URL="http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-1.0.1-SNAPSHOT.jar"
#BUKKIT_URL="http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-1.0.1-R1.jar"
# DEV 
# BUKKIT_URL="http://ci.bukkit.org/job/dev-CraftBukkit/lastSuccessfulBuild/artifact/target/craftbukkit-1.1-R1-SNAPSHOT.jar"
#BUKKIT_URL="http://ci.bukkit.org/job/dev-CraftBukkit/1818/artifact/target/craftbukkit-1.1-R1.jar"
# BUKKIT_URL="http://ci.bukkit.org/job/dev-CraftBukkit/lastSuccessfulBuild/artifact/target/craftbukkit-1.1-R5-SNAPSHOT.jar"
BUKKIT_URL="http://cbukk.it/craftbukkit.jar"

BUKKIT_LOCATION="$LOCATION"
BUKKIT_JAR="$BUKKIT_LOCATION/craftbukkit.jar"
#BUKKIT_JAR="$BUKKIT_LOCATION/craftbukkit-dev.jar"
BUKKIT_ARGS="-nogui"
BUKKIT_COMMAND="$JAVA -Xms$INITIAL_MEMORY -Xmx$MAXIMUM_MEMORY -jar $BUKKIT_JAR $BUKKIT_ARGS"
echo $BUKKIT_COMMAND

# c10t mapping software options.
C10T_URL="http://toolchain.eu/minecraft/c10t/releases"
C10T_LOCATION="$LOCATION/c10t"
C10T_BIN="$C10T_LOCATION/c10t"

# Location to place map images, and the URL displayed to users for map access.
MAPS_URL=""
MAPS_LOCATION="$LOCATION/maps"


## Lib-notify configuration

# To use lib-notify to print a message on your desktop of important server events, change the following to a 1.
USE_LIBNOTIFY=0

# The username and display that notifications will be routed to.
LIBNOTIFY_USER_NAME=bortels
LIBNOTIFY_DISPLAY=":0.0"


## World configuration.

WORLDS_LOCATION="$LOCATION"

# List of worlds and the ports they are running on.  This file will
# be generated if missing.
# Note: World name should not contain a space, at least for now.
# ie:
#   alpha	25565
#   beta	25566
WORLDS_CONF="$LOCATION/worlds.conf"

# Default world name and port if worlds.conf is missing.
DEFAULT_WORLD="worlds"
DEFAULT_PORT="25565"


## Message of the day file, displayed to users on login.

MOTD="$LOCATION/motd.txt"

## Help file.

HELP="$LOCATION/help.txt"

## Backup configuration.

BACKUP_LOCATION="$LOCATION/backups"

# Length in days that backups survive.
BACKUP_FULL_DURATION=14


## Internal Methods.

execute() {
	# Execute the given command.
	# ARGS: command user
	if [ $(id -u) = 0 ]; then
		# Script is running as root, switch user and execute the command.
		su -c "$1" $2
	else
		# Script is running as a user, just execute the command.
		sh -c "$1"
	fi
}

getProcessIDs() {
	# Get the PIDs of the Screen and Java process for the world server.
	# ARGS: world
	local SCREEN_PID JAVA_PID
	SCREEN_PID=$(execute "$SCREEN -ls" $USER_NAME | $PERL -ne 'if ($_ =~ /^\t(\d+)\.minecraft-'$1'/) { print $1; }')
	JAVA_PID=$(ps -a -u $USER_NAME -o pid,ppid,comm | $PERL -ne 'if ($_ =~ /^\s*(\d+)\s+'$SCREEN_PID'\s+java/) { print $1; }')
	echo "$SCREEN_PID $JAVA_PID"
}

serverRunning() {
	# Check to see if the world server is running.
	# ARGS: world
	local PIDS
	PIDS=$(getProcessIDs $1)
	# Try to determine if the world is running.
	if [ -n "$(echo $PIDS | cut -d ' ' -f1)" ] && [ -n "$(echo $PIDS | cut -d ' ' -f2)" ]; then
		echo 1
	else
		echo 0
	fi
}

sendCommand() {
	# Send a command to the world server.
	# ARGS: world command
	local COMMAND
	COMMAND=$(printf "$2\r")
	execute "$SCREEN -S minecraft-$1 -p 0 -X stuff \"$COMMAND\"" $USER_NAME
	if [ ! $? = 0 ]; then
		printf "Error sending command to server $1.\n"
		exit 1
	fi
}

displayScreen() {
	# Connect to the Screen of a world server.
	# ARGS: world
	execute "$SCREEN -x minecraft-$1" $USER_NAME
	if [ ! $? = 0 ]; then
		printf "Error connecting to Screen.\n"
		exit 1
	fi
}

listContains() {
	# Check whether the item is in the list.
	# ARGS: item list
	local MATCH ITEM
	MATCH=0
	for ITEM in $2; do
		if [ "$ITEM" = "$1" ]; then
			MATCH=1
		fi
	done
	echo $MATCH
}

getPort() {
	# Grab the port for the given world.
	# ARGS: world
	local PORT
	PORT=$(execute "cat $WORLDS_CONF" $USER_NAME | $PERL -ne 'if ($_ =~ /^'$1'\s+(\d+)/) { print "$1"; }')
	echo $PORT
}

getWorlds() {
	# Grab the list of worlds.
	local WORLDS
	WORLDS=$(execute "cat $WORLDS_CONF" $USER_NAME | $PERL -ne 'if ($_ =~ /^(\w+)\s+\d+/) { print "$1 "; }')
	echo $WORLDS
}

libNotify() {
	# Send a message to the desktop using lib-notify, if it is available.
	# ARGS: summary body
	local NOTIFY
	NOTIFY=$(which notify-send)
	if [ -e $NOTIFY ]; then
		execute "DISPLAY=$LIBNOTIFY_DISPLAY $NOTIFY \"$1\" \"$2\"" $LIBNOTIFY_USER_NAME > /dev/null 2>&1
	fi
}

tellMOTD() {
	# Send the Message Of The Day (MOTD) to the user.
	# ARGS: world user
	local LINE
	if [ -e $MOTD ]; then
		while read LINE; do
			sendCommand $1 "tell $2 $LINE"
		done < $MOTD
	fi
}

tellHelp() {
	# Send help to the user.
	# ARGS: world user
	local LINE
	# If the help file does not exist, create a default one.
	if [ ! -e $HELP ]; then
		execute "printf \"§fAvailable commands: $USER_COMMANDS\n\" > $HELP" $USER_NAME
	fi
	while read LINE; do
		sendCommand $1 "tell $2 $LINE"
	done < $HELP
}

checkForLogin() {
	# Check for users logging into a world.
	# ARGS: world message
	local LOGIN PLAYER_NAME
	LOGIN=$(echo "$2" | $PERL -ne 'if ($_ =~ /(\w+) \[\/([0-9\.]+)\:(\d+)\] logged in with entity id (\d+)/) { print "$1\t$2\t$3\t$4"; }')
	if [ -n "$LOGIN" ]; then
		PLAYER_NAME=$(printf "$LOGIN" | cut -f1)
		# Add the user to the world.users file.
		execute "printf \"$LOGIN\n\" >> \"$WORLDS_LOCATION/$1.users\"" $USER_NAME
		# Announce the user logging in via lib-notify.
		if [ $USE_LIBNOTIFY ]; then
			libNotify "Minecraft - $1" "$PLAYER_NAME has logged into world."
		fi
		# Whisper the MOTD to the user logging in.
		tellMOTD $1 $PLAYER_NAME
	fi 
}

checkForLogout() {
	# Check for users logging out of a world.
	# ARGS: world message
	local LOGOUT PLAYER_NAME
	LOGOUT=$(echo "$2" | $PERL -ne 'if ($_ =~ /(\w+) lost connection\: (.+)/) { print "$1\t$2"; }')
	if [ -n "$LOGOUT" ]; then
		PLAYER_NAME=$(printf "$LOGOUT" | cut -f1)
		# Remove the user from the world.users file.
		execute "perl -i -ne 'print unless /^$PLAYER_NAME\t[0-9\.]+\t\d+\d+/;' $WORLDS_LOCATION/$1.users" $USER_NAME
		# Announce the user logging out via lib-notify.
		if [ $USE_LIBNOTIFY ]; then
			libNotify "Minecraft - $1" "$PLAYER_NAME has logged out of world."
		fi
	fi 
}

checkForCommand() {
	# Check for users attempting to execute a command.
	# ARGS: world message
	local COMMAND PLAYER_NAME
	COMMAND=$(echo "$2" | $PERL -ne 'if ($_ =~ /(\w+) tried command\: (.+)/) { print "$1\t$2"; }')
	if [ -n "$COMMAND" ]; then
		PLAYER_NAME=$(printf "$COMMAND" | cut -f1)
		COMMAND=$(printf "$COMMAND" | cut -f2)
                if [ $(listContains $COMMAND "$USER_COMMANDS") = 1 ]; then
			case "$COMMAND" in
				motd)
					tellMOTD $1 $PLAYER_NAME
				;;
				help)
					tellHelp $1 $PLAYER_NAME
				;;	
				*)
				;;
			esac
		fi
	fi
}

parseLog() {
	# Parse through the log file for the given world.
	# ARGS: world
	local LINE DATE TIME TYPE MESSAGE
	while read LINE; do
		LINE=$(echo "$LINE" | $PERL -ne 'if ($_ =~ /(.+) (.+) \[(\w+)\] (.+)/) { print "$1\t$2\t$3\t$4"; }')
		DATE=$(echo "$LINE" | cut -f1)
		TIME=$(echo "$LINE" | cut -f2)
		TYPE=$(echo "$LINE" | cut -f3)
		MESSAGE=$(echo "$LINE" | cut -f4)
		case "$TYPE" in
			INFO)
				checkForLogin $1 "$MESSAGE"
				checkForLogout $1 "$MESSAGE"
				checkForCommand $1 "$MESSAGE"
			;;
			SEVERE)
				if [ $AUTO_RESTART_ON_ERROR = 1 ]; then
					sendCommand $1 "say The server is experiencing issues, restarting in 5 seconds..."
					sleep 5
					forceStop $1
					sleep 5
					start $1
				fi
			;;
			WARNING)
			;;
			*)

			;;
		esac
	done
}

watchLog() {
	# Watch the world server log file.
	# ARGS: world
	local PID
	# Make sure that the server.log file exists.
	if [ -e "$WORLDS_LOCATION/$1/server.log" ]; then
		# Watch the log.
		PID=$(echo $(getProcessIDs $1) | cut -d ' ' -f2)
		tail -n0 -f --pid=$PID $WORLDS_LOCATION/$1/server.log
	fi
}

start() {
	# Start the world server.
	# ARGS: world
	local SERVER_PORT PID
	# Make sure that the server directory exists.
	execute "mkdir -p $WORLDS_LOCATION/$1" $USER_NAME
	cd $WORLDS_LOCATION/$1
	# Make sure that the server.properties file exists.
	if [ ! -e server.properties ]; then
		SERVER_PORT=$(getPort $1)
		execute "printf \"# Minecraft server properties\n\" > server.properties" $USER_NAME
		execute "printf \"level-name=$1\n\" >> server.properties" $USER_NAME
		execute "printf \"server-port=$SERVER_PORT\n\" >> server.properties" $USER_NAME
	fi
	# Make sure that the server.log file exists.
	execute "touch server.log" $USER_NAME
	# Erase the world's users file before starting up the world (should already be empty).
	execute "printf \"\" > \"$WORLDS_LOCATION/$1.users\"" $USER_NAME
	# Start the server.
	execute "$SCREEN -dmS minecraft-$1 $SERVER_COMMAND" $USER_NAME
	if [ ! $? = 0 ]; then
		printf "Error starting the server.\n"
		exit 1
	fi
	# Start the log processor.
	PID=$(echo $(getProcessIDs $1) | cut -d ' ' -f2)
	tail -n0 -f --pid=$PID $WORLDS_LOCATION/$1/server.log | parseLog $1 &
}

stop() {
	# Stop the world server.
	# ARGS: world
	sendCommand $1 "stop"
	# Erase the world's users file since we won't be able to catch anyone logging off.
	execute "printf \"\" > \"$WORLDS_LOCATION/$1.users\"" $USER_NAME
}

forceStop() {
	# Forcibly stop the world server.
	# ARGS: world
	local PIDS
	PIDS=$(getProcessIDs $1)
	# Try to stop the server cleanly first.
	stop $1
	sleep 5
	# Kill the process ids of the world server.
	kill -9 $PIDS > /dev/null 2>&1
}

fullBackup() {
	# Backup the world server.
	# ARGS: world
	local DATE NUM
	# Make sure that the backup location exists.
	execute "mkdir -p $BACKUP_LOCATION" $USER_NAME
	cd $WORLDS_LOCATION
	# Grab the date.
	DATE=$(date +%Y-%m-%d)
	# Make sure that we are using a unique filename for this backup.
	NUM=0
	while [ -e $BACKUP_LOCATION/fullBackup-$1-$DATE-$NUM.tar.gz ]; do
		NUM=$(($NUM + 1))
	done
	# Create the full backup file.
	execute "tar -chzf $BACKUP_LOCATION/fullBackup-$1-$DATE-$NUM.tar.gz $1" $USER_NAME
	# Cleanup old backups.
	execute "find $BACKUP_LOCATION -name fullBackup-$1-* -type f -mtime +$BACKUP_FULL_DURATION -delete" $USER_NAME
}

updateServerSoftware() {
	# Update server software.
	# Args: file location url
	execute "mkdir -p $2" $USER_NAME
	# Backup the old server jar.
	if [ -e $1 ]; then
		execute "mv -f $1 $1.old" $USER_NAME
	fi
	# Download the new server software.
	execute "$WGET -qO $1 $3" $USER_NAME
	# Check for error and restore backup if found.
	if [ ! $? = 0 ]; then
		printf "\nError updating server software.\n"
		if [ -e "$1.old" ]; then
			execute "mv -f $1.old $1" $USER_NAME
		fi
		exit 1
	fi
}

updateMappingSoftware() {
	# Update the c10t mapping software.
	local ARCH VERSION
	# Make sure the directory exists.
	execute "mkdir -p $C10T_LOCATION" $USER_NAME
	cd $C10T_LOCATION
	# Determine the architecture of the system.
	if [ $(getconf LONG_BIT) = 64 ]; then
		ARCH="x86_64"
	else
		ARCH="x86"
	fi
	# Determine the current version number of c10t.
	execute "$WGET -qO CURRENT $C10T_URL/CURRENT" $USER_NAME
	if [ ! $? = 0 ]; then
		printf "\nError determining the current version of c10t.\n"
		exit 1
	fi
	VERSION=$(execute "cat CURRENT")
	# Download the new version of c10t.
	execute "$WGET -qO c10t.tar.gz $C10T_URL/c10t-$VERSION-linux-$ARCH.tar.gz" $USER_NAME
	if [ ! $? = 0 ]; then
		printf "\nError updating c10t.\n"
		exit 1
	fi
	# Uncompress the archive.
	execute "tar xzf c10t.tar.gz --strip 1" $USER_NAME
}

update() {
	# Update software package.
	# ARGS: package
	case "$1" in
		mcserver)
			updateServerSoftware "$MCSERVER_JAR" "$MCSERVER_LOCATION" "$MCSERVER_URL"
		;;
		bukkit)
			updateServerSoftware "$BUKKIT_JAR" "$BUKKIT_LOCATION" "$BUKKIT_URL"
		;;
		c10t)
			updateMappingSoftware
		;;
		*)
			printf "Unknown software package: $1\n"
			exit 1
		;;
	esac
}

c10t() {
	# Run c10t mapping software on the server.
	# ARGS: world
	execute "mkdir -p $MAPS_LOCATION/$1" $USER_NAME
	# Make sure that the world files are actually there before mapping.
	if [ -e "$WORLDS_LOCATION/$1/server.properties" ]; then
		# Create various maps for the main world.
		execute "$C10T_BIN -s -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/surface.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -c -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/caves.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -c -H -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/caves_heightmap.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -a -i 21 -H -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/lapis_heightmap.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -a -i 56 -H -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/diamonds_heightmap.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -a -i 4 -H -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/cobble_heightmap.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -q -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/surface_oblique.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -q -c -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/caves_oblique.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -z -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/surface_isometric.png" $USER_NAME > /dev/null 2>&1
		execute "$C10T_BIN -s -z -c -w $WORLDS_LOCATION/$1/$1 -o $MAPS_LOCATION/$1/caves_isometric.png" $USER_NAME > /dev/null 2>&1
		# Create various maps for the nether world if it exists.
		if [ -d "$WORLDS_LOCATION/$1/$1/DIM-1" ]; then 
			execute "$C10T_BIN -s -N --hell-mode -w $WORLDS_LOCATION/$1/$1/DIM-1 -o $MAPS_LOCATION/$1/nether_surface.png" $USER_NAME > /dev/null 2>&1
			execute "$C10T_BIN -s -N --hell-mode -q -w $WORLDS_LOCATION/$1/$1/DIM-1 -o $MAPS_LOCATION/$1/nether_surface_oblique.png" $USER_NAME > /dev/null 2>&1
			execute "$C10T_BIN -s -N --hell-mode -z -w $WORLDS_LOCATION/$1/$1/DIM-1 -o $MAPS_LOCATION/$1/nether_surface_isometric.png" $USER_NAME > /dev/null 2>&1
		fi
	fi
}

## Begin.


# Make sure that Java, Perl, GNU Screen, and GNU Wget are installed.
if [ ! -e $JAVA ]; then
	printf "ERROR: Java not found!\n"
	printf "Try installing this with:\n"
	printf "sudo apt-get install openjdk-6-jre\n"
	exit 1
fi
if [ ! -e $PERL ]; then
	printf "ERROR: Perl not found!\n"
	printf "Try installing this with:\n"
	printf "sudo apt-get install perl\n"
	exit 1
fi
if [ ! -e $SCREEN ]; then
	printf "ERROR: GNU Screen not found!\n"
	printf "Try installing this with:\n"
	printf "sudo apt-get install screen\n"
	exit 1
fi
if [ ! -e $WGET ]; then
	printf "ERROR: GNU Wget not found!\n"
	printf "Try installing this with:\n"
	printf "sudo apt-get install wget\n"
	exit 1
fi

# Make sure that the minecraft user exists.
if [ ! -n "$(grep $USER_NAME /etc/passwd)" ]; then
	printf "ERROR: This script requires that a user account named $USER_NAME exist on this system.\n"
	printf "Either modify the USER_NAME variable in this script, or try adding this user:\n"
	printf "sudo adduser $USER_NAME\n"
	exit 1
fi

# Warn if the script is running with the wrong user.
if [ ! $(id -u) = 0 ] && [ ! $(whoami) = $USER_NAME ]; then
	printf "WARNING: This script appears to have been started by the wrong user.\n"
fi

# Make sure that the worlds.conf file exists.
if [ ! -e $WORLDS_CONF ]; then
	execute "printf \"# Minecraft world configuration file\n\" > $WORLDS_CONF" $USER_NAME
	execute "printf \"# <world>\t<port>\n\" >> $WORLDS_CONF" $USER_NAME
	execute "printf \"$DEFAULT_WORLD\t$DEFAULT_PORT\n\" >> $WORLDS_CONF" $USER_NAME
fi

# Initialize some variables determined by the server type.
case "$SERVER_TYPE" in
	mcserver)
		SERVER_COMMAND=$MCSERVER_COMMAND
		SERVER_FILE=$MCSERVER_JAR
		
	;;
	bukkit)
		SERVER_COMMAND=$BUKKIT_COMMAND
		SERVER_FILE=$BUKKIT_JAR
	;;
	*)
		printf "Unknown server type: $SERVER_TYPE\n"
		exit 1
	;;
esac


# Grab the list of worlds.
WORLDS=$(getWorlds)

# Respond to the command line arguments.
case "$1" in
	start)
		# Make sure that the server software exists.
		if [ ! -e $SERVER_FILE ]; then
			printf "Server software not found, downloading it...\n"
			update $SERVER_TYPE
		fi
		# Check for the optional world command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			WORLDS="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft world $2 not found!\n"
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
		# Start each world requested, if not already running.
		printf "Starting Minecraft Server:"
		for WORLD in $WORLDS; do
			if [ $(serverRunning $WORLD) = 0 ]; then
				printf " $WORLD"
				start $WORLD
			fi
		done
		printf "\n"
	;;
	stop|force-stop)
		# Check for the optional world command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			WORLDS="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft world $2 not found!\n"
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
		# Stop each world requested, if running.
		printf "Stopping Minecraft Server:"
		for WORLD in $WORLDS; do
			# Try to stop the world cleanly.
			if [ $(serverRunning $WORLD) = 1 ]; then
				printf " $WORLD"
				sendCommand $WORLD "say The server is about to go down."
				sendCommand $WORLD "save-all"
				sendCommand $WORLD "save-off"
				sendCommand $WORLD "say The server is going down in 5 seconds..."
				sleep 5
				if [ "$1" = "force-stop" ]; then
					forceStop $WORLD
				else
					stop $WORLD
				fi
				sleep 5
			fi
		done
		printf "\n"
	;;
	restart|reload|force-restart|force-reload)
		# Check for the optional world command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			WORLDS="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft world $2 not found!\n"
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
		# Restart each world requested, start those not already running.
		printf "Restarting Minecraft Server:"
		for WORLD in $WORLDS; do
			printf " $WORLD"
			if [ $(serverRunning $WORLD) = 1 ]; then
				sendCommand $WORLD "say The server is about to restart."
				sendCommand $WORLD "save-all"
				sendCommand $WORLD "save-off"
				sendCommand $WORLD "say Restarting in 5 seconds..."
				sleep 5
				if [ "$(echo \"$1\" | cut -d '-' -f1)" = "force" ]; then
					forceStop $WORLD
				else
					stop $WORLD
				fi
				sleep 5
			fi;
			start $WORLD
		done
		printf "\n"
	;;
	status|show)
		# Check for the optional world command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			WORLDS="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft world $2 not found!\n"
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
		# Show the status of each world requested.
		printf "Minecraft Server Status:\n"
		for WORLD in $WORLDS; do
			printf "  $WORLD: "
			if [ $(serverRunning $WORLD) = 1 ]; then
				printf "running (%d users online)\n" $(cat $WORLDS_LOCATION/$WORLD.users | wc -l)
			else
				printf "not running.\n"
			fi
		done
	;;
	send)
		# Check for the world command line argument.
		if [ -n "$2" ] && [ $(listContains $2 "$WORLDS") = 1 ] && [ -n "$3" ]; then
			WORLD=$2
			shift 2
			printf "Send command to world $WORLD: $*\n"
			sendCommand $WORLD "$*"
		else
			printf "Usage:  $0 $1 <world> <command>\n"
			printf "   ie:  $0 $1 world say Hello World!\n"
			exit 1
		fi
	;;
	screen)
		# Check for the world command line argument.
		if [ -n "$2" ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			displayScreen $2
		else
			if [ -n "$2" ]; then
				printf "Minecraft world $2 not found!\n"
			else
				printf "Minecraft world not provided!\n"
			fi
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
	;;
	watch)
		# Check for the world command line argument.
		if [ -n "$2" ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			watchLog $2
		else
			if [ -n "$2" ]; then
				printf "Minecraft world $2 not found!\n"
			else
				printf "Minecraft world not provided!\n"
			fi
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
	;;
	backup)
		# Check for the optional world command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			WORLDS="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft world $2 not found!\n"
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
		# Backup each world requested.
		printf "Backing up Minecraft Server:"
		for WORLD in $WORLDS; do
			printf " $WORLD"
			if [ $(serverRunning $WORLD) = 1 ]; then
				sendCommand $WORLD "say Backing up the world."
				sendCommand $WORLD "save-all"
				sendCommand $WORLD "save-off"
				sleep 2
				fullBackup $WORLD
				sendCommand $WORLD "save-on"
				sendCommand $WORLD "say Backup complete."
			else
				fullBackup $WORLD
			fi
		done
		printf "\n"
	;;
	update)
		printf "Updating the Minecraft Server software...\n"
		# Check for the optional package command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$AVAILABLE_PACKAGES") = 1 ]; then
			UPDATE_PACKAGES="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft software package $2 not found!\n"
			printf "  Usage:  $0 $1 <software package>\n"
			exit 1
		fi
		# If the server software is being updated, stop all the world servers, and backup the worlds.
		if [ -n "$(echo \"$UPDATE_PACKAGES\" | grep $SERVER_TYPE)" ]; then
			printf "Stopping Minecraft Server:"
			for WORLD in $WORLDS; do
				if [ $(serverRunning $WORLD) = 1 ]; then
					printf " $WORLD"
					sendCommand $WORLD "say The server software is being updated."
					sendCommand $WORLD "say Server restart is imminent."
					sendCommand $WORLD "save-all"
					sendCommand $WORLD "save-off"
					sendCommand $WORLD "say Restarting in 5 seconds."
					sleep 5
					stop $WORLD
				fi
			done
			printf "\n"
			printf "Backing up Minecraft Server:"
			for WORLD in $WORLDS; do
				printf " $WORLD"
				fullBackup $WORLD
			done
			printf "\n"
		fi
		# Update each software package requested.
		printf "Updating software package:"
		for PACKAGE in $UPDATE_PACKAGES; do
			printf " $PACKAGE"
			update $PACKAGE
		done
		printf "\n"
		if [ -n "$(echo \"$UPDATE_PACKAGES\" | grep $SERVER_TYPE)" ]; then
			printf "Starting Minecraft Server:"
			for WORLD in $WORLDS; do
				printf " $WORLD"
				start $WORLD
			done
			printf "\n"
		fi
	;;
	c10t|map)
		# Make sure that the c10t software exists.
		if [ ! -e $C10T_BIN ]; then
			printf "c10t software not found, downloading it...\n"
			update "c10t"
		fi
		# Check for the optional world command line argument.
		if [ -n "$2"  ] && [ $(listContains $2 "$WORLDS") = 1 ]; then
			WORLDS="$2"
		elif [ -n "$2" ]; then
			printf "Minecraft world $2 not found!\n"
			printf "  Usage:  $0 $1 <world>\n"
			exit 1
		fi
		# Run c10t on each world requested.
		printf "Running c10t mapping:"
		for WORLD in $WORLDS; do
			printf " $WORLD"
			if [ $(serverRunning $WORLD) = 1 ]; then
				sendCommand $WORLD "say The world is about to be mapped with c10t."
				sendCommand $WORLD "save-all"
				sendCommand $WORLD "save-off"
				sleep 20
				fullBackup $WORLD
				c10t $WORLD
				sendCommand $WORLD "save-on"
				sendCommand $WORLD "say Mapping is complete.  You can access the maps at:"
				sendCommand $WORLD "say $MAPS_URL/$WORLD"
			else
				fullBackup $WORLD
				c10t $WORLD
			fi
		done
		printf "\n"
	;;
	*)
		printf "Usage: $0 {start|stop|force-stop|restart|force-restart|status|send|screen|watch|backup|update|c10t} {Optional: world or software package}\n"
		exit 1
	;;
esac
exit 0
