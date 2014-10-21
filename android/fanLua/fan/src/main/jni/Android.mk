LOCAL_PATH := $(call my-dir)

###

include $(CLEAR_VARS)

LOCAL_MODULE            := lua
LOCAL_SRC_FILES         := ../jniLibs/$(TARGET_ARCH_ABI)/liblua.so

include $(PREBUILT_SHARED_LIBRARY)

#
# Gideros Shared Library
#
include $(CLEAR_VARS)

LOCAL_MODULE            := gideros
LOCAL_SRC_FILES         := ../jniLibs/$(TARGET_ARCH_ABI)/libgideros.so

include $(PREBUILT_SHARED_LIBRARY)

#
# Lua Socket Library
#
include $(CLEAR_VARS)

LOCAL_MODULE            := luasocket
LOCAL_SRC_FILES         := ../jniLibs/$(TARGET_ARCH_ABI)/libluasocket.so

include $(PREBUILT_SHARED_LIBRARY)

#
# Lua File System Library
#
include $(CLEAR_VARS)

LOCAL_MODULE            := lfs
LOCAL_SRC_FILES         := ../jniLibs/$(TARGET_ARCH_ABI)/liblfs.so

include $(PREBUILT_SHARED_LIBRARY)

#
# Plugin
#
include $(CLEAR_VARS)

LOCAL_MODULE           := bxPlugin
LOCAL_ARM_MODE         := arm
LOCAL_CFLAGS           := -O2 -Wall
LOCAL_SRC_FILES        := bxPlugin.cpp
LOCAL_LDLIBS           := -ldl -llog
LOCAL_SHARED_LIBRARIES := gideros lua

include $(BUILD_SHARED_LIBRARY)
