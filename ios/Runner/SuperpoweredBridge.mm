#include "Superpowered.h"
#include "SuperpoweredBridge.h"
#include "SuperpoweredAnalyzer.h"
#include "SuperpoweredDecoder.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Key dev
static const char *superpoweredKey = "ExampleLicenseKey-WillExpire-OnNextUpdate";

float detectBpmFromFile(const char *path) {

    if (!path || strlen(path) == 0) {
        printf("❌ Invalid file path (null or empty).\n");
        return 0.0f;
    }

    FILE *fileCheck = fopen(path, "rb");
    if (!fileCheck) {
        printf("❌ File not found or inaccessible: %s\n", path);
        return 0.0f;
    }
    fclose(fileCheck);

    printf("📂 Initializing Superpowered SDK...\n");
    Superpowered::Initialize(superpoweredKey);

    // Create decoder and open file
    Superpowered::Decoder *decoder = new Superpowered::Decoder();
    
    int open =  decoder->open(path);
    
    int sampleRate = decoder->getSamplerate();
    int duration = (int)decoder->getDurationSeconds();

    printf("📄 File info — Sample rate: %d Hz, Duration: %d seconds\n", sampleRate, duration);

    Superpowered::Analyzer *analyzer = new Superpowered::Analyzer(sampleRate, duration);

    const unsigned int numFrames = 8192;
    short int *intBuffer = (short int *)malloc(numFrames * 2 * sizeof(short int)); // stereo short int
    float *floatBuffer = (float *)malloc(numFrames * 2 * sizeof(float));           // stereo float

    if (!intBuffer || !floatBuffer) {
        printf("❌ Failed to allocate audio buffers.\n");
        free(intBuffer);
        free(floatBuffer);
        delete analyzer;
        delete decoder;
        return 0.0f;
    }

    while (true) {
        int framesDecoded = decoder->decodeAudio(intBuffer, numFrames);
        if (framesDecoded <= 0) break;

        // Convert short int to float [-1.0,1.0]
        for (int i = 0; i < framesDecoded * 2; i++) {
            floatBuffer[i] = intBuffer[i] / 32768.0f;
        }

        analyzer->process(floatBuffer, (unsigned int)framesDecoded);
    }

    analyzer->makeResults(
        60.0f, 200.0f,  // BPM range
        0.0f, 0.0f,     // knownBpm, aroundBpm
        false, 0.0f,    // beatgrid detection
        false, false,   // waveform generation (low/mid/high)
        false           // key detection
    );

    float bpm = analyzer->bpm;
    printf("✅ Detected BPM: %.2f\n", bpm);

    free(intBuffer);
    free(floatBuffer);
    delete analyzer;
    delete decoder;

    return bpm;
}
