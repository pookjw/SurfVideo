//
//  ProjectsCollectionContentConfiguration.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ProjectsCollectionContentConfiguration : NSObject <UIContentConfiguration>
@property (copy, readonly, nonatomic) NSManagedObjectID *videoProjectObjectID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoProjectObjectID:(NSManagedObjectID *)videoProjectObjectID;
@end

NS_ASSUME_NONNULL_END
