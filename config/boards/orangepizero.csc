# Allwinner H2+ quad core 256/512MB RAM SoC WiFi SPI
BOARD_NAME="Orange Pi Zero"
BOARDFAMILY="sun8i"
BOARD_MAINTAINER=""
BOOTCONFIG="orangepi_zero_defconfig"
MODULES_CURRENT="g_serial"
MODULES_BLACKLIST="sunxi_cedrus"
DEFAULT_OVERLAYS="usbhost2 usbhost3 tve"
DEFAULT_CONSOLE="both"
HAS_VIDEO_OUTPUT="yes"
KERNEL_TARGET="current,edge,legacy"
KERNEL_TEST_TARGET="current"
# CRUSTCONFIG="orangepi_zero_defconfig" # Crust is failing https://github.com/armbian/build/issues/8197

DISPLAYCON=''
SERIALCON="ttyS0:115200,ttyGS0"

BOOTSCRIPT='boot-generic.cmd.template:boot.cmd'
BOOTSCRIPT_TEMPLATE__ALIGN_TO='0x00001000'
BOOTSCRIPT_TEMPLATE__BOARD_FAMILY="${BOARDFAMILY:-sun8i}"
BOOTSCRIPT_TEMPLATE__BOARD_VENDOR='allwinner'
BOOTSCRIPT_TEMPLATE__LOAD_ADDR='0x45000000'
BOOTSCRIPT_TEMPLATE__ROOTFS_TYPE="${ROOTFS_TYPE:-ext4}"
BOOTSCRIPT_TEMPLATE__DISPLAY_CONSOLE='' # leave empty, use DISPLAYCON
BOOTSCRIPT_TEMPLATE__SERIAL_CONSOLE='' # leave empty, use SERIALCON

function orange_pi_zero_enable_xradio_workarounds() {
	/usr/bin/systemctl enable xradio_unload.service
	/usr/bin/systemctl enable xradio_reload.service
}

function post_family_tweaks_bsp__fix_resume_after_suspend() {
	# Adding systemd services to remove and reload xradio module on suspend and resume
	# respectively. It will fix suspend resume using systemctl suspend, but rtcwake is
	# still be broken.

	run_host_command_logged cat <<- 'xradio_unload' > "${destination}"/etc/systemd/system/xradio_unload.service
		[Unit]
		Description=Unload xradio module on sleep
		Before=sleep.target

		[Service]
		Type=simple
		ExecStart=-/usr/sbin/rmmod xradio_wlan

		[Install]
		WantedBy=sleep.target
	xradio_unload

	run_host_command_logged cat <<- 'xradio_reload' > "${destination}"/etc/systemd/system/xradio_reload.service
		[Unit]
		Description=Reload xradio module on resume
		After=suspend.target

		[Service]
		Type=simple
		ExecStart=-/usr/sbin/modprobe xradio_wlan

		[Install]
		WantedBy=suspend.target
	xradio_reload

	# Enable workaround on apt upgrade of armbian-bsp-cli package
	postinst_functions+=('orange_pi_zero_enable_xradio_workarounds')
}
