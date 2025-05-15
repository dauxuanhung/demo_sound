#include <jni.h>
#include <string>
#include <android/log.h>
#include <OpenSource/SuperpoweredAndroidAudioIO.h>
#include <Superpowered.h>
#include <SuperpoweredSimple.h>
#include <SuperpoweredAnalyzer.h>
#include <unistd.h>
#include <SuperpoweredRecorder.h>
#include <SuperpoweredDecoder.h>
static Superpowered::Analyzer *analyzer;
static SuperpoweredAndroidAudioIO *audioIO;
static Superpowered::Recorder *recorder;

// This is called periodically by the audio I/O.
static bool audioProcessing(
        void *__unused clientdata, // custom pointer
        short int *audio,           // buffer of interleaved samples
        int numberOfFrames,         // number of frames to process
        int __unused samplerate     // current sample rate in Hz
) {
    float floatBuffer[numberOfFrames * 2];
    Superpowered::ShortIntToFloat(audio, floatBuffer, (unsigned int) numberOfFrames);
    recorder->recordInterleaved(floatBuffer, (unsigned int) numberOfFrames);

    analyzer->process(floatBuffer, (unsigned int) numberOfFrames);
    return true;
}

// StartAudio - Start audio engine.
extern "C" JNIEXPORT void
Java_com_example_demo_1sound_RecorderService_StartAudio(
        JNIEnv *__unused env,
        jobject __unused obj,
        jint samplerate,
        jint buffersize,
        jint destinationfd // file descriptor of the destination file
) {
    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    analyzer = new Superpowered::Analyzer(samplerate, 60);
    // Initialize the recorder.
    recorder = new Superpowered::Recorder(NULL);

    // Start a new recording.
    recorder->preparefd(
            destinationfd,            // destination file descriptor
            0,                        // not used
            (unsigned int) samplerate, // sample rate in Hz
            true,                     // apply fade in/fade out
            1                         // minimum length of the recording in seconds
    );


    // Initialize audio engine with audio callback function.
    audioIO = new SuperpoweredAndroidAudioIO(
            samplerate,      // native sampe rate
            buffersize,      // native buffer size
            true,            // enableInput
            false,           // enableOutput
            audioProcessing, // process callback function
            NULL             // clientData
    );
}

extern "C" JNIEXPORT jfloat
Java_com_example_demo_1sound_MainActivity_GetBmpFromFile(
        JNIEnv *env,
        jobject __unused obj,
        jstring path
) {
Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    const char *pathEnd = env->GetStringUTFChars(path, nullptr);
    if (pathEnd == nullptr) {
        return  0;
    }

    Superpowered::Decoder decoder;
    int error = decoder.open(pathEnd, false);
    if(error!=0)
    {
        return 0;
    }
    __android_log_print(ANDROID_LOG_DEBUG, "durationMs", "%d", decoder.getSamplerate());
    analyzer = new Superpowered::Analyzer(decoder.getSamplerate(), (int) decoder.getDurationSeconds());
    __android_log_print(ANDROID_LOG_DEBUG, "PlayerExample", "Opening file: %s", pathEnd);

    const int bufferSize = 4096;
    short int buffer[bufferSize * 2];

    while (true) {
        unsigned int framesDecoded = decoder.decodeAudio(buffer, bufferSize);
        __android_log_print(ANDROID_LOG_DEBUG, "PlayerExample", "Frames decoded: %u",framesDecoded);
        if (framesDecoded == 0) break;
        float floatBuffer[framesDecoded * 2];
        Superpowered::ShortIntToFloat(buffer, floatBuffer, framesDecoded);
        if (analyzer == nullptr) {
        __android_log_print(ANDROID_LOG_ERROR, "Analyzer", "Analyzer is NULL!");
        break;
        }

        __android_log_print(ANDROID_LOG_DEBUG, "Analyzer", "Processing %u frames", framesDecoded);
        analyzer->process(floatBuffer, framesDecoded);
    }
    if (analyzer) {
        analyzer->makeResults(60.0f, 200.0f, 0.0f, 0.0f, false, 0.0f, false, false, false);
        float bpmValue = analyzer->bpm;
        __android_log_print(ANDROID_LOG_DEBUG, "Analyzer", "Detected BPM: %f", bpmValue);
        return  bpmValue;
    }
    return  0;
}