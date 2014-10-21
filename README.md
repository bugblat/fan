# fan - FPGA on an Android


This is the software and firmware for Bugblat's *FPGA on Android*
board - the *Fan* board.

The software includes

- for full-on Android programming, an example Java app
- for scripted Android programming, a set of example Lua+Java apps
- a PC-oriented development environment for prototyping

## What is the Fan board?

The Fan board connects to an Android's USB OTG port via an FTDI interface chip.
To get started you need to install the FTDI drivers, then plug in the Fan board.


## Install the Drivers

The Fan board software uses 100% standard FTDI *D2XX* drivers.
Most Linux systems come with FTDI drivers in place,
but for Windows and Mac you have to install them.

At the time of writing, the FTDI drivers are at version 2.10.00
and the driver installation program is
*CDM_v2.10.00_WHQL_Certified.exe*
You can search for the driver installation program via::

    D2XX Direct Drivers site:ftdichip.com

Run the *driver installer*.


## Plug In the Fan board

The Fan board comes with firmware already installed.
when idle, this firmware flashes the onboard LEDs in phase.

So plug your Fan board into a USB micro lead
(micro is the type of USB lead used in most modern phones, pads, and eReaders)
and the LEDs should start doing what LEDs do best.


## More Information

The Fan product pages, including links to the full documentation, are
[here](http://bugblat.com/products/fan).
