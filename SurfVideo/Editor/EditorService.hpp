//
//  EditorService.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import "SVProjectsManager.hpp"
#import "EditorRenderer.hpp"
#import "EditorRenderCaption.hpp"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const EditorServiceCompositionDidChangeNotification;

// AVComposition *
extern NSString * const EditorServiceCompositionKey;

// AVVideoComposition *
extern NSString * const EditorServiceVideoCompositionKey;

// NSArray<__kindof EditorRenderElement *> *
extern NSString * const EditorServiceRenderElementsKey;

#define EditorServiceCompletionHandler void (^ _Nullable)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error)

__attribute__((objc_direct_members))
@interface EditorService : NSObject
@property (class, readonly, nonatomic) CMPersistentTrackID mainVideoTrackID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities NS_DESIGNATED_INITIALIZER;

- (void)compositionWithCompletionHandler:(void (^)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements))completionHandler;

- (void)initializeWithProgressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendVideosToMainVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeTrackSegment:(AVCompositionTrackSegment *)trackSegment atTrackID:(CMPersistentTrackID)trackID completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeCaption:(EditorRenderCaption *)caption completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendCaptionWithAttributedString:(NSAttributedString *)attributedString completionHandler:(EditorServiceCompletionHandler)completionHandler;

// kCMTimeInvalid will not update time
- (void)editCaption:(EditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
