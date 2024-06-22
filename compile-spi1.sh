sudo dtc -W no-unit_address_vs_reg -@ -I dts -O dtb -o gc9a01-spi1.dtbo gc9a01-spi1.dts
sudo cp gc9a01-spi1.dtbo /boot/firmware/overlays
