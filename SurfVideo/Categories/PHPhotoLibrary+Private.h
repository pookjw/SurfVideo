//
//  PHPhotoLibrary+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import <Photos/Photos.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHPhotoLibrary (Private)
- (__kindof NSManagedObjectContext *)managedObjectContextForCurrentQueueQoS;
- (__kindof NSManagedObjectContext *)managedObjectContext;
@end

NS_ASSUME_NONNULL_END
