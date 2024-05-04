//
//  EditorService+AudioClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService+AudioClip.hpp"
#import "EditorService+Private.hpp"
#import "NSManagedObjectContext+CheckThread.hpp"

@implementation EditorService (AudioClip)

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
