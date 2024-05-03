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
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVComposition * _Nullable composition = self.queue_composition;
        
        if (!composition) {
            completionHandler(nil, nil, nil, nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotInitializedError userInfo:nil]);
            dispatch_resume(self.queue_1);
            return;
        }
        
        AVMutableComposition *mutableComposition = [composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        CMPersistentTrackID mainVideoTrackID = self.mainVideoTrackID;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        
        [self appendClipsToTrackFromPickerResults:pickerResults
                                          trackID:mainVideoTrackID
                               mutableComposition:mutableComposition
                                    createFootage:YES
                                     videoProject:videoProject
                                  progressHandler:progressHandler
                                completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> * _Nullable createdCompositionIDs, NSDictionary<NSNumber *, NSString *> * _Nullable titlesByTrackSegmentIndex, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            //
            
            NSMutableArray<NSUUID *> *sortedCreatedCompositionIDs = [[NSMutableArray alloc] initWithCapacity:createdCompositionIDs.count];
            
            for (PHPickerResult *pickerResult in pickerResults) {
                [createdCompositionIDs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull assetIdentifier, NSUUID * _Nonnull compositionID, BOOL * _Nonnull stop) {
                    if ([pickerResult.assetIdentifier isEqualToString:assetIdentifier]) {
                        [sortedCreatedCompositionIDs addObject:compositionID];
                        *stop = YES;
                    }
                }];
            }
            
            //
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:mutableComposition
                                         compositionIDs:[self appendingCompositionIDArray:sortedCreatedCompositionIDs trackID:mainVideoTrackID intoCompositionIDs:compositionIDs]
                                      trackSegmentNames:[self appendingTrackSegmentNames:titlesByTrackSegmentIndex trackID:self.mainVideoTrackID intoTrackSegmentNames:trackSegmentNames]
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

- (void)appendVideoClipsToMainVideoTrackFromURLs:(NSArray<NSURL *> *)URLs
                                 progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler 
                               completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [self appendClipsFromURLs:URLs intoTrackID:self.mainVideoTrackID progressHandler:progressHandler completionHandler:completionHandler];
}

- (void)removeVideoClipWithCompositionID:(NSUUID *)compositionID completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable, NSError * _Nullable))completionHandler {
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
            
            [managedObjectContext performBlock:^{
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
