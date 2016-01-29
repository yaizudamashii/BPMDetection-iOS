//
//  BPMDetector.m
//  BPMDetect
//
//  Created by Yuki Konda on 1/29/16.
//  Copyright © 2016 Yuki Konda. All rights reserved.
//

#import "BPMDetector.h"
#include "SuperpoweredDecoder.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredAudioBuffers.h"
#include "SuperpoweredAnalyzer.h"

@implementation BPMDetector

- (float)getBPM:(NSURL *)fileURL
{
    SuperpoweredDecoder *decoder = [self getSongDecoderForFileURL:fileURL]; // where url is the audio song which is either in bundle or in your app document directory
    
    if (!decoder) {
        NSLog(@"Handle Error that decoder is not created");
        return 0;
    }
    float analyzedBPM = [self processSongForDecoder:decoder];
    delete decoder;
    
    return analyzedBPM;
}

-(SuperpoweredDecoder *)getSongDecoderForFileURL:(NSURL *)fileURL {
    SuperpoweredDecoder *decoder = new SuperpoweredDecoder();
    const char *openError = decoder->open([[fileURL path] UTF8String]);
    if (openError) {
        NSLog(@"%s", openError);
        delete decoder;
        return nil;
    }
    return decoder;
}

-(float)processSongForDecoder:(SuperpoweredDecoder *)decoder {
    int sampleRate = decoder->samplerate;
    double durationSeconds = decoder->durationSeconds;
    
    SuperpoweredAudiobufferPool *bufferPool = new SuperpoweredAudiobufferPool(4, 1024 * 1024);             // Allow 1 MB max. memory for the buffer pool.
    
    SuperpoweredOfflineAnalyzer *analyzer = new SuperpoweredOfflineAnalyzer(sampleRate, 0, durationSeconds);
    
    short int *intBuffer = (short int *)malloc(decoder->samplesPerFrame * 2 * sizeof(short int) + 16384);
    
    int samplesMultiplier = 4; ////-->> Performance Tradeoff
    while (true) {
        // Decode one frame. samplesDecoded will be overwritten with the actual decoded number of samples.
        unsigned int samplesDecoded = decoder->samplesPerFrame * samplesMultiplier;
        if (decoder->decode(intBuffer, &samplesDecoded) != SUPERPOWEREDDECODER_OK) break;
        
        // Create an input buffer for the analyzer.
        SuperpoweredAudiobufferlistElement inputBuffer;
        
        bufferPool->createSuperpoweredAudiobufferlistElement(&inputBuffer, decoder->samplePosition, samplesDecoded + 8);
        
        // Convert the decoded PCM samples from 16-bit integer to 32-bit floating point.
        //SuperpoweredStereoMixer::shortIntToFloat(intBuffer, bufferPool->floatAudio(&inputBuffer), samplesDecoded);
        SuperpoweredShortIntToFloat(intBuffer, bufferPool->floatAudio(&inputBuffer), samplesDecoded);
        inputBuffer.endSample = samplesDecoded;             // <-- Important!
        analyzer->process(bufferPool->floatAudio(&inputBuffer), samplesDecoded);
    }
    
    delete bufferPool;
    free(intBuffer);
    
    unsigned char **averageWaveForm = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **peakWaveForm = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **lowWaveform = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **midWaveform = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **highWaveform = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **notes = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    char **overViewWaveForm = (char **)malloc(durationSeconds * sizeof(char *));
    
    int *keyIndex = (int *)malloc(sizeof(int));
    int *waveFormSize = (int *)malloc(sizeof(int));
    
    float *averageDecibel = (float *)malloc(sizeof(float));
    float *loudPartsAverageDecibel = (float *)malloc(sizeof(float));
    float *peakDecibel = (float *)malloc(sizeof(float));
    float *bpm = (float *)malloc(sizeof(float));
    float *beatGridStart = (float *)malloc(sizeof(float));
    
    analyzer->getresults(averageWaveForm, peakWaveForm, lowWaveform, midWaveform, highWaveform, notes, waveFormSize, overViewWaveForm, averageDecibel, loudPartsAverageDecibel, peakDecibel, bpm, beatGridStart, keyIndex);
    
    float detectedBPM = bpm[0];
    
    free(averageWaveForm);
    free(peakWaveForm);
    free(overViewWaveForm);
    free(keyIndex);
    free(waveFormSize);
    free(averageDecibel);
    free(loudPartsAverageDecibel);
    free(peakDecibel);
    free(bpm);
    free(beatGridStart);
    
    return detectedBPM;
}

@end
