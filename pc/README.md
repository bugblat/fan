# Fan board PC Software

## libbx - Shared Library

To control your Fan board you need to

- access the USB port and control the onboard FT230
- reload the FPGA
- control the FPGA

To ease this task we provide a shared driver library that sits
directly above the FTDI chip drivers.
The *libbx* library operates at the level of *write to the FPGA*,
*read from the FPGA*, and *reload the FPGA*. It knows nothing about the
firmware inside the FPGA, nothing about the register allocations.

libbx operates in two modes.

- in application mode, libbx interfaces between an application program
  and the operating system drivers for the FT230 USB/UART chip.

- in JTAG mode, libbx controls the FT230 so that it can bit-bang the
  JTAG interface; it also implements the host of low-level commands that
  are required to reprogram the FPGA.

libbx is written in C++, with a C wrapper so
that it can interface easily to scripting languages such as Python.
The source files are in the libbx folder.
The interface is defined in the *libbx.h* file.

The software/libbx folder includes precompiled libbx.dll
and libbx.so files - you can run the Python software even if
the compiler tools for C/C++ are missing from your system.

## bxPlugin - Gideros Plugin

The Fan board supports the Gideros_ software framework,
recently released as open source.
*bxPlugin* is a thin layer over libbx that bridges between a Lua program in
Gideros and the Fan hardware.

The plugin compiles under Windows to a DLL.
To install it under Gideros the DLL must be copied to the *Plugins* folder
of your Gideros installation.
Usually this is here::

  C:\Program Files\Gideros\Plugins

You may need to run as Administrator.

With the plugin installed, it can be used in a Lua script like this::

  require "bxPlugin"

  if bx.open() then
    isOpen = true
    local ok, d = bx.readReg(0, 32)
    ...
    ...

See also the Lua examples.
