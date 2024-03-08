//
//  SVAudioSamplesManager.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/8/24.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>
#import "SVAudioSample.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface SVAudioSamplesManager : NSObject
+ (SVAudioSamplesManager *)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (NSProgress *)audioSampleFromURL:(NSURL *)url completionHandler:(void (^)(SVAudioSample * _Nullable audioSample, NSError * _Nullable error))completionHandler;
- (NSProgress *)audioSampleFromAsset:(AVAsset *)asset completionHandler:(void (^)(SVAudioSample * _Nullable audioSample, NSError * _Nullable error))completionHandler;
- (void)managedObjectContextWithCompletionHandler:(void (^)(NSManagedObjectContext * _Nullable managedObjectContext))completionHandler;
@end

NS_ASSUME_NONNULL_END
