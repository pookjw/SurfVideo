//
//  AudioSamplesExtractor.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/6/24.
//

#import "AudioSamplesExtractor.hpp"
#import "constants.hpp"
#import <Accelerate/Accelerate.h>
#include <algorithm>
#include <memory>
#include <ranges>

// https://github.com/benoit-pereira-da-silva/SoundWaveForm/blob/master/Sources/SoundWaveForm/SamplesExtractor.swift

@implementation AudioSamplesExtractor

+ (void)extractAudioSamplesFromAssetTrack:(AVAssetTrack *)assetTrack timeRange:(CMTimeRange)timeRange samplingRate:(Float64)samplingRate noiseFloor:(float)noiseFloor progressHandler:(void (^)(std::optional<const std::vector<float>> samples, BOOL isFinal, BOOL *stop, NSError * _Nullable error))progressHandler {
    assert(![NSThread isMainThread]);
    
    if (![assetTrack.mediaType isEqualToString:AVMediaTypeAudio]) {
        BOOL stop;
        progressHandler(std::nullopt, YES, &stop, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotAudioTrack userInfo:nil]);
        return;
    }
    
    AVAsset *asset = assetTrack.asset;
    
    if (asset == nil) {
        BOOL stop;
        progressHandler(std::nullopt, YES, &stop, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoAssetNotFound userInfo:nil]);
        return;
    }
    
    NSError * _Nullable error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    if (error) {
        BOOL stop;
        progressHandler(std::nullopt, YES, &stop, error);
        return;
    }
    
    if (CMTIMERANGE_IS_VALID(timeRange)) {
        assetReader.timeRange = timeRange;
    }
    
    AVAssetReaderTrackOutput *assetReaderTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetTrack outputSettings:@{
        AVFormatIDKey: @(kAudioFormatLinearPCM),
        AVLinearPCMBitDepthKey: @16,
        AVLinearPCMIsBigEndianKey: @NO,
        AVLinearPCMIsFloatKey: @NO,
        AVLinearPCMIsNonInterleaved: @NO
    }];
    
    [assetReader addOutput:assetReaderTrackOutput];
    
    [AudioSamplesExtractor extractAudioSamplesWithAssetReader:assetReader
                                                   assetTrack:assetTrack
                                       assetReaderTrackOutput:assetReaderTrackOutput
                                             samplingRate:samplingRate
                                                   noiseFloor:noiseFloor
                                              progressHandler:progressHandler];
}

+ (void)extractAudioSamplesWithAssetReader:(AVAssetReader *)assetReader
                                assetTrack:(AVAssetTrack *)assetTrack
                    assetReaderTrackOutput:(AVAssetReaderTrackOutput *)assetReaderTrackOutput
                          samplingRate:(Float64)samplingRate 
                                noiseFloor:(float)noiseFloor
                           progressHandler:(void (^)(std::optional<const std::vector<float>> samples, BOOL isFinal, BOOL *stop, NSError * _Nullable error))progressHandler __attribute__((objc_direct)) {
    CMAudioFormatDescriptionRef _Nullable audioFormatDescription = NULL;
    
    for (id formatDessciprtion in assetTrack.formatDescriptions) {
        if (CFGetTypeID(formatDessciprtion) == CMFormatDescriptionGetTypeID()) {
            audioFormatDescription = (CMAudioFormatDescriptionRef)formatDessciprtion;
        }
    }
    
    if (audioFormatDescription == NULL) {
        BOOL stop;
        progressHandler(std::nullopt, YES, &stop, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoFormatDescription userInfo:nil]);
        return;
    }
    
    const AudioStreamBasicDescription *streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription);
    
    // By default the reader's timerange is set to CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)
    // So if duration == kCMTimePositiveInfinity we should use the asset duration
    CMTime duration;
    if (CMTIME_IS_POSITIVE_INFINITY(assetReader.timeRange.duration)) {
        duration = assetTrack.timeRange.duration;
    } else {
        duration = assetReader.timeRange.duration;
    }
    
    Float64 numberOfSamples = (streamBasicDescription->mSampleRate) * duration.value / duration.timescale;
    UInt32 channelCount = streamBasicDescription->mChannelsPerFrame;
    
    NSUInteger samplesPerPixel = std::floor(std::fmax(1., (Float64)(channelCount) * numberOfSamples / Float64(samplingRate == 0. ? 100. : samplingRate)));
    std::vector<float> filter(samplesPerPixel);
    std::fill(filter.begin(), filter.end(), 1.f / samplesPerPixel);
    
    std::shared_ptr<std::vector<char>> sampleData = std::make_shared<std::vector<char>>();
    
    [assetReader startReading];
    
    while (assetReader.status == AVAssetReaderStatusReading) {
        CMSampleBufferRef CM_NULLABLE sampleBuffer = [assetReaderTrackOutput copyNextSampleBuffer];
        if (sampleBuffer == NULL) break;
        
        CMBlockBufferRef CM_NULLABLE sampleBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        if (sampleBlockBuffer == NULL) {
            CMSampleBufferInvalidate(sampleBuffer);
            CFRelease(sampleBuffer);
            break;
        }
        
        size_t sampleBufferPointerLength;
        char * _Nullable sampleBufferPointer = NULL;
        OSStatus status = CMBlockBufferGetDataPointer(sampleBlockBuffer,
                                                      0,
                                                      &sampleBufferPointerLength,
                                                      NULL,
                                                      &sampleBufferPointer);
        assert(status == kCMBlockBufferNoErr);
        
        sampleData.get()->reserve(sampleBufferPointerLength);
        std::ranges::for_each(sampleBufferPointer, sampleBufferPointer + sampleBufferPointerLength, [sampleData](char a) {
            sampleData.get()->push_back(a);
        });
        
        CMSampleBufferInvalidate(sampleBuffer);
        CFRelease(sampleBuffer);
        
        // 만약 전체 sample 개수가 5이고, downsampled가 2라면 length는 2가 되고 samplesToProcess도 2가 되며 나머지 1은 removeFirst에 의해 남아 있게 된다. 
        size_t totalSamples = sampleData.get()->size() * sizeof(char) / sizeof(short);
        NSUInteger downsampledLength = totalSamples / samplesPerPixel;
        NSUInteger samplesToProcess = totalSamples - totalSamples % samplesPerPixel;
        
        if (samplesToProcess == 0) {
            continue;
        }
        
        std::vector<float> samples = [AudioSamplesExtractor processSamplesFromSampleData:sampleData
                                                                        samplesToProcess:samplesToProcess
                                                                       downsampledLength:downsampledLength
                                                                         samplesPerPixel:samplesPerPixel
                                                                              noiseFloor:noiseFloor
                                                                                  filter:filter];
        
        BOOL isFinal;
        if (assetReader.status == AVAssetReaderStatusCompleted) {
            if (sampleData.get()->size() == 0) {
                isFinal = YES;
            } else {
                isFinal = NO;
            }
        } else {
            isFinal = NO;
        }
        
        BOOL stop = NO;
        progressHandler(samples, isFinal, &stop, nil);
        
        if (stop) {
            return;
        }
    }
    
    // Process the remaining samples at the end which didn't fit into samplesPerPixel
    NSUInteger samplesToProcess = sampleData.get()->size() * sizeof(char) / sizeof(short);
    if (samplesToProcess > 0) {
        NSUInteger downsampledLength = 1;
        NSUInteger samplesPerPixel = samplesToProcess;
        std::vector<float> filter(samplesPerPixel);
        std::fill(filter.begin(), filter.end(), 1.f / samplesPerPixel);
        
        std::vector<float> samples = [AudioSamplesExtractor processSamplesFromSampleData:sampleData
                                                                        samplesToProcess:samplesToProcess
                                                                       downsampledLength:downsampledLength
                                                                         samplesPerPixel:samplesPerPixel
                                                                              noiseFloor:noiseFloor
                                                                                  filter:filter];
        
        BOOL stop;
        progressHandler(samples, YES, &stop, nil);
    }
    
    assert(sampleData.get()->size() == 0);
}

+ (const std::vector<float>)processSamplesFromSampleData:(std::shared_ptr<std::vector<char>>)sampleData samplesToProcess:(NSUInteger)samplesToProcess downsampledLength:(NSUInteger)downsampledLength samplesPerPixel:(NSUInteger)samplesPerPixel noiseFloor:(float)noiseFloor filter:(std::vector<float>)filter __attribute__((objc_direct)) {
    char *samples = sampleData.get()->data();
    
    std::vector<float> processingBuffer(samplesToProcess);
    
    // Convert 16bit int samples to floats
    vDSP_vflt16(reinterpret_cast<const short *>(samples), 1, processingBuffer.data(), 1, (vDSP_Length)samplesToProcess);
    
    // Clear samples
    sampleData.get()->erase(sampleData.get()->begin(), sampleData.get()->begin() + samplesToProcess * sizeof(short) / sizeof(char));
    
    // not necessary
    sampleData.get()->shrink_to_fit();
    
    // Take the absolute values to get amplitude
    vDSP_vabs(processingBuffer.data(), 1, processingBuffer.data(), 1, processingBuffer.size());
    
    // Convert to dB
    const float refDB = 32768.f;
    vDSP_vdbcon(processingBuffer.data(), 1, &refDB, processingBuffer.data(), 1, processingBuffer.size(), 1);
    
    // Clip to [noiseFloor, 0]
    float ceil = 0.f;
    vDSP_vclip(processingBuffer.data(),
               1,
               &noiseFloor,
               &ceil,
               processingBuffer.data(),
               1,
               (vDSP_Length)samplesToProcess);
    
    // Downsample and average
    std::vector<float> downSampledData (downsampledLength);
    vDSP_desamp(processingBuffer.data(),
                (vDSP_Length)samplesPerPixel,
                filter.data(),
                downSampledData.data(),
                vDSP_Length(downSampledData.size()),
                vDSP_Length(filter.size()));
    
    return downSampledData;
}

@end
