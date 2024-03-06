//
//  AudioSamplesExtractor.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/6/24.
//

#import "AudioSamplesExtractor.hpp"
#import "constants.hpp"

// https://github.com/benoit-pereira-da-silva/SoundWaveForm/blob/master/Sources/SoundWaveForm/SamplesExtractor.swift

@implementation AudioSamplesExtractor

+ (void)extractAudioSamplesFromAssetTrack:(AVAssetTrack *)assetTrack timeRange:(CMTimeRange)timeRange desiredNumberOfSamples:(NSUInteger)desiredNumberOfSamples completionHandler:(void (^)(NSArray<NSNumber *> * _Nullable samples, std::float_t maxSample, NSError * _Nullable error))completionHandler {
    assert(![NSThread isMainThread]);
    
    if (![assetTrack.mediaType isEqualToString:AVMediaTypeAudio]) {
        completionHandler(nil, 0, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotAudioTrack userInfo:nil]);
        return;
    }
    
    AVAsset *asset = assetTrack.asset;
    
    if (asset == nil) {
        completionHandler(nil, 0, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoAssetNotFound userInfo:nil]);
        return;
    }
    
    NSError * _Nullable error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    if (error) {
        completionHandler(nil, 0, error);
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
                                       desiredNumberOfSamples:desiredNumberOfSamples
                                            completionHandler:completionHandler];
}

+ (void)extractAudioSamplesWithAssetReader:(AVAssetReader *)assetReader
                                assetTrack:(AVAssetTrack *)assetTrack
                    desiredNumberOfSamples:(NSUInteger)desiredNumberOfSamples
                         completionHandler:(void (^)(NSArray<NSNumber *> * _Nullable samples, std::float_t maxSample, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    AVAsset *asset = assetReader.asset;
    
    CMAudioFormatDescriptionRef _Nullable audioFormatDescription = NULL;
    
    for (id formatDessciprtion in assetTrack.formatDescriptions) {
        if (CFGetTypeID(formatDessciprtion) == CMFormatDescriptionGetTypeID()) {
            audioFormatDescription = (CMAudioFormatDescriptionRef)formatDessciprtion;
        }
    }
    
    if (audioFormatDescription == NULL) {
        completionHandler(nil, 0, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoFormatDescription userInfo:nil]);
        return;
    }
    
    const AudioStreamBasicDescription *streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescription);
    
    // By default the reader's timerange is set to CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity)
    // So if duration == kCMTimePositiveInfinity we should use the asset duration
    CMTime duration;
    if (CMTIME_IS_POSITIVE_INFINITY(assetReader.timeRange.duration)) {
        duration = asset.duration;
    } else {
        duration = assetReader.timeRange.duration;
    }
    
    Float64 numberOfSamples = (streamBasicDescription->mSampleRate) * duration.value / duration.timescale;
    
    UInt32 channelCount = streamBasicDescription->mChannelsPerFrame;
    
    std::float_t maxSample = DBL_MIN;
}

@end
