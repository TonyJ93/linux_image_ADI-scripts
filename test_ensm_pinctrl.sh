#!/bin/sh

fdd_pin_control_test () {
	echo Running FDD Pin Control Test
	while true; do
			echo high > $ENABLE # RX&TX ON

			sleep 1

			echo low > $ENABLE # RX&TX OFF

			sleep 1

		done
}

fdd_independant_mode_pin_control_test () {
	echo Running FDD Independant Pin Control Test
	while true; do
			echo high > $ENABLE # RX ON
			echo low > $TXNRX # TX OFF

			sleep 1

			echo high > $TXNRX #TX ON

			sleep 1

		done
}

tdd_pin_control_test () {

	echo Running TDD Pin Control Test
	while true; do

		# RX
		echo low > $ENABLE
		echo low > $TXNRX
		echo low > $TXNRX # add some extra delay required for VCO cal in single synthesizer mode.
		echo high > $ENABLE

		sleep 1

		# TX
		echo low > $ENABLE
		echo high > $TXNRX
		echo high > $TXNRX # add some extra delay required for VCO cal in single synthesizer mode.
		echo high > $ENABLE

		sleep 1
	done
}

if [ `id -u` != "0" ]
then
   echo "This script must be run as root" 1>&2
   exit 1
fi

for i in $(find -L /sys/bus/iio/devices -maxdepth 2 -name name)
do
  dev_name=$(cat $i)
  if [ "$dev_name" = "ad9361-phy" ]; then
     phy_path=$(echo $i | sed 's:/name$::')
     ensm_modes=$(cat $phy_path/ensm_mode_available)
     break
  fi
done

if [ "$dev_name" != "ad9361-phy" ]; then
 echo "This test if for FMCOMMS2/3/4 only"
 exit
fi

cd /sys/class/gpio

if [ -e gpiochip138 ]
then
  #Export the CTRL_IN GPIOs
  echo 239 > export 2> /dev/null
  echo 240 > export 2> /dev/null
else
  echo ERROR: Wrong board?
  exit
fi

ENABLE=gpio239/direction
TXNRX=gpio240/direction

echo low > $ENABLE
echo low > $TXNRX

echo Press CTRL-C to exit

case "$ensm_modes" in
  *fdd*)
    echo "Type: 0 for FDD Pin Control Mode"
    echo "Type: 1 for FDD Independant Pin Control Mode"

    read mode

    if [ $mode = "1" ]; then
	echo pinctrl_fdd_indep > $phy_path/ensm_mode #Enable Pincontrol Mode
	fdd_independant_mode_pin_control_test
    else
	echo pinctrl > $phy_path/ensm_mode #Enable Pincontrol Mode
	fdd_pin_control_test
    fi

    ;;
  *rx*)
    echo pinctrl > $phy_path/ensm_mode #Enable Pincontrol Mode
    tdd_pin_control_test
    ;;
esac
