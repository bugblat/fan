@echo off
cd libs\armeabi
for %%i in (*.so) do if not "%%i"=="libbxPlugin.so" del /q "%%i"
cd ..\..
cd libs\armeabi-v7a
for %%i in (*.so) do if not "%%i"=="libbxPlugin.so" del /q "%%i"
cd ..\..
cd libs\x86
for %%i in (*.so) do if not "%%i"=="libbxPlugin.so" del /q "%%i"
cd ..\..
