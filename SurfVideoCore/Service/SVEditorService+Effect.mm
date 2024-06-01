//
//  SVEditorService+Effect.mm
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/2/24.
//

#import <SurfVideoCore/SVEditorService+Effect.hpp>
#import <SurfVideoCore/SVEditorService+Private.hpp>
#import <SurfVideoCore/SVEditorRenderEffect.hpp>

@implementation SVEditorService (Effect)

- (void)appendEffectWithName:(NSString *)effectName timeRange:(CMTimeRange)timeRange completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition * _Nullable composition = self.queue_composition;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        auto compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof SVEditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        
        [managedObjectContext performBlock:^{
            SVEffectTrack *effectTrack = [[SVEffectTrack alloc] initWithContext:managedObjectContext];
            [videoProject addEffectTracksObject:effectTrack];
            
            SVEffect *effect = [[SVEffect alloc] initWithContext:managedObjectContext];
            [effectTrack addEffectsObject:effect];
            [effectTrack release];
            
            NSUUID *effectID = [NSUUID UUID];
            effect.effectID = effectID;
            effect.effectName = effectName;
            effect.timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
            
            [effect release];
            
            NSError * _Nullable error = nil;
            [managedObjectContext save:&error];
            assert(!error);
            
            SVEditorRenderEffect *renderEffect = [[SVEditorRenderEffect alloc] initWithEffectName:effectName
                                                                                        timeRange:timeRange
                                                                                         effectID:effectID];
            
            [renderElements addObject:renderEffect];
            [renderEffect release];
            
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

- (void)removeEffect:(SVEditorRenderEffect *)effect completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        SVVideoProject *videoProject = self.queue_videoProject;
        AVComposition *composition = self.queue_composition;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSMutableArray<__kindof SVEditorRenderElement *> *renderElements = [self.queue_renderElements mutableCopy];
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVEffect *> *fetchRequest = [SVEffect fetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"effectID", effect.effectID]];
            fetchRequest.fetchLimit = 1;
            
            NSError * _Nullable error = nil;
            NSArray<SVEffect *> *effects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            assert(error == nil);
            
            SVEffect *cvEffect = effects.firstObject;
            assert(effect != nil);
            SVEffectTrack *effectTrack = cvEffect.effectTrack;
            
            [managedObjectContext deleteObject:cvEffect];
            [managedObjectContext deleteObject:effectTrack];
            
            [managedObjectContext save:&error];
            
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            //
            
            [renderElements removeObject:effect];
            
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

- (void)renderEffectsAtTime:(CMTime)time completionHandler:(void (^)(NSArray<SVEditorRenderEffect *> * _Nonnull))completionHandler {
    dispatch_async(self.queue_1, ^{
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            if (![evaluatedObject isKindOfClass:SVEditorRenderEffect.class]) return NO;
            
            SVEditorRenderEffect *renderEffect = evaluatedObject;
            return CMTimeRangeContainsTime(renderEffect.timeRange, time);
        }];
        
        NSArray<SVEditorRenderEffect *> *results = [self.queue_renderElements filteredArrayUsingPredicate:predicate];
        completionHandler(results);
    });
}

@end
