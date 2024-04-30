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

- (void)appendAudioClipsToVideoTrackFromURLs:(NSArray<NSURL *> *)URLs progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        CMPersistentTrackID audioTrackID = self.audioTrackID;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        
        [self queue_appendClipsToTrackFromURLs:URLs 
                                       trackID:audioTrackID
                            mutableComposition:mutableComposition 
                                 createFootage:YES
                               progressHandler:progressHandler
                             completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSURL *, NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
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
            
            [self contextQueue_finalizeWithComposition:mutableComposition 
                                        compositionIDs:[self appendingCompositionIDArray:sortedCreatedCompositionIDs trackID:audioTrackID intoCompositionIDs:compositionIDs]
                                        renderElements:renderElements
                                          videoProject:videoProject
                                     completionHandler:completionHandler];
            
            [sortedCreatedCompositionIDs release];
        }];
        
        [mutableComposition release];
    });
}

- (void)removeAudioClipWithCompositionID:(NSUUID *)compositionID completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        abort();
    });
}

- (void)removeAudioClipTrackSegment:(AVCompositionTrackSegment *)trackSegment completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable))completionHandler {
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
