<img src="images/gc9a01.png" width="50%" height="50%">

# GC9A01 FBTFT overlay

This is a fork of the original dtoverlay for the GC9A01. For my project I need to use three different displays at once. Therefore I changed the overlay to use SPI1 instead of SPI0 because it allows the use of 3x CS pins. To use with SPI0 and only 2x CS pins, all you have to do is removing: "spidev@2", gc9a01_3_pins", "gc9a01@2" and replacing "spi1" (two times) with "spi0"!
The following lines are all from the forked repo. This is everything I changed (so far)!


### Note from the forked repo
The `gc9a01-overlay.dts` [was commited](https://github.com/raspberrypi/linux/commit/efaad621ac01729c9656c47ce009ddb8e7698e16) on the official [Raspberry Pi Linux kernel](https://github.com/raspberrypi/linux). Development on this repository has ceased and any issue or new feature should be handled [there](https://github.com/raspberrypi/linux/blob/rpi-5.15.y/arch/arm/boot/dts/overlays/gc9a01-overlay.dts).

---

This is an overlay for the `fb_ili9340` graphics driver from [NoTro FBTFT](https://github.com/notro/fbtft/wiki/FBTFT-RPI-overlays), to use with LCD displays that has the [Galaxycore's GC9A01 single chip driver](documents/GC9A01A.pdf). It allows to easily setup (in just 3 super easy steps!) said displays to be used on newer Raspberry Pi OS releases that already includes `fbtft` on it's kernel.

## Step #1: Wiring! :electric_plug:

The display should be connected to the Raspberry Pi on the first SPI channel (`spi1`) [pins](https://pinout.xyz). Look at the `pinout.txt` for more information!


## Step #2: Setup! :hammer_and_wrench:

1. Locate your sdcard boot partition. If you are on 'Windows', that should be the partition where the sdcard was mounted (e.g. `E:/`). On 'Raspberry Pi OS' that should be `/boot`;

2. Check the `overlays` directory in boot partition (e.g. `E:/overlays` on 'Windows' or `/boot/overlays` on 'Raspberry Pi OS') and look for the `gc9a01.dtbo` overlay file. If you're missing the file, you can download it from [here](https://github.com/raspberrypi/firmware/raw/master/boot/overlays/gc9a01.dtbo) (official Raspberry Pi Firmware repository) and save it to the said directory;

3. Edit the `config.txt` file on the boot partition and append the following line to the end of the file:

```
dtoverlay=gc9a01-spi1,width=240,height=240,fps=50
```
The line above will attach GC9A01 LCD driver to `/dev/fb1`, `/dev/fb2`, `/dev/fb3` framebuffers over `spi1` spi pins and initialize the LCDs.

That's it. Put the sdcard on the Raspberry Pi and boot (if you did the above steps right inside from 'Raspberry Pi OS', just reboot with `sudo reboot`).

After power up, open a terminal and verify that the device was properly mounted:

```
ls /dev/fb*
```

- this should list `fb1`, `fb2` and `fb3` (for me because fb0 is my hdmi output).

## Step #3: Get some image! :tv:

Since this overlay is just an extension of the device driver, it only attaches and initiates the LCD device on the `fb1/2/3` framebuffer (it's like turning on the TV without any cable or antenna input). In order to actually see something on the display, you need something sending image to it.
What users tipically do is just mirror the HDMI output (displayed on `fb0`) on the LCD (displayed on `fb1/2/3`). For this task there are many tools available and we'll help you to setup one of them bellow. If you are a developer, another way to show stuff on the display would be your application directly write on `fb1/2/3` framebuffer, but that won't be covered here.

### Mirroring HDMI on LCD: Rpi-fbcp

[Raspberry Pi Framebuffer Copy](https://github.com/tasanakorn/rpi-fbcp) is a tool that copies the primary framebuffer (`fb0`) to a secondary one (`fb1/2/3`).

Run the following commands to download, build and install:

```
cd ~
git clone https://github.com/tasanakorn/rpi-fbcp
cd rpi-fbcp/
mkdir build
cd build/
cmake ..
make
sudo install fbcp /usr/local/bin/fbcp
```

To make it run on boot, edit the following file:

```
sudo vi /etc/rc.local
```

Add `fbcp&` on the line right before `exit 0`. The `&` will make it run on background, without hanging the boot process:

```
fbcp&
exit 0
```
Reboot the Raspberry Pi and you'll start seeing the image from HDMI mirrored on the LCD.

<img src="images/gc9a01-desktop.jpg" width="100%" height="100%">

<br>

# Extra setup (optional) :repeat:

## Overlay parameters

The overlay support some optional parameters that allow changes in the default behavior and affects only the LCD display. They are key=value pairs, comma separated in no predefined order, as follow:

```
dtoverlay=gc9a01-spi1,speed=40000000,rotate=0,width=240,height=240,fps=50,debug=0
```

- `speed`: max spi frequency to be used
- `rotate`: image rotation (in degrees: 0, 90, 180, 270)
- `width`: width of the display
- `height`: height of the display
- `fps`: max fps to be used
- `debug`: debug level to be logged on boot process

## Additional image orientation and resolution

Since `fbcp` is making a plain copy from HDMI to LCD, screen resolution may affect the final result. Additional settings can be added on the `config.txt` in order to adjust the resulting image to your needs. The full set of options can be checked at [/boot/overlays/README](https://github.com/raspberrypi/linux/blob/rpi-5.10.y/arch/arm/boot/dts/overlays/README).

Note that the following settings will be applied both to the HDMI and the LCD.

```
dtoverlay=gc9a01-spi1
hdmi_force_hotplug=1
hdmi_cvt=240 240 60 1 0 0 0
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
display_rotate=2
```

- `hdmi_force_hotplug`: force HDMI output rather than DVI
- `hdmi_cvt`: adjusts tge resolution, framerate and more. Format: \<width\> \<height\> \<framerate\> \<aspect\> \<margins\> \<interlace\>
- `hdmi_group`: set DMT group (Display Monitor Timings: the standard typically used by monitors)
- `hdmi_mode`: set DMT mode
- `hdmi_drive`: force a HDMI mode rather than DVI
- `display_rotate`: rotate screen 180 degrees

The `display_rotate` setting allows to rotate or flip the screen orientation to fit your needs. The default value is `0`, possible values are:

- `0` no rotation
- `1` rotate 90 degrees clockwise
- `2` rotate 180 degrees clockwise
- `3` rotate 270 degrees clockwise
- `0x10000` horizontal flip
- `0x20000` vertical flip

This setting is a bitmask. So you can both flip and rotate the display at the same time. Example:

- `0x10001` both do a horizontal flip and rotate 90 degrees clockwise (`0x10000` + `1`).
- `0x20003` both do a vertical flip and rotate 270 degrees clockwise (`0x20000` + `3`).

<br>

# Development :space_invader:

## Building and testing

Clone the repository:

```
cd ~
git clone https://github.com/VogelPapaFinn/gc9a01-overlay-spi1_cs3.git
cd gc9a01-overlay-spi1_cs3
```

Build overlay:

```
./compile-spi1.sh
```


Load overlay:

```
sudo reboot now
```

Check for info on boot process:

```
dmesg | grep spi
dmesg | grep fb
```

- should list the loaded driver info

<br>

---
<sup>[@juliannojungle](https://github.com/juliannojungle), 2022</sup>
