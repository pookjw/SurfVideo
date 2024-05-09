//
//  EditorService+AudioClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/EditorService.hpp>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorService (AudioClip)
- (void)appendAudioClipsToAudioTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * progress))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeAudioClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
