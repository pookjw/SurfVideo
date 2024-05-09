//
//  SVAudioSamplesManager.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/8/24.
//

#import <SurfVideoCore/SVAudioSamplesManager.hpp>
#import <SurfVideoCore/SVNSArrayValueTransformer.hpp>
#import <SurfVideoCore/AudioSamplesExtractor.hpp>
#import <SurfVideoCore/constants.hpp>
#import <Accelerate/Accelerate.h>
#import <objc/message.h>
#import <memory>
#import <algorithm>

__attribute__((objc_direct_members))
@interface SVAudioSamplesManager ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) NSPersistentContainer * _Nullable queue_persistentContainer;
@property (retain, readonly, nonatomic) NSManagedObjectContext * _Nullable queue_managedObjectContext;
@property (readonly, nonatomic) NSURL *workingURL;
@property (readonly, nonatomic) NSManagedObjectModel *managedObjectModel_v0;
@end

@implementation SVAudioSamplesManager

@synthesize queue_persistentContainer = _queue_persistentContainer;
@synthesize queue_managedObjectContext = _queue_managedObjectContext;

+ (SVAudioSamplesManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static SVAudioSamplesManager *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [SVAudioSamplesManager new];
    });
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("SVAudioSamplesManager", attr);
    }
    
    return self;
}

- (void)dealloc {
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [_queue_persistentContainer release];
    [_queue_managedObjectContext release];
    
    [super dealloc];
}

- (NSProgress *)audioSampleFromURL:(NSURL *)url completionHandler:(void (^)(SVAudioSample * _Nullable, NSError * _Nullable))completionHandler {
    AVAsset *asset = [AVAsset assetWithURL:url];
    return [self audioSampleFromAsset:asset completionHandler:completionHandler];
}

- (NSProgress *)audioSampleFromAsset:(AVAsset *)asset completionHandler:(void (^)(SVAudioSample * _Nullable, NSError * _Nullable))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    dispatch_async(self.queue, ^{
        // AVFigAssetInspector *
        id _assetInspector = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(asset, sel_registerName("_assetInspector"));
        NSData * _Nullable SHA1Digest = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(_assetInspector, sel_registerName("SHA1Digest"));
        
        if (SHA1Digest == nil) {
            progress.completedUnitCount = 1;
            
            if (completionHandler) {
                completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoHashValue userInfo:nil]);
            }
            
            return;
        }
        
        NSManagedObjectContext *managedObjectContext = self.queue_managedObjectContext;
        
        [managedObjectContext performBlock:^{
            Float64 samplingRate = 5000.;
            float noiseFloor = -50.f;
            
            NSFetchRequest<SVAudioSample *> *fetchRequest = [SVAudioSample fetchRequest];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K == %@) && (%K == %lf) && (%K == %lf)" argumentArray:@[@"sha1", SHA1Digest, @"noiseFloor", @(noiseFloor), @"samplingRate", @(samplingRate)]];
            fetchRequest.predicate = predicate;
            fetchRequest.fetchLimit = 1;
            
            NSError * _Nullable error = nil;
            NSArray *objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            
            if (error) {
                progress.completedUnitCount = 1;
                
                if (completionHandler) {
                    completionHandler(nil, error);
                }
                
                return;
            }
            
            if (SVAudioSample *audioSample = objects.firstObject) {
                progress.completedUnitCount = 1;
                
                if (completionHandler) {
                    completionHandler(audioSample, nil);
                }
                
                return;
            }
            
            [asset loadTracksWithMediaType:AVMediaTypeAudio completionHandler:^(NSArray<AVAssetTrack *> * _Nullable assetTracks, NSError * _Nullable error) {
                if (error) {
                    progress.completedUnitCount = 1;
                    
                    if (completionHandler) {
                        completionHandler(nil, error);
                    }
                    
                    return;
                }
                
                AVAssetTrack * _Nullable assetTrack = assetTracks.firstObject;
                if (assetTrack == nil) {
                    progress.completedUnitCount = 1;
                    
                    if (completionHandler) {
                        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideNoAudioTrack userInfo:nil]);
                    }
                    
                    return;
                }
                
                std::shared_ptr<float> maxSample = std::make_shared<float>(-FLT_MAX);
                std::shared_ptr<double> sumSamples = std::make_shared<double>(0.);
                std::shared_ptr<std::vector<float>> totalSamples = std::make_shared<std::vector<float>>();
                
                [AudioSamplesExtractor extractAudioSamplesFromAssetTrack:assetTrack timeRange:kCMTimeRangeInvalid samplingRate:samplingRate noiseFloor:noiseFloor progressHandler:^(std::optional<const std::vector<float>> samples, BOOL isFinal, BOOL * _Nonnull stop, NSError * _Nullable error) {
                    *stop = progress.isCancelled;
                    
                    if (error) {
                        progress.completedUnitCount = 1;
                        
                        if (completionHandler) {
                            completionHandler(nil, error);
                        }
                        
                        return;
                    }
                    
                    totalSamples.get()->reserve(samples.value().size());
                    std::for_each(samples.value().begin(), samples.value().end(), [totalSamples, maxSample, sumSamples](float sample) {
                        *maxSample.get() = std::fmax(*maxSample.get(), sample);
                        *sumSamples.get() += sample;
                        totalSamples.get()->push_back(sample);
                    });
                    
                    if (isFinal) {
                        NSMutableArray<NSNumber *> *normalizedSamples = [[NSMutableArray<NSNumber *> alloc] initWithCapacity:totalSamples.get()->size()];
                        
                        float _maxSample = *maxSample.get();
                        float average = *sumSamples.get() / totalSamples.get()->size();
                        float minDist = average - noiseFloor;
                        float maxDist = _maxSample - average;
                        
                        std::for_each(totalSamples.get()->cbegin(), totalSamples.get()->cend(), [noiseFloor, _maxSample, average, minDist, maxDist, normalizedSamples](float sample) {
                            float normalizedSample;
                            
                            if (sample < average) {
                                normalizedSample = 0.5f - ((average - sample) / minDist) * 0.5f;
                            } else {
                                normalizedSample = 0.5f + ((sample - average) / maxDist) * 0.5f;
                            }
                            
                            [normalizedSamples addObject:@(normalizedSample)];
                        });
                                                
                        [managedObjectContext performBlock:^{
                            SVAudioSample *audioSample = [[[SVAudioSample alloc] initWithContext:managedObjectContext] autorelease];
                            audioSample.sha1 = SHA1Digest;
                            audioSample.noiseFloor = noiseFloor;
                            audioSample.samples = normalizedSamples;
                            audioSample.samplingRate = samplingRate;
                            
                            NSError * _Nullable error = nil;
                            [managedObjectContext save:&error];
                            
                            if (error) {
                                progress.completedUnitCount = 1;
                                completionHandler(nil, error);
                                return;
                            }
                            
                            progress.completedUnitCount = 1;
                            
                            if (completionHandler) {
                                completionHandler(audioSample, nil);
                            }
                        }];
                        
                        [normalizedSamples release];
                    }
                }];
            }];
        }];
    });
    
    return progress;
}

- (void)managedObjectContextWithCompletionHandler:(void (^)(NSManagedObjectContext * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        completionHandler(self.queue_managedObjectContext);
    });
}

- (NSPersistentContainer *)queue_persistentContainer {
    if (auto queue_persistentContainer = _queue_persistentContainer) return queue_persistentContainer;
    
    NSError * _Nullable error = nil;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSURL *workingURL = self.workingURL;
    
    if (![fileManager fileExistsAtPath:workingURL.path isDirectory:nil]) {
        [fileManager createDirectoryAtURL:workingURL withIntermediateDirectories:YES attributes:nil error:&error];
        assert(!error);
    }
    
    NSURL *containerURL = [[workingURL URLByAppendingPathComponent:@"container" isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];
    
    NSLog(@"%@", [containerURL path]);
    
    NSPersistentStoreDescription *persistentStoreDescription = [[NSPersistentStoreDescription alloc] initWithURL:containerURL];
    persistentStoreDescription.shouldAddStoreAsynchronously = NO;
    
    NSPersistentContainer *persistentContainer = [[NSPersistentContainer alloc] initWithName:@"v0" managedObjectModel:self.managedObjectModel_v0];
    
    [persistentContainer.persistentStoreCoordinator addPersistentStoreWithDescription:persistentStoreDescription completionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable _error) {
        assert(!error);
    }];
    [persistentStoreDescription release];
    
    _queue_persistentContainer = [persistentContainer retain];
    return [persistentContainer autorelease];
}

- (NSManagedObjectContext *)queue_managedObjectContext {
    if (auto managedObjectContext = _queue_managedObjectContext) return managedObjectContext;
    
    NSManagedObjectContext *managedObjectContext = [self.queue_persistentContainer newBackgroundContext];
    
    _queue_managedObjectContext = [managedObjectContext retain];
    return [managedObjectContext autorelease];
}

- (NSURL *)workingURL {
    NSURL *applicationSupportURL = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *workingURL = [[applicationSupportURL URLByAppendingPathComponent:@"SurfVideo" isDirectory:YES] URLByAppendingPathComponent:@"SVAudioSamplesManager" isDirectory:YES];
    return workingURL;
}

- (NSManagedObjectModel *)managedObjectModel_v0 {
    NSAttributeDescription *AudioSample_sha1AttributeDescription = [NSAttributeDescription new];
    AudioSample_sha1AttributeDescription.attributeType = NSBinaryDataAttributeType;
    AudioSample_sha1AttributeDescription.optional = YES;
    AudioSample_sha1AttributeDescription.transient = NO;
    AudioSample_sha1AttributeDescription.name = @"sha1";
    
    NSAttributeDescription *AudioSample_noiseFloorAttributeDescription = [NSAttributeDescription new];
    AudioSample_noiseFloorAttributeDescription.attributeType = NSFloatAttributeType;
    AudioSample_noiseFloorAttributeDescription.optional = YES;
    AudioSample_noiseFloorAttributeDescription.transient = NO;
    AudioSample_noiseFloorAttributeDescription.name = @"noiseFloor";
    
    NSAttributeDescription *AudioSample_samplesAttributeDescription = [NSAttributeDescription new];
    AudioSample_samplesAttributeDescription.attributeType = NSTransformableAttributeType;
    AudioSample_samplesAttributeDescription.optional = YES;
    AudioSample_samplesAttributeDescription.transient = NO;
    AudioSample_samplesAttributeDescription.name = @"samples";
    AudioSample_samplesAttributeDescription.valueTransformerName = SVNSArrayValueTransformer.name;
    
    NSAttributeDescription *AudioSample_samplingRateAttributeDescription = [NSAttributeDescription new];
    AudioSample_samplingRateAttributeDescription.attributeType = NSFloatAttributeType;
    AudioSample_samplingRateAttributeDescription.optional = YES;
    AudioSample_samplingRateAttributeDescription.transient = NO;
    AudioSample_samplingRateAttributeDescription.name = @"samplingRate";
    
    //
    
    NSEntityDescription *audioSampleEntityDescription = [NSEntityDescription new];
    audioSampleEntityDescription.name = @"AudioSample";
    audioSampleEntityDescription.managedObjectClassName = NSStringFromClass(SVAudioSample.class);
    
    audioSampleEntityDescription.properties = @[
        AudioSample_sha1AttributeDescription,
        AudioSample_noiseFloorAttributeDescription,
        AudioSample_samplesAttributeDescription,
        AudioSample_samplingRateAttributeDescription
    ];
    
    audioSampleEntityDescription.uniquenessConstraints = @[
        @[
            AudioSample_sha1AttributeDescription,
            AudioSample_noiseFloorAttributeDescription,
            AudioSample_samplingRateAttributeDescription
        ]
    ];
    
    [AudioSample_sha1AttributeDescription release];
    [AudioSample_noiseFloorAttributeDescription release];
    [AudioSample_samplesAttributeDescription release];
    [AudioSample_samplingRateAttributeDescription release];
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    managedObjectModel.entities = @[
        audioSampleEntityDescription
    ];
    
    [audioSampleEntityDescription release];
    
    return [managedObjectModel autorelease];
}

@end
