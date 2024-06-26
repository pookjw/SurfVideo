//
//  NSManagedObjectModel+SVObjectModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/28/24.
//

#import <SurfVideoCore/NSManagedObjectModel+SVObjectModel.hpp>
#import <SurfVideoCore/SVNSAttributedStringValueTransformer.hpp>
#import <SurfVideoCore/SVNSValueValueTransformer.hpp>
#import <SurfVideoCore/SVVideoProject.hpp>
#import <SurfVideoCore/SVVideoTrack.hpp>
#import <SurfVideoCore/SVAudioTrack.hpp>
#import <SurfVideoCore/SVCaptionTrack.hpp>
#import <SurfVideoCore/SVTrack.hpp>
#import <SurfVideoCore/SVVideoClip.hpp>
#import <SurfVideoCore/SVAudioClip.hpp>
#import <SurfVideoCore/SVClip.hpp>
#import <SurfVideoCore/SVCaption.hpp>
#import <SurfVideoCore/SVPHAssetFootage.hpp>
#import <SurfVideoCore/SVLocalFileFootage.hpp>
#import <SurfVideoCore/SVFootage.hpp>

@implementation NSManagedObjectModel (SVObjectModel)

+ (NSManagedObjectModel *)sv_projectsObjectModel_current {
    return [NSManagedObjectModel sv_projectsObjectModel_v1];
}

+ (NSManagedObjectModel *)sv_projectsObjectModel_v1 {
    NSURL *bundleURL = [NSBundle bundleForClass:[SVVideoProject class]].resourceURL;
    NSURL *projectsModelMomdURL = [bundleURL URLByAppendingPathComponent:@"ProjectsModel.momd" isDirectory:YES];
    NSURL *projectsModel_v0_URL = [projectsModelMomdURL URLByAppendingPathComponent:@"ProjectsModel_v1.mom" isDirectory:NO];
    
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:projectsModel_v0_URL];
    return [managedObjectModel autorelease];
}

+ (NSManagedObjectModel *)sv_projectsObjectModel_v0 {
    NSAttributeDescription *VideoProject_createdDateAttributeDescription = [NSAttributeDescription new];
    VideoProject_createdDateAttributeDescription.attributeType = NSDateAttributeType;
    VideoProject_createdDateAttributeDescription.optional = YES;
    VideoProject_createdDateAttributeDescription.transient = NO;
    VideoProject_createdDateAttributeDescription.name = @"createdDate";
    
    NSRelationshipDescription *VideoProject_videoTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoProject_videoTrackRelationshipDescription.optional = YES;
    VideoProject_videoTrackRelationshipDescription.transient = NO;
    VideoProject_videoTrackRelationshipDescription.name = @"videoTrack";
    VideoProject_videoTrackRelationshipDescription.minCount = 0;
    VideoProject_videoTrackRelationshipDescription.maxCount = 1;
    VideoProject_videoTrackRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *VideoProject_audioTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoProject_audioTrackRelationshipDescription.optional = YES;
    VideoProject_audioTrackRelationshipDescription.transient = NO;
    VideoProject_audioTrackRelationshipDescription.name = @"audioTrack";
    VideoProject_audioTrackRelationshipDescription.minCount = 0;
    VideoProject_audioTrackRelationshipDescription.maxCount = 1;
    VideoProject_audioTrackRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *VideoProject_captionTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoProject_captionTrackRelationshipDescription.optional = YES;
    VideoProject_captionTrackRelationshipDescription.transient = NO;
    VideoProject_captionTrackRelationshipDescription.name = @"captionTrack";
    VideoProject_captionTrackRelationshipDescription.minCount = 0;
    VideoProject_captionTrackRelationshipDescription.maxCount = 1;
    VideoProject_captionTrackRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSAttributeDescription *VideoProject_thumbnailImageTIFFDataAttributeDescription = [NSAttributeDescription new];
    VideoProject_thumbnailImageTIFFDataAttributeDescription.attributeType = NSBinaryDataAttributeType;
    VideoProject_thumbnailImageTIFFDataAttributeDescription.optional = YES;
    VideoProject_thumbnailImageTIFFDataAttributeDescription.transient = NO;
    VideoProject_thumbnailImageTIFFDataAttributeDescription.name = @"thumbnailImageTIFFData";
    VideoProject_thumbnailImageTIFFDataAttributeDescription.allowsExternalBinaryDataStorage = YES;
    
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
    
    NSDerivedAttributeDescription *AudioTrack_audioClipsCountAttributeDescription = [NSDerivedAttributeDescription new];
    AudioTrack_audioClipsCountAttributeDescription.attributeType = NSInteger64AttributeType;
    AudioTrack_audioClipsCountAttributeDescription.optional = YES;
    AudioTrack_audioClipsCountAttributeDescription.transient = NO;
    AudioTrack_audioClipsCountAttributeDescription.name = @"audioClipsCount";
    AudioTrack_audioClipsCountAttributeDescription.derivationExpression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"audioClips"]]];
    
    NSRelationshipDescription *AudioTrack_audioClipsRelationshipDescription = [NSRelationshipDescription new];
    AudioTrack_audioClipsRelationshipDescription.optional = YES;
    AudioTrack_audioClipsRelationshipDescription.transient = NO;
    AudioTrack_audioClipsRelationshipDescription.name = @"audioClips";
    AudioTrack_audioClipsRelationshipDescription.minCount = 0;
    AudioTrack_audioClipsRelationshipDescription.maxCount = 0;
    AudioTrack_audioClipsRelationshipDescription.ordered = YES;
    AudioTrack_audioClipsRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *AudioTrack_videoProjectRelationshipDescription = [NSRelationshipDescription new];
    AudioTrack_videoProjectRelationshipDescription.optional = YES;
    AudioTrack_videoProjectRelationshipDescription.transient = NO;
    AudioTrack_videoProjectRelationshipDescription.name = @"videoProject";
    AudioTrack_videoProjectRelationshipDescription.minCount = 0;
    AudioTrack_videoProjectRelationshipDescription.maxCount = 1;
    AudioTrack_videoProjectRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSDerivedAttributeDescription *CaptionTrack_captionsCountAttributeDescription = [NSDerivedAttributeDescription new];
    CaptionTrack_captionsCountAttributeDescription.attributeType = NSInteger64AttributeType;
    CaptionTrack_captionsCountAttributeDescription.optional = YES;
    CaptionTrack_captionsCountAttributeDescription.transient = NO;
    CaptionTrack_captionsCountAttributeDescription.name = @"captionsCount";
    CaptionTrack_captionsCountAttributeDescription.derivationExpression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"captions"]]];
    
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
    
    NSAttributeDescription *AudioClip_startTimeValueAttributeDescription = [NSAttributeDescription new];
    AudioClip_startTimeValueAttributeDescription.attributeType = NSTransformableAttributeType;
    AudioClip_startTimeValueAttributeDescription.optional = YES;
    AudioClip_startTimeValueAttributeDescription.transient = NO;
    AudioClip_startTimeValueAttributeDescription.name = @"startTimeValue";
    AudioClip_startTimeValueAttributeDescription.valueTransformerName = SVNSValueValueTransformer.name;
    
    NSAttributeDescription *AudioClip_endTimeValueAttributeDescription = [NSAttributeDescription new];
    AudioClip_endTimeValueAttributeDescription.attributeType = NSTransformableAttributeType;
    AudioClip_endTimeValueAttributeDescription.optional = YES;
    AudioClip_endTimeValueAttributeDescription.transient = NO;
    AudioClip_endTimeValueAttributeDescription.name = @"endTimeValue";
    AudioClip_endTimeValueAttributeDescription.valueTransformerName = SVNSValueValueTransformer.name;
    
    NSRelationshipDescription *AudioClip_audioTrackRelationshipDescription = [NSRelationshipDescription new];
    AudioClip_audioTrackRelationshipDescription.optional = YES;
    AudioClip_audioTrackRelationshipDescription.transient = NO;
    AudioClip_audioTrackRelationshipDescription.name = @"audioTrack";
    AudioClip_audioTrackRelationshipDescription.minCount = 0;
    AudioClip_audioTrackRelationshipDescription.maxCount = 1;
    AudioClip_audioTrackRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSRelationshipDescription *Clip_footageRelationshipDescription = [NSRelationshipDescription new];
    Clip_footageRelationshipDescription.optional = YES;
    Clip_footageRelationshipDescription.transient = NO;
    Clip_footageRelationshipDescription.name = @"footage";
    Clip_footageRelationshipDescription.minCount = 0;
    Clip_footageRelationshipDescription.maxCount = 1;
    Clip_footageRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    NSAttributeDescription *Clip_nameAttributeDescription = [NSAttributeDescription new];
    Clip_nameAttributeDescription.attributeType = NSStringAttributeType;
    Clip_nameAttributeDescription.optional = YES;
    Clip_nameAttributeDescription.transient = NO;
    Clip_nameAttributeDescription.name = @"name";
    
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
    
    //
    
    NSAttributeDescription *LocalFileFootage_lastPathComponentAttributeDescription = [NSAttributeDescription new];
    LocalFileFootage_lastPathComponentAttributeDescription.attributeType = NSStringAttributeType;
    LocalFileFootage_lastPathComponentAttributeDescription.optional = YES;
    LocalFileFootage_lastPathComponentAttributeDescription.transient = NO;
    LocalFileFootage_lastPathComponentAttributeDescription.name = @"lastPathComponent";
    
    
    //
    
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
    
    VideoProject_videoTrackRelationshipDescription.inverseRelationship = VideoTrack_videoProjectRelationshipDescription;
    VideoProject_audioTrackRelationshipDescription.inverseRelationship = AudioTrack_videoProjectRelationshipDescription;
    VideoProject_captionTrackRelationshipDescription.inverseRelationship = CaptionTrack_videoProjectRelationshipDescription;
    VideoTrack_videoClipsRelationshipDescription.inverseRelationship = VideoClip_videoTrackRelationshipDescription;
    VideoTrack_videoProjectRelationshipDescription.inverseRelationship = VideoProject_videoTrackRelationshipDescription;
    AudioTrack_audioClipsRelationshipDescription.inverseRelationship = AudioClip_audioTrackRelationshipDescription;
    AudioTrack_videoProjectRelationshipDescription.inverseRelationship = VideoProject_audioTrackRelationshipDescription;
    CaptionTrack_captionsRelationshipDescription.inverseRelationship = Caption_captionTrackRelationshipDescription;
    Clip_footageRelationshipDescription.inverseRelationship = Footage_clipsRelationshipDescription;
    VideoClip_videoTrackRelationshipDescription.inverseRelationship = VideoTrack_videoClipsRelationshipDescription;
    AudioClip_audioTrackRelationshipDescription.inverseRelationship = AudioTrack_audioClipsRelationshipDescription;
    Footage_clipsRelationshipDescription.inverseRelationship = Clip_footageRelationshipDescription;
    
    //
    
    NSEntityDescription *videoProjectEntityDescription = [NSEntityDescription new];
    videoProjectEntityDescription.name = @"VideoProject";
    videoProjectEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoProject.class);
    
    NSEntityDescription *videoTrackEntityDescription = [NSEntityDescription new];
    videoTrackEntityDescription.name = @"VideoTrack";
    videoTrackEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoTrack.class);
    
    NSEntityDescription *audioTrackEntityDescription = [NSEntityDescription new];
    audioTrackEntityDescription.name = @"AudioTrack";
    audioTrackEntityDescription.managedObjectClassName = NSStringFromClass(SVAudioTrack.class);
    
    NSEntityDescription *captionTrackEntityDescription = [NSEntityDescription new];
    captionTrackEntityDescription.name = @"CaptionTrack";
    captionTrackEntityDescription.managedObjectClassName = NSStringFromClass(SVCaptionTrack.class);
    
    NSEntityDescription *trackEntityDescription = [NSEntityDescription new];
    trackEntityDescription.name = @"Track";
    trackEntityDescription.managedObjectClassName = NSStringFromClass(SVTrack.class);
    trackEntityDescription.abstract = YES;
    trackEntityDescription.subentities = @[
        videoTrackEntityDescription,
        audioTrackEntityDescription,
        captionTrackEntityDescription
    ];
    
    NSEntityDescription *videoClipEntityDescription = [NSEntityDescription new];
    videoClipEntityDescription.name = @"VideoClip";
    videoClipEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoClip.class);
    
    NSEntityDescription *audioClipEntityDescription = [NSEntityDescription new];
    audioClipEntityDescription.name = @"AudioClip";
    audioClipEntityDescription.managedObjectClassName = NSStringFromClass(SVAudioClip.class);
    
    NSEntityDescription *clipEntityDescription = [NSEntityDescription new];
    clipEntityDescription.name = @"Clip";
    clipEntityDescription.managedObjectClassName = NSStringFromClass(SVClip.class);
    clipEntityDescription.abstract = YES;
    clipEntityDescription.subentities = @[
        videoClipEntityDescription,
        audioClipEntityDescription
    ];
    
    NSEntityDescription *captionEntityDescription = [NSEntityDescription new];
    captionEntityDescription.name = @"Caption";
    captionEntityDescription.managedObjectClassName = NSStringFromClass(SVCaption.class);
    
    NSEntityDescription *phAssetFootageEntityDescription = [NSEntityDescription new];
    phAssetFootageEntityDescription.name = @"PHAssetFootage";
    phAssetFootageEntityDescription.managedObjectClassName = NSStringFromClass(SVPHAssetFootage.class);
    
    NSEntityDescription *localFileFootageEntityDescription = [NSEntityDescription new];
    localFileFootageEntityDescription.name = @"LocalFileFootage";
    localFileFootageEntityDescription.managedObjectClassName = NSStringFromClass(SVLocalFileFootage.class);
    
    NSEntityDescription *footageEntityDescription = [NSEntityDescription new];
    footageEntityDescription.name = @"Footage";
    footageEntityDescription.managedObjectClassName = NSStringFromClass(SVFootage.class);
    footageEntityDescription.abstract = YES;
    footageEntityDescription.subentities = @[
        phAssetFootageEntityDescription,
        localFileFootageEntityDescription
    ];
    
    //
    
    VideoProject_videoTrackRelationshipDescription.destinationEntity = videoTrackEntityDescription;
    VideoProject_audioTrackRelationshipDescription.destinationEntity = audioTrackEntityDescription;
    VideoProject_captionTrackRelationshipDescription.destinationEntity = captionTrackEntityDescription;
    VideoTrack_videoClipsRelationshipDescription.destinationEntity = videoClipEntityDescription;
    VideoTrack_videoProjectRelationshipDescription.destinationEntity = videoProjectEntityDescription;
    AudioTrack_audioClipsRelationshipDescription.destinationEntity = audioClipEntityDescription;
    AudioTrack_videoProjectRelationshipDescription.destinationEntity = videoProjectEntityDescription;
    CaptionTrack_captionsRelationshipDescription.destinationEntity = captionEntityDescription;
    CaptionTrack_videoProjectRelationshipDescription.destinationEntity = videoProjectEntityDescription;
    VideoClip_videoTrackRelationshipDescription.destinationEntity = videoTrackEntityDescription;
    AudioClip_audioTrackRelationshipDescription.destinationEntity = audioTrackEntityDescription;
    Clip_footageRelationshipDescription.destinationEntity = footageEntityDescription;
    Caption_captionTrackRelationshipDescription.destinationEntity = captionTrackEntityDescription;
    Footage_clipsRelationshipDescription.destinationEntity = clipEntityDescription;
    
    //
    
    videoProjectEntityDescription.properties = @[
        VideoProject_createdDateAttributeDescription,
        VideoProject_videoTrackRelationshipDescription,
        VideoProject_audioTrackRelationshipDescription,
        VideoProject_captionTrackRelationshipDescription,
        VideoProject_thumbnailImageTIFFDataAttributeDescription
    ];
    
    videoTrackEntityDescription.properties = @[
        VideoTrack_videoClipsCountAttributeDescription,
        VideoTrack_videoClipsRelationshipDescription,
        VideoTrack_videoProjectRelationshipDescription
    ];
    
    audioTrackEntityDescription.properties = @[
        AudioTrack_audioClipsCountAttributeDescription,
        AudioTrack_audioClipsRelationshipDescription,
        AudioTrack_videoProjectRelationshipDescription
    ];
    
    captionTrackEntityDescription.properties = @[
        CaptionTrack_captionsCountAttributeDescription,
        CaptionTrack_captionsRelationshipDescription,
        CaptionTrack_videoProjectRelationshipDescription
    ];
    
    videoClipEntityDescription.properties = @[
        VideoClip_videoTrackRelationshipDescription
    ];
    
    audioClipEntityDescription.properties = @[
        AudioClip_startTimeValueAttributeDescription,
        AudioClip_endTimeValueAttributeDescription,
        AudioClip_audioTrackRelationshipDescription
    ];
    
    captionEntityDescription.properties = @[
        Caption_attributedStringAttributeDescription,
        Caption_startTimeValueAttributeDescription,
        Caption_endTimeValueAttributeDescription,
        Caption_captionTrackRelationshipDescription
    ];
    
    clipEntityDescription.properties = @[
        Clip_footageRelationshipDescription,
        Clip_nameAttributeDescription
    ];
    
    phAssetFootageEntityDescription.properties = @[
        PHAsset_assetIdentifierAttributeDescription
    ];
    
    phAssetFootageEntityDescription.uniquenessConstraints = @[
        @[
            PHAsset_assetIdentifierAttributeDescription
        ]
    ];
    
    localFileFootageEntityDescription.properties = @[
        LocalFileFootage_lastPathComponentAttributeDescription
    ];
    
    localFileFootageEntityDescription.uniquenessConstraints = @[
        @[
            LocalFileFootage_lastPathComponentAttributeDescription
        ]
    ];
    
    footageEntityDescription.properties = @[
        Footage_clipsRelationshipDescription,
        Footage_clipsCountDerivedAttributeDescription
    ];
    
    //
    
    [VideoProject_createdDateAttributeDescription release];
    [VideoProject_videoTrackRelationshipDescription release];
    [VideoProject_audioTrackRelationshipDescription release];
    [VideoProject_captionTrackRelationshipDescription release];
    [VideoProject_thumbnailImageTIFFDataAttributeDescription release];
    [VideoTrack_videoClipsCountAttributeDescription release];
    [VideoTrack_videoClipsRelationshipDescription release];
    [VideoTrack_videoProjectRelationshipDescription release];
    [AudioTrack_audioClipsCountAttributeDescription release];
    [AudioTrack_audioClipsRelationshipDescription release];
    [AudioTrack_videoProjectRelationshipDescription release];
    [CaptionTrack_captionsCountAttributeDescription release];
    [CaptionTrack_captionsRelationshipDescription release];
    [CaptionTrack_videoProjectRelationshipDescription release];
    [AudioClip_startTimeValueAttributeDescription release];
    [AudioClip_endTimeValueAttributeDescription release];
    [VideoClip_videoTrackRelationshipDescription release];
    [AudioClip_audioTrackRelationshipDescription release];
    [Clip_footageRelationshipDescription release];
    [Clip_nameAttributeDescription release];
    [Caption_attributedStringAttributeDescription release];
    [Caption_startTimeValueAttributeDescription release];
    [Caption_endTimeValueAttributeDescription release];
    [Caption_captionTrackRelationshipDescription release];
    [PHAsset_assetIdentifierAttributeDescription release];
    [LocalFileFootage_lastPathComponentAttributeDescription release];
    [Footage_clipsRelationshipDescription release];
    [Footage_clipsCountDerivedAttributeDescription release];
    
    //
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    managedObjectModel.entities = @[
        videoProjectEntityDescription,
        videoTrackEntityDescription,
        audioTrackEntityDescription,
        captionTrackEntityDescription,
        trackEntityDescription,
        videoClipEntityDescription,
        audioClipEntityDescription,
        clipEntityDescription,
        captionEntityDescription,
        phAssetFootageEntityDescription,
        localFileFootageEntityDescription,
        footageEntityDescription
    ];
    
    [videoProjectEntityDescription release];
    [videoTrackEntityDescription release];
    [audioTrackEntityDescription release];
    [captionTrackEntityDescription release];
    [trackEntityDescription release];
    [videoClipEntityDescription release];
    [audioClipEntityDescription release];
    [clipEntityDescription release];
    [captionEntityDescription release];
    [phAssetFootageEntityDescription release];
    [localFileFootageEntityDescription release];
    [footageEntityDescription release];
    
    return [managedObjectModel autorelease];
}

@end
