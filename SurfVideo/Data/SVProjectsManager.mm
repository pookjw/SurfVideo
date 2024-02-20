//
//  SVProjectsManager.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import "SVProjectsManager.hpp"
#import "SVNSAttributedStringValueTransformer.hpp"
#import "SVNSValueValueTransformer.hpp"

__attribute__((objc_direct_members))
@interface SVProjectsManager ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) NSPersistentContainer * _Nullable persistentContainer;
@property (retain, readonly, nonatomic) NSManagedObjectContext * _Nullable managedObjectContext;
@property (readonly, nonatomic) NSManagedObjectModel *managedObjectModel_v0;
@end

@implementation SVProjectsManager

@synthesize persistentContainer = _persistentContainer;
@synthesize queue = _queue;
@synthesize managedObjectContext = _managedObjectContext;

+ (SVProjectsManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static SVProjectsManager *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [SVProjectsManager new];
    });
    
    return instance;
}

- (void)dealloc {
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [_persistentContainer release];
    [_managedObjectContext release];
    
    [super dealloc];
}

- (void)managedObjectContextWithCompletionHandler:(void (^)(NSManagedObjectContext * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        completionHandler(self.managedObjectContext);
    });
}

- (void)cleanupFootagesWithCompletionHandler:(void (^)(NSInteger cleanedUpFootagesCount, NSError * _Nullable error))completionHandler {
    [self managedObjectContextWithCompletionHandler:^(NSManagedObjectContext * _Nullable managedObjectContext) {
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVFootage *> *fetchReqeust = [SVFootage fetchRequest];
            fetchReqeust.predicate = [NSPredicate predicateWithFormat:@"%K <= 0" argumentArray:@[@"clipsCount"]];
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchReqeust];
            deleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
            
            NSPersistentStoreCoordinator *persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator;
            NSError * _Nullable error = nil;
            NSBatchDeleteResult * _Nullable deleteResult = [persistentStoreCoordinator executeRequest:deleteRequest withContext:managedObjectContext error:&error];
            [deleteRequest release];
            
            if (error) {
                completionHandler(NSNotFound, error);
                return;
            }
            
            auto deletedObjectIDs = static_cast<NSArray<NSManagedObjectID *> *>(deleteResult.result);
            completionHandler(deletedObjectIDs.count, nil);
        }];
    }];
}

- (dispatch_queue_t)queue {
    if (auto queue = _queue) return queue;
    
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("SVProjectsManager", attr);
    
    dispatch_retain(queue);
    _queue = queue;
    
    return [queue autorelease];
}

- (NSPersistentContainer *)persistentContainer {
    if (auto persistentContainer = _persistentContainer) return persistentContainer;
    
    [self registerValueTransformers];
    
    NSError * _Nullable error = nil;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSURL *applicationSupportURL = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    
    NSURL *rootURL = [applicationSupportURL URLByAppendingPathComponent:@"SVProjectsManager" isDirectory:YES];
    
    if (![fileManager fileExistsAtPath:rootURL.path isDirectory:nil]) {
        [fileManager createDirectoryAtURL:rootURL withIntermediateDirectories:YES attributes:nil error:&error];
        assert(!error);
    }
        
    NSURL *containerURL = [[rootURL URLByAppendingPathComponent:@"container" isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];
    
    NSLog(@"%@", containerURL);
    
    NSPersistentStoreDescription *persistentStoreDescription = [[NSPersistentStoreDescription alloc] initWithURL:containerURL];
    persistentStoreDescription.shouldAddStoreAsynchronously = NO;
    
    NSPersistentContainer *persistentContainer = [[NSPersistentContainer alloc] initWithName:@"v0" managedObjectModel:self.managedObjectModel_v0];
    
    [persistentContainer.persistentStoreCoordinator addPersistentStoreWithDescription:persistentStoreDescription completionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable _error) {
        assert(!error);
    }];
    [persistentStoreDescription release];
    
    _persistentContainer = [persistentContainer retain];
    return [persistentContainer autorelease];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (auto managedObjectContext = _managedObjectContext) return managedObjectContext;
    
    NSManagedObjectContext *managedObjectContext = [self.persistentContainer newBackgroundContext];
    
    _managedObjectContext = [managedObjectContext retain];
    return [managedObjectContext autorelease];
}

- (void)registerValueTransformers __attribute__((objc_direct)) {
    SVNSAttributedStringValueTransformer *nsAttributedStringValueTransformer = [SVNSAttributedStringValueTransformer new];
    [NSValueTransformer setValueTransformer:nsAttributedStringValueTransformer forName:SVNSAttributedStringValueTransformer.name];
    [nsAttributedStringValueTransformer release];
    
    SVNSValueValueTransformer *nsValueValueTransformer = [SVNSValueValueTransformer new];
    [NSValueTransformer setValueTransformer:nsValueValueTransformer forName:SVNSValueValueTransformer.name];
    [nsValueValueTransformer release];
}

- (NSManagedObjectModel *)managedObjectModel_v0 __attribute__((objc_direct)) {
    NSAttributeDescription *VideoProject_createdDateAttributeDescription = [NSAttributeDescription new];
    VideoProject_createdDateAttributeDescription.attributeType = NSDateAttributeType;
    VideoProject_createdDateAttributeDescription.optional = YES;
    VideoProject_createdDateAttributeDescription.transient = NO;
    VideoProject_createdDateAttributeDescription.name = @"createdDate";
    
    NSRelationshipDescription *VideoProject_mainVideoTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoProject_mainVideoTrackRelationshipDescription.optional = YES;
    VideoProject_mainVideoTrackRelationshipDescription.transient = NO;
    VideoProject_mainVideoTrackRelationshipDescription.name = @"mainVideoTrack";
    VideoProject_mainVideoTrackRelationshipDescription.minCount = 0;
    VideoProject_mainVideoTrackRelationshipDescription.maxCount = 1;
    VideoProject_mainVideoTrackRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *VideoProject_captionTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoProject_captionTrackRelationshipDescription.optional = YES;
    VideoProject_captionTrackRelationshipDescription.transient = NO;
    VideoProject_captionTrackRelationshipDescription.name = @"captionTrack";
    VideoProject_captionTrackRelationshipDescription.minCount = 0;
    VideoProject_captionTrackRelationshipDescription.maxCount = 1;
    VideoProject_captionTrackRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    //
    
    NSDerivedAttributeDescription *VideoTrack_videoClipsCountAttributeDescription = [NSDerivedAttributeDescription new];
    VideoTrack_videoClipsCountAttributeDescription.attributeType = NSInteger64AttributeType;
    VideoTrack_videoClipsCountAttributeDescription.optional = YES;
    VideoTrack_videoClipsCountAttributeDescription.transient = NO;
    VideoTrack_videoClipsCountAttributeDescription.name = @"videoClipsCount";
    VideoTrack_videoClipsCountAttributeDescription.derivationExpression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"videoClips"]]];
    
    NSRelationshipDescription *VideoTrack_videoClipsRelationshipDescription = [NSRelationshipDescription new];
    VideoTrack_videoClipsRelationshipDescription.optional = YES;
    VideoTrack_videoClipsRelationshipDescription.transient = NO;
    VideoTrack_videoClipsRelationshipDescription.name = @"videoClips";
    VideoTrack_videoClipsRelationshipDescription.minCount = 0;
    VideoTrack_videoClipsRelationshipDescription.maxCount = 0;
    VideoTrack_videoClipsRelationshipDescription.ordered = YES;
    VideoTrack_videoClipsRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *VideoTrack_videoProjectRelationshipDescription = [NSRelationshipDescription new];
    VideoTrack_videoProjectRelationshipDescription.optional = YES;
    VideoTrack_videoProjectRelationshipDescription.transient = NO;
    VideoTrack_videoProjectRelationshipDescription.name = @"videoProject";
    VideoTrack_videoProjectRelationshipDescription.minCount = 0;
    VideoTrack_videoProjectRelationshipDescription.maxCount = 1;
    VideoTrack_videoProjectRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSRelationshipDescription *CaptionTrack_captionsRelationshipDescription = [NSRelationshipDescription new];
    CaptionTrack_captionsRelationshipDescription.optional = YES;
    CaptionTrack_captionsRelationshipDescription.transient = NO;
    CaptionTrack_captionsRelationshipDescription.name = @"captions";
    CaptionTrack_captionsRelationshipDescription.minCount = 0;
    CaptionTrack_captionsRelationshipDescription.maxCount = 0;
    CaptionTrack_captionsRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *CaptionTrack_videoProjectRelationshipDescription = [NSRelationshipDescription new];
    CaptionTrack_videoProjectRelationshipDescription.optional = YES;
    CaptionTrack_videoProjectRelationshipDescription.transient = NO;
    CaptionTrack_videoProjectRelationshipDescription.name = @"videoProject";
    CaptionTrack_videoProjectRelationshipDescription.minCount = 0;
    CaptionTrack_videoProjectRelationshipDescription.maxCount = 1;
    CaptionTrack_videoProjectRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSRelationshipDescription *VideoClip_videoTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoClip_videoTrackRelationshipDescription.optional = YES;
    VideoClip_videoTrackRelationshipDescription.transient = NO;
    VideoClip_videoTrackRelationshipDescription.name = @"videoTrack";
    VideoClip_videoTrackRelationshipDescription.minCount = 0;
    VideoClip_videoTrackRelationshipDescription.maxCount = 1;
    VideoClip_videoTrackRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSRelationshipDescription *Clip_footageRelationshipDescription = [NSRelationshipDescription new];
    Clip_footageRelationshipDescription.optional = YES;
    Clip_footageRelationshipDescription.transient = NO;
    Clip_footageRelationshipDescription.name = @"footage";
    Clip_footageRelationshipDescription.minCount = 0;
    Clip_footageRelationshipDescription.maxCount = 1;
    Clip_footageRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSAttributeDescription *Caption_attributedStringAttributeDescription = [NSAttributeDescription new];
    Caption_attributedStringAttributeDescription.attributeType = NSTransformableAttributeType;
    Caption_attributedStringAttributeDescription.optional = YES;
    Caption_attributedStringAttributeDescription.transient = NO;
    Caption_attributedStringAttributeDescription.name = @"attributedString";
    Caption_attributedStringAttributeDescription.valueTransformerName = SVNSAttributedStringValueTransformer.name;
    
    NSAttributeDescription *Caption_startTimeValueAttributeDescription = [NSAttributeDescription new];
    Caption_startTimeValueAttributeDescription.attributeType = NSTransformableAttributeType;
    Caption_startTimeValueAttributeDescription.optional = YES;
    Caption_startTimeValueAttributeDescription.transient = NO;
    Caption_startTimeValueAttributeDescription.name = @"startTimeValue";
    Caption_startTimeValueAttributeDescription.valueTransformerName = SVNSValueValueTransformer.name;
    
    NSAttributeDescription *Caption_endTimeValueAttributeDescription = [NSAttributeDescription new];
    Caption_endTimeValueAttributeDescription.attributeType = NSTransformableAttributeType;
    Caption_endTimeValueAttributeDescription.optional = YES;
    Caption_endTimeValueAttributeDescription.transient = NO;
    Caption_endTimeValueAttributeDescription.name = @"endTimeValue";
    Caption_endTimeValueAttributeDescription.valueTransformerName = SVNSValueValueTransformer.name;
    
    NSRelationshipDescription *Caption_captionTrackRelationshipDescription = [NSRelationshipDescription new];
    Caption_captionTrackRelationshipDescription.optional = YES;
    Caption_captionTrackRelationshipDescription.transient = NO;
    Caption_captionTrackRelationshipDescription.name = @"captionTrack";
    Caption_captionTrackRelationshipDescription.minCount = 0;
    Caption_captionTrackRelationshipDescription.maxCount = 1;
    Caption_captionTrackRelationshipDescription.ordered = NO;
    Caption_captionTrackRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSAttributeDescription *PHAsset_assetIdentifierAttributeDescription = [NSAttributeDescription new];
    PHAsset_assetIdentifierAttributeDescription.attributeType = NSStringAttributeType;
    PHAsset_assetIdentifierAttributeDescription.optional = YES;
    PHAsset_assetIdentifierAttributeDescription.transient = NO;
    PHAsset_assetIdentifierAttributeDescription.name = @"assetIdentifier";
    
    NSRelationshipDescription *Footage_clipsRelationshipDescription = [NSRelationshipDescription new];
    Footage_clipsRelationshipDescription.optional = YES;
    Footage_clipsRelationshipDescription.transient = NO;
    Footage_clipsRelationshipDescription.name = @"clips";
    Footage_clipsRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    NSDerivedAttributeDescription *Footage_clipsCountDerivedAttributeDescription = [NSDerivedAttributeDescription new];
    Footage_clipsCountDerivedAttributeDescription.attributeType = NSInteger64AttributeType;
    Footage_clipsCountDerivedAttributeDescription.optional = YES;
    Footage_clipsCountDerivedAttributeDescription.transient = NO;
    Footage_clipsCountDerivedAttributeDescription.name = @"clipsCount";
    Footage_clipsCountDerivedAttributeDescription.derivationExpression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"clips"]]];
    
    //
    
    VideoProject_mainVideoTrackRelationshipDescription.inverseRelationship = VideoTrack_videoProjectRelationshipDescription;
    VideoProject_captionTrackRelationshipDescription.inverseRelationship = CaptionTrack_videoProjectRelationshipDescription;
    VideoTrack_videoClipsRelationshipDescription.inverseRelationship = VideoClip_videoTrackRelationshipDescription;
    VideoTrack_videoProjectRelationshipDescription.inverseRelationship = VideoProject_mainVideoTrackRelationshipDescription;
    CaptionTrack_captionsRelationshipDescription.inverseRelationship = Caption_captionTrackRelationshipDescription;
    Clip_footageRelationshipDescription.inverseRelationship = Footage_clipsRelationshipDescription;
    VideoClip_videoTrackRelationshipDescription.inverseRelationship = VideoTrack_videoClipsRelationshipDescription;
    Footage_clipsRelationshipDescription.inverseRelationship = Clip_footageRelationshipDescription;
    
    //
    
    NSEntityDescription *videoProjectEntityDescription = [NSEntityDescription new];
    videoProjectEntityDescription.name = @"VideoProject";
    videoProjectEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoProject.class);
    
    NSEntityDescription *videoTrackEntityDescription = [NSEntityDescription new];
    videoTrackEntityDescription.name = @"VideoTrack";
    videoTrackEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoTrack.class);
    
    NSEntityDescription *captionTrackEntityDescription = [NSEntityDescription new];
    captionTrackEntityDescription.name = @"CaptionTrack";
    captionTrackEntityDescription.managedObjectClassName = NSStringFromClass(SVCaptionTrack.class);
    
    NSEntityDescription *trackEntityDescription = [NSEntityDescription new];
    trackEntityDescription.name = @"Track";
    trackEntityDescription.managedObjectClassName = NSStringFromClass(SVTrack.class);
    trackEntityDescription.abstract = YES;
    trackEntityDescription.subentities = @[videoTrackEntityDescription, captionTrackEntityDescription];
    
    NSEntityDescription *videoClipEntityDescription = [NSEntityDescription new];
    videoClipEntityDescription.name = @"VideoClip";
    videoClipEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoClip.class);
    
    NSEntityDescription *clipEntityDescription = [NSEntityDescription new];
    clipEntityDescription.name = @"Clip";
    clipEntityDescription.managedObjectClassName = NSStringFromClass(SVClip.class);
    clipEntityDescription.abstract = YES;
    clipEntityDescription.subentities = @[videoClipEntityDescription];
    
    NSEntityDescription *captionEntityDescription = [NSEntityDescription new];
    captionEntityDescription.name = @"Caption";
    captionEntityDescription.managedObjectClassName = NSStringFromClass(SVCaption.class);
    
    NSEntityDescription *phAssetFootageEntityDescription = [NSEntityDescription new];
    phAssetFootageEntityDescription.name = @"PHAssetFootage";
    phAssetFootageEntityDescription.managedObjectClassName = NSStringFromClass(SVPHAssetFootage.class);
    
    NSEntityDescription *footageEntityDescription = [NSEntityDescription new];
    footageEntityDescription.name = @"Footage";
    footageEntityDescription.managedObjectClassName = NSStringFromClass(SVFootage.class);
    footageEntityDescription.abstract = YES;
    footageEntityDescription.subentities = @[phAssetFootageEntityDescription];
    
    //
    
    VideoProject_mainVideoTrackRelationshipDescription.destinationEntity = videoTrackEntityDescription;
    VideoProject_captionTrackRelationshipDescription.destinationEntity = captionTrackEntityDescription;
    VideoTrack_videoClipsRelationshipDescription.destinationEntity = videoClipEntityDescription;
    VideoTrack_videoProjectRelationshipDescription.destinationEntity = videoProjectEntityDescription;
    CaptionTrack_captionsRelationshipDescription.destinationEntity = captionEntityDescription;
    CaptionTrack_videoProjectRelationshipDescription.destinationEntity = videoProjectEntityDescription;
    VideoClip_videoTrackRelationshipDescription.destinationEntity = videoTrackEntityDescription;
    Clip_footageRelationshipDescription.destinationEntity = footageEntityDescription;
    Caption_captionTrackRelationshipDescription.destinationEntity = captionTrackEntityDescription;
    Footage_clipsRelationshipDescription.destinationEntity = clipEntityDescription;
    
    //
    
    videoProjectEntityDescription.properties = @[
        VideoProject_createdDateAttributeDescription,
        VideoProject_mainVideoTrackRelationshipDescription,
        VideoProject_captionTrackRelationshipDescription
    ];
    
    videoTrackEntityDescription.properties = @[
        VideoTrack_videoClipsCountAttributeDescription,
        VideoTrack_videoClipsRelationshipDescription,
        VideoTrack_videoProjectRelationshipDescription
    ];
    
    captionTrackEntityDescription.properties = @[
        CaptionTrack_captionsRelationshipDescription,
        CaptionTrack_videoProjectRelationshipDescription
    ];
    
    videoClipEntityDescription.properties = @[
        VideoClip_videoTrackRelationshipDescription
    ];
    
    captionEntityDescription.properties = @[
        Caption_attributedStringAttributeDescription,
        Caption_startTimeValueAttributeDescription,
        Caption_endTimeValueAttributeDescription,
        Caption_captionTrackRelationshipDescription
    ];
    
    clipEntityDescription.properties = @[
        Clip_footageRelationshipDescription
    ];
    
    phAssetFootageEntityDescription.properties = @[
        PHAsset_assetIdentifierAttributeDescription
    ];
    
    footageEntityDescription.properties = @[
        Footage_clipsRelationshipDescription,
        Footage_clipsCountDerivedAttributeDescription
    ];
    
    //
    
    [VideoProject_createdDateAttributeDescription release];
    [VideoProject_mainVideoTrackRelationshipDescription release];
    [VideoProject_captionTrackRelationshipDescription release];
    [VideoTrack_videoClipsCountAttributeDescription release];
    [VideoTrack_videoClipsRelationshipDescription release];
    [VideoTrack_videoProjectRelationshipDescription release];
    [CaptionTrack_captionsRelationshipDescription release];
    [CaptionTrack_videoProjectRelationshipDescription release];
    [VideoClip_videoTrackRelationshipDescription release];
    [Clip_footageRelationshipDescription release];
    [Caption_attributedStringAttributeDescription release];
    [Caption_startTimeValueAttributeDescription release];
    [Caption_endTimeValueAttributeDescription release];
    [Caption_captionTrackRelationshipDescription release];
    [PHAsset_assetIdentifierAttributeDescription release];
    [Footage_clipsRelationshipDescription release];
    [Footage_clipsCountDerivedAttributeDescription release];
    
    //
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    managedObjectModel.entities = @[
        videoProjectEntityDescription,
        videoTrackEntityDescription,
        captionTrackEntityDescription,
        trackEntityDescription,
        videoClipEntityDescription,
        clipEntityDescription,
        captionEntityDescription,
        phAssetFootageEntityDescription,
        footageEntityDescription
    ];
    
    [videoProjectEntityDescription release];
    [videoTrackEntityDescription release];
    [captionTrackEntityDescription release];
    [trackEntityDescription release];
    [videoClipEntityDescription release];
    [clipEntityDescription release];
    [captionEntityDescription release];
    [phAssetFootageEntityDescription release];
    [footageEntityDescription release];
    
    return [managedObjectModel autorelease];
}

@end
