//
//  SVProjectsManager.hpp
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import <CoreData/CoreData.h>
#import <PhotosUI/PhotosUI.h>
#import <SurfVideoCore/SVVideoProject.hpp>
#import <SurfVideoCore/SVVideoTrack.hpp>
#import <SurfVideoCore/SVAudioTrack.hpp>
#import <SurfVideoCore/SVCaptionTrack.hpp>
#import <SurfVideoCore/SVEffectTrack.hpp>
#import <SurfVideoCore/SVTrack.hpp>
#import <SurfVideoCore/SVVideoClip.hpp>
#import <SurfVideoCore/SVAudioClip.hpp>
#import <SurfVideoCore/SVClip.hpp>
#import <SurfVideoCore/SVCaption.hpp>
#import <SurfVideoCore/SVPHAssetFootage.hpp>
#import <SurfVideoCore/SVLocalFileFootage.hpp>
#import <SurfVideoCore/SVFootage.hpp>
#import <SurfVideoCore/SVEffect.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface SVProjectsManager : NSObject
@property (readonly, nonatomic) NSURL *localFileFootagesURL;
+ (SVProjectsManager *)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (void)managedObjectContextWithCompletionHandler:(void (^)(NSManagedObjectContext * _Nullable managedObjectContext))completionHandler;
- (void)cleanupFootagesWithCompletionHandler:(void (^)(NSInteger cleanedUpFootagesCount, NSError * _Nullable error))completionHandler;

- (SVVideoProject * _Nullable)contextQueue_createVideoProjectWithPickerResults:(NSArray<PHPickerResult *> *)results managedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error;

- (NSDictionary<NSString *, SVPHAssetFootage *> * _Nullable)contextQueue_phAssetFootagesFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers createIfNeededWithoutSaving:(BOOL)createIfNeededWithoutSaving managedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError * _Nullable * _Nullable)error;
- (NSDictionary<NSURL *, SVLocalFileFootage *> * _Nullable)contextQueue_localFileFootageFromURLs:(NSArray<NSURL *> *)urls createIfNeededWithoutSaving:(BOOL)createIfNeededWithoutSaving managedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError * _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
