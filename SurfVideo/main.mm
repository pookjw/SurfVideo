//
//  main.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.hpp"
#import "SVAudioSamplesManager.hpp"

int main(int argc, char * argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSURL *url = [NSBundle.mainBundle URLForResource:@"Tea by Coldise | Unminus" withExtension:@"mp3"];
    [SVAudioSamplesManager.sharedInstance audioSampleFromURL:url completionHandler:^(SVAudioSample * _Nullable audioSample, NSError * _Nullable error) {
        NSLog(@"%@ %@", audioSample, error);
    }];
    int result = UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
    [pool release];
    return result;;
}
