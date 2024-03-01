//
//  EditorService+VideoClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/29/24.
//

#import "EditorService+VideoClip.hpp"
#import "EditorService+Private.hpp"
#import "constants.hpp"

@implementation EditorService (VideoClip)

- (void)appendVideoClipsToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults 
                                      progressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                                    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        AVComposition * _Nullable composition = self.queue_composition;
        SVVideoProject *videoProject = self.queue_videoProject;
        
        if (!composition) {
            completionHandler(nil, nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotInitializedError userInfo:nil]);
            return;
        }
        
        AVMutableComposition *mutableComposition = [composition mutableCopy];
        
        [self queue_appendVideoClipsToMainVideoTrackFromPickerResults:pickerResults
                                               mutableComposition:mutableComposition
                                                    createFootage:YES
                                                  progressHandler:progressHandler
                                                completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
            [videoProject.managedObjectContext performBlock:^{
                [self contextQueue_finalizeWithComposition:mutableComposition completionHandler:completionHandler];
            }];
        }];
        
        [mutableComposition release];
    });
}

- (void)appendVideoClipsToMainVideoTrackFromURLs:(NSArray<NSURL *> *)URLs
                             progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler 
                           completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        
        [self queue_appendVideoClipsToMainVideoTrackFromURLs:URLs 
                                      mutableComposition:mutableComposition
                                           createFootage:YES
                                         progressHandler:progressHandler
                                       completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, error);
                return;
            }
            
            [videoProject.managedObjectContext performBlock:^{
                [self contextQueue_finalizeWithComposition:mutableComposition completionHandler:completionHandler];
            }];
        }];
        
        [mutableComposition release];
    });
}

@end
