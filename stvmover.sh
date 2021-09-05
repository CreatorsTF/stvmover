#!/bin/bash
# by sapphonie - sappho.io

# trap ctrl-c properly (SIGINT)
trap exit INT

# check temp file
if test -f "/tmp/stvmover"; then
    echo "stv mover already running! aborting. . . . ."
    exit 1
fi


if [ -d "/srv/daemon-data/" ]; then
    srvroot="/srv/daemon-data/"
elif [ -d "/var/lib/pterodactyl/volumes/" ]; then
    srvroot="/var/lib/pterodactyl/volumes/"
else
    echo "no ptero dir, exiting"
    exit 255
fi

# make temp file
touch /tmp/stvmover

# fix permissions
# TODO: WHY??
chmod 775 -R "$srvroot"
chown pterodactyl:pterodactyl "$srvroot"

demosRoot="/var/www/demos/"
mkdir -p -v "$demosRoot"

# only find demos not modified more than 10 minutes ago (-mmin +10) and feed it into this loop
find "$srvroot"/ -iname '*.dem' -mmin +10 -print0 | while read -rd $'\0' file
do
    # does file have the dem header?
    if hexdump -n 8 "$file" | grep "4c48 4432 4d45 004f" &> /dev/null ;
    # file is almost certainly a real dem file
    then
        realfilename=$(basename "$file")
        servernumber=$(echo "$realfilename" | cut -d '-' -f 1)
        # make temp server directories
        mkdir -pv "$demosRoot""$servernumber"
        # MOVE to demo folder
        mv -v "$file" "$demosRoot""$servernumber"/"$realfilename"
    # file does have the dem suffix but contains invalid data
    else
        echo "$file is the wrong format, deleting";
	rm "$file" -v
    fi
done

# cleanup demos older than 2 weeks
find  "$demosRoot" -iname '*.dem' -mmin +43200 -exec rm {} \;
# cleanup demos older than 2 weeks
find  "$srvroot" -iname '*.dem' -mmin +43200 -exec rm {} \;
# cleanup logs older than 2 weeks in ptero folders
find "$srvroot" -iname '*.log' -mmin +43200 -exec rm {} \;

# fix permissions. again.
chmod 775 -R /var/www/html/
chown -R www-data:www-data /var/www/html/

rm /tmp/stvmover

