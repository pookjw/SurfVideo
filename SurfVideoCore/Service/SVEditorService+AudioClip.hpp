//
//  SVEditorService+AudioClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/SVEditorService.hpp>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVEditorService (AudioClip)
- (void)appendAudioClipsToAudioTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs copyToTempDirectoryImmediatly:(BOOL)copyToTempDirectoryImmediatly progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeAudioClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
