# Fan board Android Software

We provide

- BXIF.java - a Java driver for the Fan board
- fanLua - an example set of Android Studio java/c++ programs for running
  Gideros Lua scripts on the Fan board
- fanJava - an example Android Studio java program which accesses a
  Fan board

For best use of our Java software you need to download and install the
Android Studio/SDK package.
We don't support the Android Eclipse/ADT software environment.
For Lua and other languages such as Python you also need the Android NDK
package.
There are numerous online references to downloading and installing these
packages.

A typical Android device has a single USB connector,
so for debugging a USB OTG application you need to establish a wifi
connection between your PC and your Android device.
There are numerous online guides to this as well.

## BXIF.java

BXIF.java is the Java language equivalent to libbx on a PC.
Whereas libbx sits above FTDI's D2XX driver library,
BXIF.java sits above FTDI's j2xx.jar driver package.

As far as possible, BXIF implements the same functions as libbx,
with the exception of the rather specialized functions used to
reprogram a Fan board.

BXIF.java is used in both the fanLua examples and the fanJava example.
It sits in the source tree for fanLua here::

  fanLua/app/src/main/java/com/bugblat/bx

## fanLua

fanLua implements the Gideros Lua framework.
It is an Android *flavors* application, with three flavors.
The three flavors can be seen in the source tree under src.
src/main holds the core application.
src/player holds the parts that are different for the player flavor,
similarly for src/slider and src/me.

It is possible to extend the core application, for instance to access Android
functionality such as wifi, SMS, and email.
In that case you will need to add to the functions in the jni parts and in
BXIF.java.
See README.txt in the main folder.

### player

The *player* version has a completely empty *assets* folder.
As a result it will act as behave exactly as the standard Gideros player,
listening for incoming commands from Gideros Studio or from a debugger
such as ZeroBrane_.

### slider

The *slider* version contains the *lua/leds* application, compiled,
in its assets folder.
When this app is installed and run it will search for and control
an attached Fan board.

You can easily replace the default application.
Search for a guide to exporting an app as *assets only* from Gideros.
Copy those assets into the *assets/assets* folder and rebuild
the project.

Or see the next section of this manual.

At the time of writing,
you may be unable to export from the default Gideros download.
Gideros is transitioning to open source and you may need to
upgrade from the free version to a licensed version (also free).

### me

As delivered, the *me* version of the app contains the standard
*Button* application.
It will run OK, but it is really a placeholder for your own application.

This is how it works.

- install and run the *fan-me.apk* app.
- using your favorite file manager app on the Android (we use ASTRO),
  inspect the sdcard/gideros/me/resource folder.
  This may become sdcard0/... or something similar
- the resource folder should contain the script for the *me* app.
  Via a file manager, you can replace it and that's the new app!

You will probably want to develop and interactively debug the
replacement script with the *fan-player* version.


## fanJava

The fanJava app is almost the simplest possible Android Java app
for the Fan board.
Almost because there is only one screen, but not quite because that screen
is a *Fragment* rather than a traditional *Activity*.

The app uses the BXIF library to access the Fan board.
The outermost Activity is MainActivity.java,
the Fan code is in the FanDemo.java Fragment class.
