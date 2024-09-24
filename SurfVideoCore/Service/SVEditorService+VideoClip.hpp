//
//  SVEditorService+VideoClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/29/24.
//

#import <SurfVideoCore/SVEditorService.hpp>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVEditorService (VideoClip)
- (void)appendVideoClipsToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendVideoClipsToMainVideoTrackFromURLs:(NSArray<NSURL *> *)URLs copyToTempDirectoryImmediatly:(BOOL)copyToTempDirectoryImmediatly progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeVideoClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)trimVideoClipWithCompositionID:(NSUUID *)compositionID trimTimeRange:(CMTimeRange)trimTimeRange completionHandler:(EditorServiceCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
