//
//  SVEditorService+Caption.m
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/SVEditorService+Caption.hpp>
#import <SurfVideoCore/SVEditorService+Private.hpp>
#import <SurfVideoCore/SVEditorRenderCaption.hpp>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@implementation SVEditorService (Caption)

- (void)appendCaptionWithAttributedString:(NSAttributedString *)attributedString completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        auto compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof SVEditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        
        [managedObjectContext performBlock:^{
            SVCaptionTrack *captionTrack = videoProject.captionTrack;
            
            SVCaption *caption = [[SVCaption alloc] initWithContext:managedObjectContext];
            
            NSUUID *captionID = [NSUUID UUID];
            caption.captionID = captionID;
            
            NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
#if TARGET_OS_IPHONE
            [mutableAttributedString addAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} range:NSMakeRange(0, mutableAttributedString.length)];
#else
            [mutableAttributedString addAttributes:@{NSForegroundColorAttributeName: NSColor.whiteColor} range:NSMakeRange(0, mutableAttributedString.length)];
#endif
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
            
            SVEditorRenderCaption *renderCaption = [[SVEditorRenderCaption alloc] initWithAttributedString:attributedString startTime:startTime endTime:endTime captionID:captionID];
            [renderElements addObject:renderCaption];
            [renderCaption release];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:composition
                                         compositionIDs:compositionIDs
                       trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                         renderElements:renderElements
                                      completionHandler:EditorServiceCompletionHandlerBlock {
                if (completionHandler) {
                    completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, error);
                }
                
                dispatch_resume(self.queue_1);
            }];
        }];
        
        [renderElements release];
    });
}

- (void)editCaption:(SVEditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof SVEditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVCaption *> *fetchRequest = [SVCaption fetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"captionID", caption.captionID]];
            fetchRequest.fetchLimit = 1;
            
            NSError * _Nullable error = nil;
            NSArray<SVCaption *> *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
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
                dispatch_resume(self.queue_1);
                return;
            }
            
            //
            
            __block NSInteger renderElementsIndex = NSNotFound;
            [renderElements enumerateObjectsUsingBlock:^(__kindof SVEditorRenderElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj isKindOfClass:[SVEditorRenderCaption class]]) return;
                
                SVEditorRenderCaption *renderCaption = obj;
                
                if ([renderCaption.captionID isEqual:caption.captionID]) {
                    renderElementsIndex = idx;
                    *stop = YES;
                }
            }];
            
            assert(renderElementsIndex != NSNotFound);
            [renderElements removeObjectAtIndex:renderElementsIndex];
            
            SVEditorRenderCaption *newRenderCaption = [[SVEditorRenderCaption alloc] initWithAttributedString:svCaption.attributedString
                                                                                                startTime:svCaption.startTimeValue.CMTimeValue
                                                                                                  endTime:svCaption.endTimeValue.CMTimeValue
                                                                                                captionID:svCaption.captionID];
            
            [renderElements insertObject:newRenderCaption atIndex:renderElementsIndex];
            [newRenderCaption release];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:composition
                                         compositionIDs:compositionIDs
                       trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                         renderElements:renderElements
                                      completionHandler:EditorServiceCompletionHandlerBlock {
                completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, error);
                dispatch_resume(self.queue_1);
            }];
        }];
        
        [renderElements release];
    });
}

- (void)removeCaption:(SVEditorRenderCaption *)caption
    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition *composition = self.queue_composition;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof SVEditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        
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
                dispatch_resume(self.queue_1);
                return;
            }
            
            //
            
            [renderElements removeObject:caption];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:composition
                                         compositionIDs:compositionIDs
                       trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                         renderElements:renderElements
                                      completionHandler:EditorServiceCompletionHandlerBlock {
                completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, error);
                dispatch_resume(self.queue_1);
            }];
        }];
        
        [renderElements release];
    });
}

@end
