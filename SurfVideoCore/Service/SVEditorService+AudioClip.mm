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

- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs
               copyToTempDirectoryImmediatly:(BOOL)copyToTempDirectoryImmediatly
                             progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler
                           completionHandler:(EditorServiceCompletionHandler)completionHandler {
    if (copyToTempDirectoryImmediatly) {
        NSError * _Nullable error = nil;
        NSArray<NSURL *> *tempURLs = [self copyFilesToTempDirectoryWithURLs:URLs error:&error];
        
        if (error != nil) {
            completionHandler(nil, nil, nil, nil, nil, error);
            return;
        }
        
        [self appendClipsFromURLs:tempURLs intoTrackID:self.audioTrackID progressHandler:progressHandler completionHandler:completionHandler];
    } else {
        [self appendClipsFromURLs:URLs intoTrackID:self.audioTrackID progressHandler:progressHandler completionHandler:completionHandler];
    }
}

- (void)removeAudioClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [self removeClipWithCompositionID:compositionID completionHandler:completionHandler];
}

@end
