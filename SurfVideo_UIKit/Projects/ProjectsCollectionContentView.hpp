//
//  ProjectsCollectionContentView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import <UIKit/UIKit.h>
#import "ProjectsCollectionContentConfiguration.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ProjectsCollectionContentView : UIView <UIContentView>
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithContentConfiguration:(ProjectsCollectionContentConfiguration *)contentConfiguration NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
