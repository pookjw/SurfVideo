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

- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        CMPersistentTrackID audioTrackID = self.audioTrackID;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        
        [self appendClipsToTrackFromURLs:URLs 
                                       trackID:audioTrackID
                            mutableComposition:mutableComposition 
                                 createFootage:YES
                            videoProject:videoProject
                               progressHandler:progressHandler
                             completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSURL *, NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            //
            
            NSMutableArray<NSUUID *> *sortedCreatedCompositionIDs = [[NSMutableArray alloc] initWithCapacity:createdCompositionIDs.count];
            
            for (NSURL *URL in URLs) {
                [createdCompositionIDs enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull _URL, NSUUID * _Nonnull compositionID, BOOL * _Nonnull stop) {
                    if ([URL isEqual:_URL]) {
                        [sortedCreatedCompositionIDs addObject:compositionID];
                        *stop = YES;
                    }
                }];
            }
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:mutableComposition
                                         compositionIDs:[self appendingCompositionIDArray:sortedCreatedCompositionIDs trackID:audioTrackID intoCompositionIDs:compositionIDs]
                                      trackSegmentNames:trackSegmentNames
                                         renderElements:renderElements
                                      completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable trackSegmentNames, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
                completionHandler(composition, videoComposition, renderElements, trackSegmentNames, compositionIDs, error);
                dispatch_resume(self.queue_1);
            }];
            
            [sortedCreatedCompositionIDs release];
        }];
        
        [mutableComposition release];
    });
}

- (void)removeAudioClipWithCompositionID:(NSUUID *)compositionID completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSManagedObjectContext *managedObjectContext = self.queue_videoProject.managedObjectContext;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        
        [self queue_removeTrackSegmentWithCompositionID:compositionID
                                     mutableComposition:mutableComposition
                                         compositionIDs:compositionIDs
                                      completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            [managedObjectContext sv_performBlock:^{
                [self contextQueue_finalizeWithVideoProject:videoProject
                                                composition:mutableComposition
                                             compositionIDs:compositionIDs
                                          trackSegmentNames:trackSegmentNames
                                             renderElements:renderElements
                                          completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable trackSegmentNames, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
                    completionHandler(composition, videoComposition, renderElements, trackSegmentNames, compositionIDs, error);
                    dispatch_resume(self.queue_1);
                }];
            }];
        }];
        
        [mutableComposition release];
    });
}

@end
