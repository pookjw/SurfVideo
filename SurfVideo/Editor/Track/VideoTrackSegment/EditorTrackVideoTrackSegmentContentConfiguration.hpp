//
//  EditorTrackVideoTrackSegmentContentConfiguration.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import <UIKit/UIKit.h>
#import "EditorTrackSectionModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackVideoTrackSegmentContentConfiguration : NSObject <UIContentConfiguration>
@property (retain, readonly, nonatomic) EditorTrackSectionModel *sectionModel;
@property (retain, readonly, nonatomic) EditorTrackItemModel *itemModel;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSectionModel:(EditorTrackSectionModel *)sectionModel itemModel:(EditorTrackItemModel *)itemModel NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
