//
//  EditorService.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import "SVVideoProject.hpp"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const EditorServiceDidChangeCompositionNotification;
extern NSString * const EditorServiceCompositionKey;

__attribute__((objc_direct_members))
@interface EditorService : NSObject
@property (class, readonly, nonatomic) CMPersistentTrackID mainVideoTrackID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities NS_DESIGNATED_INITIALIZER;
- (void)initializeWithProgressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler;
- (void)appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler;
- (void)removeTrackSegment:(AVCompositionTrackSegment *)trackSegment atTrackID:(CMPersistentTrackID)trackID completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
