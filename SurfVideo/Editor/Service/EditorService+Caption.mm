//
//  EditorService+Caption.m
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService+Caption.hpp"
#import "EditorService+Private.hpp"

@implementation EditorService (Caption)

- (void)appendCaptionWithAttributedString:(NSAttributedString *)attributedString completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [managedObjectContext performBlock:^{
            SVCaptionTrack *captionTrack = self.queue_videoProject.captionTrack;
            
            SVCaption *caption = [[SVCaption alloc] initWithContext:managedObjectContext];
            
            NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
            [mutableAttributedString addAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} range:NSMakeRange(0, mutableAttributedString.length)];
            caption.attributedString = mutableAttributedString;
            [mutableAttributedString release];
            
            CMTime startTime = kCMTimeZero;
            CMTime endTime = self.queue_composition.duration;
            
            caption.startTimeValue = [NSValue valueWithCMTime:startTime];
            caption.endTimeValue = [NSValue valueWithCMTime:endTime];
            
            [captionTrack addCaptionsObject:caption];
            [caption release];
            
            NSError * _Nullable error = nil;
            [managedObjectContext save:&error];
            assert(!error);
            
            [self contextQueue_finalizeWithComposition:composition completionHandler:completionHandler];
        }];
    });
}

- (void)editCaption:(EditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [managedObjectContext performBlock:^{
            SVCaption *svCaption = [managedObjectContext objectWithID:caption.objectID];
            svCaption.attributedString = attributedString;
            
            if (CMTIME_IS_VALID(startTime)) {
                svCaption.startTimeValue = [NSValue valueWithCMTime:startTime];
            }
            
            if (CMTIME_IS_VALID(endTime)) {
                svCaption.endTimeValue = [NSValue valueWithCMTime:endTime];
            }
            
            NSError * _Nullable error = nil;
            [managedObjectContext save:&error];
            
            if (error) {
                completionHandler(nil, nil, nil, error);
                return;
            }
            
            [self contextQueue_finalizeWithComposition:composition completionHandler:completionHandler];
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
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithObjectIDs:@[caption.objectID]];
            deleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
            
            NSPersistentStoreCoordinator *persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator;
            NSError * _Nullable error = nil;
            NSBatchDeleteResult * _Nullable deleteResult = [persistentStoreCoordinator executeRequest:deleteRequest withContext:managedObjectContext error:&error];
            [deleteRequest release];
            
            auto deletedObjectIDs = static_cast<NSArray<NSManagedObjectID *> *>(deleteResult.result);
            assert(deletedObjectIDs.count == 1);
            assert([deletedObjectIDs[0] isEqual:caption.objectID]);
            
            [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectIDsKey: deletedObjectIDs} intoContexts:@[managedObjectContext]];
            
            if (error) {
                completionHandler(nil, nil, nil, error);
                return;
            }
            
            [self contextQueue_finalizeWithComposition:composition completionHandler:completionHandler];
        }];
    });
}

@end
