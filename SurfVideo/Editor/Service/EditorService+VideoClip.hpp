//
//  EditorService+VideoClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/29/24.
//

#import "EditorService.hpp"
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorService (VideoClip)
- (void)appendVideoClipsToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendVideoClipsToMainVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeVideoClipTrackSegment:(AVCompositionTrackSegment *)trackSegment completionHandler:(EditorServiceCompletionHandler)completionHandler __deprecated;
@end

NS_ASSUME_NONNULL_END
