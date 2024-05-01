//
//  EditorService+Caption.m
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService+Caption.hpp"
#import "EditorService+Private.hpp"
#import "EditorRenderCaption.hpp"

@implementation EditorService (Caption)

- (void)appendCaptionWithAttributedString:(NSAttributedString *)attributedString completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        auto compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof EditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        
        [managedObjectContext performBlock:^{
            SVCaptionTrack *captionTrack = videoProject.captionTrack;
            
            SVCaption *caption = [[SVCaption alloc] initWithContext:managedObjectContext];
            
            NSUUID *captionID = [NSUUID UUID];
            caption.captionID = captionID;
            
            NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
            [mutableAttributedString addAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} range:NSMakeRange(0, mutableAttributedString.length)];
            caption.attributedString = mutableAttributedString;
            [mutableAttributedString release];
            
            CMTime startTime = kCMTimeZero;
            CMTime endTime = composition.duration;
            
            caption.startTimeValue = [NSValue valueWithCMTime:startTime];
            caption.endTimeValue = [NSValue valueWithCMTime:endTime];
            
            [captionTrack addCaptionsObject:caption];
            [caption release];
            
            NSError * _Nullable error = nil;
            [managedObjectContext save:&error];
            assert(!error);
            
            EditorRenderCaption *renderCaption = [[EditorRenderCaption alloc] initWithAttributedString:attributedString startTime:startTime endTime:endTime captionID:captionID];
            [renderElements addObject:renderCaption];
            [renderCaption release];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:composition
                                         compositionIDs:compositionIDs
                                      trackSegmentNames:trackSegmentNames
                                         renderElements:renderElements
                                      completionHandler:completionHandler];
        }];
        
        [renderElements release];
    });
}

- (void)editCaption:(EditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof EditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVCaption *> *fetchRequest = [SVCaption fetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"captionID", caption.captionID]];
            fetchRequest.fetchLimit = 1;
            
            NSError * _Nullable error = nil;
            NSArray<SVCaption *> *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                return;
            }
            
            assert(fetchedObjects.count == 1);
            
            SVCaption *svCaption = fetchedObjects.firstObject;
            svCaption.attributedString = attributedString;
            
            if (CMTIME_IS_VALID(startTime)) {
                svCaption.startTimeValue = [NSValue valueWithCMTime:startTime];
            }
            
            if (CMTIME_IS_VALID(endTime)) {
                svCaption.endTimeValue = [NSValue valueWithCMTime:endTime];
            }
            
            [managedObjectContext save:&error];
            
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                return;
            }
            
            //
            
            __block NSInteger renderElementsIndex = NSNotFound;
            [renderElements enumerateObjectsUsingBlock:^(__kindof EditorRenderElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj isKindOfClass:[EditorRenderCaption class]]) return;
                
                EditorRenderCaption *renderCaption = obj;
                
                if ([renderCaption.captionID isEqual:caption.captionID]) {
                    renderElementsIndex = idx;
                    *stop = YES;
                }
            }];
            
            assert(renderElementsIndex != NSNotFound);
            [renderElements removeObjectAtIndex:renderElementsIndex];
            
            EditorRenderCaption *newRenderCaption = [[EditorRenderCaption alloc] initWithAttributedString:svCaption.attributedString
                                                                                                startTime:svCaption.startTimeValue.CMTimeValue
                                                                                                  endTime:svCaption.endTimeValue.CMTimeValue
                                                                                                captionID:svCaption.captionID];
            
            [renderElements insertObject:newRenderCaption atIndex:renderElementsIndex];
            [newRenderCaption release];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:composition
                                         compositionIDs:compositionIDs
                                      trackSegmentNames:trackSegmentNames
                                         renderElements:renderElements
                                      completionHandler:completionHandler];
        }];
        
        [renderElements release];
    });
}

- (void)removeCaption:(EditorRenderCaption *)caption
    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition *composition = self.queue_composition;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof EditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVCaption *> *fetchRequest = [SVCaption fetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"captionID", caption.captionID]];
            fetchRequest.fetchLimit = 1;
            
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
            deleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
            
            NSPersistentStoreCoordinator *persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator;
            NSError * _Nullable error = nil;
            NSBatchDeleteResult * _Nullable deleteResult = [persistentStoreCoordinator executeRequest:deleteRequest withContext:managedObjectContext error:&error];
            [deleteRequest release];
            
            auto deletedObjectIDs = static_cast<NSArray<NSManagedObjectID *> *>(deleteResult.result);
            assert(deletedObjectIDs.count == 1);
            
            [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey: deletedObjectIDs} intoContexts:@[managedObjectContext]];
            
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                return;
            }
            
            //
            
            __block NSInteger renderElementsIndex = NSNotFound;
            [renderElements enumerateObjectsUsingBlock:^(__kindof EditorRenderElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj isKindOfClass:[EditorRenderCaption class]]) return;
                
                EditorRenderCaption *renderCaption = obj;
                
                if ([renderCaption.captionID isEqual:caption.captionID]) {
                    renderElementsIndex = idx;
                    *stop = YES;
                }
            }];
            
            assert(renderElementsIndex != NSNotFound);
            [renderElements removeObjectAtIndex:renderElementsIndex];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:composition
                                         compositionIDs:compositionIDs
                                      trackSegmentNames:trackSegmentNames
                                         renderElements:renderElements
                                      completionHandler:completionHandler];
        }];
        
        [renderElements release];
    });
}

@end
