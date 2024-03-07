//
//  main.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#include <iostream>
#import "AppDelegate.hpp"
#import "AudioSamplesExtractor.hpp"

int main(int argc, char * argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSURL *url = [NSBundle.mainBundle URLForResource:@"Tea by Coldise | Unminus" withExtension:@"mp3"];
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    
    [asset loadTracksWithMediaType:AVMediaTypeAudio completionHandler:^(NSArray<AVAssetTrack *> * _Nullable tracks, NSError * _Nullable error) {
        assert(!error);
        
        [AudioSamplesExtractor extractAudioSamplesFromAssetTrack:tracks[0] timeRange:kCMTimeRangeInvalid downsamplingRate:100. noiseFloor:-50.f progressHandler:^(std::optional<std::vector<float>> samples, BOOL isFinal, BOOL * _Nonnull stop, NSError * _Nullable error) {
            assert(!error);
            for (float f : samples.value()) {
                NSLog(@"%lf", f);
            }
            
            if (isFinal) {
                NSLog(@"Done");
            }
        }];
    }];
    
    int result = UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
    [pool release];
    return result;;
}
