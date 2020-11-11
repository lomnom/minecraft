#!/bin/bash
screen -dmS minecraft sh
screen -S minecraft -X stuff "cd /home/minecraft 
java -Xms2G -Xmx3500M  \
-XX:+UseG1GC  \
-XX:+ParallelRefProcEnabled  \
-XX:MaxGCPauseMillis=200  \
-XX:+UnlockExperimentalVMOptions  \
-XX:+DisableExplicitGC  \
-XX:+AlwaysPreTouch  \
-XX:G1NewSizePercent=30  \
-XX:G1MaxNewSizePercent=40  \
-XX:G1HeapRegionSize=8M  \
-XX:G1ReservePercent=20  \
-XX:G1HeapWastePercent=5  \
-XX:G1MixedGCCountTarget=4  \
-XX:InitiatingHeapOccupancyPercent=15  \
-XX:G1MixedGCLiveThresholdPercent=90  \
-XX:G1RSetUpdatingPauseTimePercent=5  \
-XX:SurvivorRatio=32  \
-XX:+PerfDisableSharedMem  \
-XX:MaxTenuringThreshold=1  \
-Dusing.aikars.flags=https://mcflags.emc.gs  \
-Daikars.new.flags=true  \
-jar /home/minecraft/spigot-1.16.3.jar  \
-nogui
"
