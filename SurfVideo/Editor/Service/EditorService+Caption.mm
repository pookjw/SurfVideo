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
            
            [self contextQueue_finalizeWithComposition:composition
                                        compositionIDs:compositionIDs
                                        renderElements:renderElements
                                          videoProject:videoProject
                                     completionHandler:completionHandler];
        }];
        
        [renderElements release];
    });
}

- (void)editCaption:(EditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVCaption *> *fetchRequest = [SVCaption fetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"captionID", caption.captionID]];
            
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
            
            [self contextQueue_finalizeWithComposition:composition videoProject:videoProject completionHandler:completionHandler];
        }];
    });
}

- (void)removeCaption:(EditorRenderCaption *)caption 
    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition *composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVCaption *> *fetchRequest = [SVCaption fetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"captionID", caption.captionID]];
            
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
            deleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
            
            NSPersistentStoreCoordinator *persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator;
            NSError * _Nullable error = nil;
            NSBatchDeleteResult * _Nullable deleteResult = [persistentStoreCoordinator executeRequest:deleteRequest withContext:managedObjectContext error:&error];
            [deleteRequest release];
            
            auto deletedObjectIDs = static_cast<NSArray<NSManagedObjectID *> *>(deleteResult.result);
            assert(deletedObjectIDs.count == 1);
            
            [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectIDsKey: deletedObjectIDs} intoContexts:@[managedObjectContext]];
            
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                return;
            }
            
            [self contextQueue_finalizeWithComposition:composition videoProject:videoProject completionHandler:completionHandler];
        }];
    });
}

@end
