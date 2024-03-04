//
//  EditorService+AudioClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService+AudioClip.hpp"
#import "EditorService+Private.hpp"

@implementation EditorService (AudioClip)

- (void)appendAudioClipsToAudioTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults
                                  progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler 
                                completionHandler:(EditorServiceCompletionHandler)completionHandler {
    
}

- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        
        [self queue_appendClipsToTrackFromURLs:URLs 
                                       trackID:self.audioTrackID
                            mutableComposition:mutableComposition 
                                 createFootage:YES
                               progressHandler:progressHandler
                             completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, error);
                return;
            }
            
            [videoProject.managedObjectContext performBlock:^{
                [self contextQueue_finalizeWithComposition:mutableComposition videoProject:videoProject completionHandler:completionHandler];
            }];
        }];
        
        [mutableComposition release];
    });
}

- (void)removeAudioClipTrackSegment:(AVCompositionTrackSegment *)trackSegment completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *, NSArray *> *trackSegmentNames, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [self queue_removeTrackSegment:trackSegment trackID:self.audioTrackID mutableComposition:mutableComposition completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable) {
            [managedObjectContext performBlock:^{
                [self contextQueue_finalizeWithComposition:mutableComposition videoProject:videoProject completionHandler:completionHandler];
            }];
        }];
        
        [mutableComposition release];
    });
}

@end
