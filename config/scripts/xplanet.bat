:: Converted .sh script to .bat 
:: Matt Coblentz, 11 May 2024
:: No, I don't know exactly what I'm doing

@echo off

SET SWITCH=%~1
SET %~1CMDRESPONSE=1
SET %~1TM="Totalmarker2.6.1.pl"

IF [[ "%SWITCH%" != "install" "]]" (
  source "C:\Users\mcoblent\xplanet-1.3.0\xplanet\config\xp.def"
)

case "$SWITCH" in
    install)
        echo "Installing Xplanet"
        brew tap matthewc100/Xplanet
        
        brew install -s matthewc100/Xplanet/xplanet --with-all
        if [ ! $? -eq 0 ]; then
            echo "ERROR... Problem with Xplanet build. Exiting."
            exit 1
        fi
        echo "Point to Xplanet binary"
        sed -i '' "s#XPLANET_BIN=#XPLANET_BIN=$(/usr/bin/which xplanet)#" "C:\Users\mcoblent\xplanet-1.3.0\xplanet\config\xp.def"
        if [ ! $? -eq 0 ]; then
            echo "################################################################################"
            echo "WARNING... Double check XPLANET_BIN is set correctly in file ~/.Xplanet/config/xp.def"
            echo "################################################################################"
        fi
        echo "################################################################################"
        echo "Running Xplanet to bring up Mac security approvals"
        echo "Xplanet won't work without these approvals"
        echo "Accept fast... (within 10 seconds)"
        echo "################################################################################"
        echo 'Press any key to continue or Control-C to exit...'; read -k1 -s
        $(xplanet -num_times=1)
        sleep 8
        $(xplanet -num_times=1)
        sleep 2
        ;;
    setup)
        source $XPLANET_CONFIG\\scripts\\xp-setup.sh
        ;;
    start)
        $XPLANET_BIN \
            -searchdir=$XPLANET_HOME \
            -config=$XPLANET_CONFIG/xp.conf \
            -projection=$XPLANET_PROJECTION \
            -longitude=$(( ( RANDOM % 360 ) - 180 )) \
            -latitude=$(( ( RANDOM % 180 ) - 90 )) \
#           -random \
            -save_desktop_file \
            -labelpos=+10-45 \
            -date_format="%D at %r" \
            -color=green2 \
            -fork \
            -output=$XPLANET_OUTPUT

        ;;
    stop)
        # kill -9 $(ps aux | grep '[x]planet' | awk '{print $2}')
        killall xplanet
        ;;
    earth)
        # rm $XPLANET_HOME/logs/xplanet*
        MONTH=$(date +%m)
        LAND_FILE="$EARTH_MAP_PRE.2004$MONTH.3x5400x2700.png"
        ln -sfn $XPLANET_CONFIG/images/$LAND_FILE $XPLANET_HOME/images/earth.png
        ;;
    clouds)
        echo "$(date): Updating Cloud Image"
        /usr/bin/perl $TM -Clouds
        ;;
    quake)
        echo "$(date): Updating Earthquake Information"
        /usr/bin/perl $TM -Quake
        ;;
    storm)
        echo "$(date): Updating Storm Information"
        /usr/bin/perl $TM -Storm
        ;;
    volcano)
        echo "$(date): Updating Volcano Information"
        /usr/bin/perl $TM -Volcano
        ;;
    label)
        echo "$(date): Updating Label"
        /usr/bin/perl $TM -Label
        ;;
    *)
        clear
        echo -e "Options for this script:
./xplanet.sh
  'install' - installs Xplanet
  'setup'   - sets the Xplanet environment
  'start'   - starts Xplanet in forked process
  'stop'    - stops all running instances of Xplanet
  'earth'   - updates the monthly Earth map and maintenance
  'clouds'  - updates the cloud map
  'quake'   - updates the quake marker
  'storm'   - updates the storm marker
  'volcano' - updates the volcano marker
  'label'   - updates the label marker
"
        exit 1 ;;
esac

CMDRESPONSE=$?

if [ $CMDRESPONSE -eq 0 ]; then
    case "$SWITCH" in
        install)    echo "Xplanet is successfully installed (it should be the current background)" ;;
        setup)      echo "Xplanet environment setup is complete" ;;
        start)      echo "$(date): Xplanet Started" ;;
        stop)       echo "$(date): Xplanet Stopped" ;;
        earth)      echo "$(date): Earth Map Updated"
                    # echo "$(date): Pruned Logs"
            ;;
    esac
else
    case "$SWITCH" in
        install)    echo "ERROR! Xplanet installation returned code '$CMDRESPONSE'" ;;
        setup)      echo "ERROR! Xplanet environment setup returned code '$CMDRESPONSE'" ;;
        start)      echo "$(date): ERROR! Xplanet couldn't start code '$CMDRESPONSE'" ;;
        stop)       echo "$(date): ERROR! Couldn't stop Xplanet processes, code '$CMDRESPONSE'" ;;
        earth)      echo "$(date): ERROR! Couldn't update Xplanet earth map, code '$CMDRESPONSE'"
                    # echo "$(date): ERROR! Couldn't prune Xplanet logs, code '$CMDRESPONSE'"
            ;;
        clouds)     echo "$(date): ERROR! Totalmarker cloud update didn't exit cleanly, code '$CMDRESPONSE'" ;;
        quake)      echo "$(date): ERROR! Totalmarker earthquake update didn't exit cleanly, code '$CMDRESPONSE'" ;;
        storm)      echo "$(date): ERROR! Totalmarker storm update didn't exit cleanly, code '$CMDRESPONSE'" ;;
        volcano)    echo "$(date): ERROR! Totalmarker volcano update didn't exit cleanly, code '$CMDRESPONSE'" ;;
        label)      echo "$(date): ERROR! Totalmarker label update didn't exit cleanly, code '$CMDRESPONSE'" ;;
    esac
fi
