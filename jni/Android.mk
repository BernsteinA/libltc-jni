LOCAL_PATH := .
include $(CLEAR_VARS)
LOCAL_MODULE := libltc
LOCAL_SRC_FILES := src/ltc_wrap.c src/lib/libltc/src/ltc.c src/lib/libltc/src/timecode.c src/lib/libltc/src/decoder.c src/lib/libltc/src/encoder.c
TARGET_PLATFORM := android-10
include $(BUILD_SHARED_LIBRARY)