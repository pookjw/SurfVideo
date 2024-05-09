//
//  SVEditorService+AudioClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/SVEditorService+AudioClip.hpp>
#import <SurfVideoCore/SVEditorService+Private.hpp>
#import <SurfVideoCore/NSManagedObjectContext+CheckThread.hpp>

@implementation SVEditorService (AudioClip)

- (void)appendAudioClipsToAudioTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults
                                      progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler 
                                    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    
}

- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [self appendClipsFromURLs:URLs intoTrackID:self.audioTrackID progressHandler:progressHandler completionHandler:completionHandler];
}

- (void)removeAudioClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [self removeClipWithCompositionID:compositionID completionHandler:completionHandler];
}

@end
