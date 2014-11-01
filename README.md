# Fan - FPGA on an Android

This is the software and firmware for Bugblat's *FPGA on Android*
board - the *Fan* board.

The software directory includes

- an example Java app for full-on Android programming
- a set of example Lua+Java apps for scripted Android programming
- a PC-oriented development environment for prototyping

The firmware directory includes the small *flasher* and *flashctl* designs,
and *la125*, a complete 125MHz logic analyzer.

The lua directory has example Lua programs that will run unchanged
on a PC or on an Android device.

The pc directory contains low level libraries for controlling a FPGA
board, plus a plugin for using the Lua/Gideros framework on a PC.
The pc/utils directory includes programs for reprogramming a
non-volatile FPGA.

## How to Use the Software and Firmware

The Fan board implements an FPGA with a USB interface for
programming and control.
It can connect to an Android's USB OTG port or to a USB port on a PC.

The USB interface is an FTDI chip.
Android applications need to incorporate FTDI's Java interface JAR,
as shown in the example applications.

To develop or test on a PC, you need to install FTDI drivers.

## On a PC - Install Drivers

The Fan board software uses 100% standard FTDI *D2XX* drivers.
Most Linux systems come with FTDI drivers in place,
but for Windows and Mac you have to install them.

At the time of writing, the FTDI drivers are at version 2.10.00
and the driver installation program is
*CDM_v2.10.00_WHQL_Certified.exe*
You can search for the driver installation program via::

    D2XX Direct Drivers site:ftdichip.com

Run the *driver installer*.

The Fan board comes with firmware already installed.
when idle, this firmware flashes the onboard LEDs in phase.

So plug the FPGA board into a USB micro lead
(micro is the type of USB lead used in most modern phones, pads, and eReaders)
and the LEDs should start doing what LEDs do best.

## On Android - Send an APK to Android

Install the Fan Slider app from
[Google Play](https://play.google.com/store/apps/details?id=com.bugblat.fan.slider).

Alternatively, send one of the APKs (in android/faJava/.../apk or android/fanLua/.../apk)
to Android.
Then connect the FPGA board:

- plug the OTG cable into Android
- plug the regular cable into the OTG cable
- plug the board into the regular cable.

Android will ask for permission to connect, then the LEDs will flash.

The usual problem is pluging in the cables back to front.
Both cables have micro-USB connectors so it's easy to do.
The OTG cable has to plug into Android so that Android goes into host mode.
Get it wrong and  Android will stay in slave mode.

## More Information

The Fan product pages, including links to the full documentation, are
[here](http://bugblat.com/products/fan).
