%module LTC
%{
#include "lib/libltc/src/ltc.h"
#include "lib/libltc/src/decoder.h"
#include "lib/libltc/src/encoder.h"
%}

%include "stdint.i"
%include "carrays.i"
%include "cpointer.i"
    
typedef unsigned char ltcsnd_sample_t;
%array_class(ltcsnd_sample_t, samplebuffer);

%array_class(float, floata);

typedef int64_t ltc_off_t;

struct LTCFrame {
	unsigned int frame_units:4; ///< SMPTE framenumber BCD unit 0..9
	unsigned int user1:4;

	unsigned int frame_tens:2; ///< SMPTE framenumber BCD tens 0..3
	unsigned int dfbit:1; ///< indicated drop-frame timecode
	unsigned int col_frame:1; ///< colour-frame: timecode intentionally synchronized to a colour TV field sequence
	unsigned int user2:4;

	unsigned int secs_units:4; ///< SMPTE seconds BCD unit 0..9
	unsigned int user3:4;

	unsigned int secs_tens:3; ///< SMPTE seconds BCD tens 0..6
	unsigned int biphase_mark_phase_correction:1; ///< see note on Bit 27 in description and \ref ltc_frame_set_parity .
	unsigned int user4:4;

	unsigned int mins_units:4; ///< SMPTE minutes BCD unit 0..9
	unsigned int user5:4;

	unsigned int mins_tens:3; ///< SMPTE minutes BCD tens 0..6
	unsigned int binary_group_flag_bit0:1; ///< indicate user-data char encoding, see table above - bit 43
	unsigned int user6:4;

	unsigned int hours_units:4; ///< SMPTE hours BCD unit 0..9
	unsigned int user7:4;

	unsigned int hours_tens:2; ///< SMPTE hours BCD tens 0..2
	unsigned int binary_group_flag_bit1:1; ///< indicate timecode is local time wall-clock, see table above - bit 58
	unsigned int binary_group_flag_bit2:1; ///< indicate user-data char encoding (or parity with 25fps), see table above - bit 59
	unsigned int user8:4;

	unsigned int sync_word:16;
};

enum LTC_TV_STANDARD {
	LTC_TV_525_60, ///< 30fps
	LTC_TV_625_50, ///< 25fps
	LTC_TV_1125_60,///< 30fps
	LTC_TV_FILM_24 ///< 24fps
};

/** encoder and LTCframe <> timecode operation flags */
enum LTC_BG_FLAGS {
	LTC_USE_DATE  = 1, ///< LTCFrame <> SMPTETimecode converter and LTCFrame increment/decrement use date, also set BGF2 to '1' when encoder is initialized or re-initialized (unless LTC_BGF_DONT_TOUCH is given)
	LTC_TC_CLOCK  = 2,///< the Timecode is wall-clock aka freerun. This also sets BGF1 (unless LTC_BGF_DONT_TOUCH is given)
	LTC_BGF_DONT_TOUCH = 4, ///< encoder init or re-init does not touch the BGF bits (initial values after initialization is zero)
	LTC_NO_PARITY = 8 ///< parity bit is left untouched when setting or in/decrementing the encoder frame-number
};

struct LTCFrameExt {
	LTCFrame ltc; ///< the actual LTC frame. see \ref LTCFrame
	ltc_off_t off_start; ///< \anchor off_start the approximate sample in the stream corresponding to the start of the LTC frame.
	ltc_off_t off_end; ///< \anchor off_end the sample in the stream corresponding to the end of the LTC frame.
	int reverse; ///< if non-zero, a reverse played LTC frame was detected. Since the frame was reversed, it started at off_end and finishes as off_start (off_end > off_start). (Note: in reverse playback the (reversed) sync-word of the next/previous frame is detected, this offset is corrected).
	floata biphase_tics[LTC_FRAME_BIT_COUNT]; ///< detailed timing info: phase of the LTC signal; the time between each bit in the LTC-frame in audio-frames. Summing all 80 values in the array will yield audio-frames/LTC-frame = (\ref off_end - \ref off_start + 1).
	ltcsnd_sample_t sample_min; ///< the minimum input sample signal for this frame (0..255)
	ltcsnd_sample_t sample_max; ///< the maximum input sample signal for this frame (0..255)
	double volume; ///< the volume of the input signal in dbFS
};

struct SMPTETimecode {
	char timezone[6];   ///< the timezone 6bytes: "+HHMM" textual representation
	unsigned char years; ///< LTC-date uses 2-digit year 00.99
	unsigned char months; ///< valid months are 1..12
	unsigned char days; ///< day of month 1..31

	unsigned char hours; ///< hour 0..23
	unsigned char mins; ///< minute 0..60
	unsigned char secs; ///< second 0..60
	unsigned char frame; ///< sub-second frame 0..(FPS - 1)
};

struct LTCDecoder {
	LTCFrameExt* queue;
	int queue_len;
	int queue_read_off;
	int queue_write_off;

	unsigned char biphase_state;
	unsigned char biphase_prev;
	unsigned char snd_to_biphase_state;
	int snd_to_biphase_cnt;		///< counts the samples in the current period
	int snd_to_biphase_lmt;	///< specifies when a state-change is considered biphase-clock or 2*biphase-clock
	double snd_to_biphase_period;	///< track length of a period - used to set snd_to_biphase_lmt

	ltcsnd_sample_t snd_to_biphase_min;
	ltcsnd_sample_t snd_to_biphase_max;

	unsigned short decoder_sync_word;
	LTCFrame ltc_frame;
	int bit_cnt;

	ltc_off_t frame_start_off;
	ltc_off_t frame_start_prev;

	floata biphase_tics[LTC_FRAME_BIT_COUNT];
	int biphase_tic;
};

struct LTCEncoder {
	double fps;
	double sample_rate;
	double filter_const;
	int flags;
	enum LTC_TV_STANDARD standard;
	ltcsnd_sample_t enc_lo, enc_hi;

	size_t offset;
	size_t bufsize;
	ltcsnd_sample_t *buf;

	char state;

	double samples_per_clock;
	double samples_per_clock_2;
	double sample_remainder;

	LTCFrame f;
};

void ltc_frame_to_time(SMPTETimecode *stime, LTCFrame* frame, int flags);
void ltc_time_to_frame(LTCFrame *frame, SMPTETimecode* stime, enum LTC_TV_STANDARD standard, int flags);
//void ltc_frame_reset(LTCFrame* frame);
//int ltc_frame_increment(LTCFrame* frame, int fps, enum LTC_TV_STANDARD standard, int flags);
//int ltc_frame_decrement(LTCFrame* frame, int fps, enum LTC_TV_STANDARD standard, int flags);
LTCDecoder * ltc_decoder_create(int apv, int queue_size);
//int ltc_decoder_free(LTCDecoder *d);
void ltc_decoder_write(LTCDecoder *d, samplebuffer *buf, size_t size, ltc_off_t posinfo);
//void ltc_decoder_write_float(LTCDecoder *d, float *buf, size_t size, ltc_off_t posinfo);
//void ltc_decoder_write_s16(LTCDecoder *d, short *buf, size_t size, ltc_off_t posinfo);
//void ltc_decoder_write_u16(LTCDecoder *d, ltcsnd_sample_t *buf, size_t size, ltc_off_t posinfo);
int ltc_decoder_read(LTCDecoder *d, LTCFrameExt *frame);
void decode_ltc(LTCDecoder *d, ltcsnd_sample_t *sound, size_t size, ltc_off_t posinfo);
void ltc_decoder_queue_flush(LTCDecoder* d);
//int ltc_decoder_queue_length(LTCDecoderp* d);


LTCEncoder* ltc_encoder_create(double sample_rate, double fps, enum LTC_TV_STANDARD standard, int flags);
void ltc_encoder_free(LTCEncoder *e);
void ltc_encoder_set_timecode(LTCEncoder *e, SMPTETimecode *t);
void ltc_encoder_get_timecode(LTCEncoder *e, SMPTETimecode *t);
int ltc_encoder_inc_timecode(LTCEncoder *e);
int ltc_encoder_dec_timecode(LTCEncoder *e);
void ltc_encoder_set_frame(LTCEncoder *e, LTCFrame *f);
void ltc_encoder_get_frame(LTCEncoder *e, LTCFrame *f);
int ltc_encoder_copy_buffer(LTCEncoder *e, ltcsnd_sample_t *buf);
int ltc_encoder_get_bufferptr(LTCEncoder *e, ltcsnd_sample_t **buf, int flush);
void ltc_encoder_buffer_flush(LTCEncoder *e);
size_t ltc_encoder_get_buffersize(LTCEncoder *e);
int ltc_encoder_reinit(LTCEncoder *e, double sample_rate, double fps, enum LTC_TV_STANDARD standard, int flags);
void ltc_encoder_reset(LTCEncoder *e);
int ltc_encoder_set_buffersize(LTCEncoder *e, double sample_rate, double fps);
int ltc_encoder_set_volume(LTCEncoder *e, double dBFS);
void ltc_encoder_set_filter(LTCEncoder *e, double rise_time);
int ltc_encoder_encode_byte(LTCEncoder *e, int byte, double speed);
void ltc_encoder_encode_frame(LTCEncoder *e);
void ltc_frame_set_parity(LTCFrame *frame, enum LTC_TV_STANDARD standard);
//int parse_bcg_flags(LTCFrame *f, enum LTC_TV_STANDARD standard);
ltc_off_t ltc_frame_alignment(double samples_per_frame, enum LTC_TV_STANDARD standard);



