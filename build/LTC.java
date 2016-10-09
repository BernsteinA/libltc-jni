/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 3.0.8
 *
 * Do not make changes to this file unless you know what you are doing--modify
 * the SWIG interface file instead.
 * ----------------------------------------------------------------------------- */

package org.gareus.libltc;

public class LTC {
  public static void ltc_frame_to_time(SMPTETimecode stime, LTCFrame frame, int flags) {
    LTCJNI.ltc_frame_to_time(SMPTETimecode.getCPtr(stime), stime, LTCFrame.getCPtr(frame), frame, flags);
  }

  public static void ltc_time_to_frame(LTCFrame frame, SMPTETimecode stime, LTC_TV_STANDARD standard, int flags) {
    LTCJNI.ltc_time_to_frame(LTCFrame.getCPtr(frame), frame, SMPTETimecode.getCPtr(stime), stime, standard.swigValue(), flags);
  }

  public static LTCDecoder ltc_decoder_create(int apv, int queue_size) {
    long cPtr = LTCJNI.ltc_decoder_create(apv, queue_size);
    return (cPtr == 0) ? null : new LTCDecoder(cPtr, false);
  }

  public static void ltc_decoder_write(LTCDecoder d, samplebuffer buf, long size, long posinfo) {
    LTCJNI.ltc_decoder_write(LTCDecoder.getCPtr(d), d, samplebuffer.getCPtr(buf), buf, size, posinfo);
  }

  public static int ltc_decoder_read(LTCDecoder d, LTCFrameExt frame) {
    return LTCJNI.ltc_decoder_read(LTCDecoder.getCPtr(d), d, LTCFrameExt.getCPtr(frame), frame);
  }

  public static void decode_ltc(LTCDecoder d, SWIGTYPE_p_unsigned_char sound, long size, long posinfo) {
    LTCJNI.decode_ltc(LTCDecoder.getCPtr(d), d, SWIGTYPE_p_unsigned_char.getCPtr(sound), size, posinfo);
  }

  public static void ltc_decoder_queue_flush(LTCDecoder d) {
    LTCJNI.ltc_decoder_queue_flush(LTCDecoder.getCPtr(d), d);
  }

}