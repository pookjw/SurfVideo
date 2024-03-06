//
//  main.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.hpp"
#import "AudioSamplesExtractor.hpp"

int main(int argc, char * argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSURL *url = [NSBundle.mainBundle URLForResource:@"Tea by Coldise | Unminus" withExtension:@"mp3"];
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AudioSamplesExtractor extractAudioSamplesFromAssetTrack:asset.tracks.firstObject timeRange:kCMTimeRangeInvalid desiredNumberOfSamples:0 completionHandler:^(NSArray<NSNumber *> * _Nullable samples, std::float_t maxSample, NSError * _Nullable error) {
            assert(!error);
        }];
    });
    
    int result = UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
    [pool release];
    return result;;
}
