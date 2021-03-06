 #!/bin/bash

source /auto/grp3/door-display/image_gen/web/config/database.sh
if [[ ! -e "$webDirectory/voltage_monitor/data" ]]; then
    mkdir $webDirectory/voltage_monitor/data
fi
ESP_DEVICES=`mysql -h $deviceDatabaseServer -u $deviceDatabaseUsername --password=$deviceDatabasePassword -s -N -e 'SELECT device_id FROM \`door-display\`.devices'`
ESP_DEVICES_ARRAY=($ESP_DEVICES);
for device_id in "${ESP_DEVICES_ARRAY[@]}"
do
    voltage=`mysql -h $deviceDatabaseServer -u $deviceDatabaseUsername --password=$deviceDatabasePassword -s -N -e 'SELECT voltage FROM \`door-display\`.devices WHERE device_id = '$device_id`
    mac_address=`mysql -h $deviceDatabaseServer -u $deviceDatabaseUsername --password=$deviceDatabasePassword -s -N -e 'SELECT mac_address FROM \`door-display\`.devices WHERE device_id = '$device_id`
    if [[ ! -f "$rrdDirectory/$mac_address.rrd" ]]; then
        rrdtool create $rrdDirectory/$mac_address.rrd \
            --start `date +%s` \
            --step 1800 \
            DS:voltage:GAUGE:3600:1:4 \
            RRA:AVERAGE:0.5:48:366 \
            RRA:AVERAGE:0.5:1:335
    fi
    rrdtool update $rrdDirectory/$mac_address.rrd N:$voltage
    rrdtool graph \
        $webDirectory/voltage_monitor/data/week_$mac_address.png \
        -u 3.3 -l 2.3 -r \
        --end now --start end-167h \
        DEF:voltagea=$rrdDirectory/$mac_address.rrd:voltage:AVERAGE \
        LINE1:voltagea#0000FF:"Voltage over past week"
    rrdtool graph \
        $webDirectory/voltage_monitor/data/month_$mac_address.png \
        -u 3.3 -l 2.3 -r \
        --end now --start end-1m \
        DEF:voltagea=$rrdDirectory/$mac_address.rrd:voltage:AVERAGE \
        LINE1:voltagea#0000FF:"Voltage over past month"
    rrdtool graph \
        $webDirectory/voltage_monitor/data/year_$mac_address.png \
        -u 3.3 -l 2.3 -r \
        --end now --start end-1y \
        DEF:voltagea=$rrdDirectory/$mac_address.rrd:voltage:AVERAGE \
        LINE1:voltagea#0000FF:"Voltage over past year"

    chmod 660 $webDirectory/voltage_monitor/data/week_$mac_address.png 
    chmod 660 $webDirectory/voltage_monitor/data/month_$mac_address.png 
    chmod 660 $webDirectory/voltage_monitor/data/year_$mac_address.png 
done
