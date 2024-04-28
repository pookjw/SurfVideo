//
//  NSManagedObjectModel+SVObjectModel.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/28/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface NSManagedObjectModel (SVObjectModel)
@property (class, readonly, nonatomic) NSManagedObjectModel *sv_projectsObjectModel_current;
@property (class, readonly, nonatomic) NSManagedObjectModel *sv_projectsObjectModel_v1;
@property (class, readonly, nonatomic) NSManagedObjectModel *sv_projectsObjectModel_v0;
@end

NS_ASSUME_NONNULL_END
