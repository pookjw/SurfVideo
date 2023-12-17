//
//  EditorTrackMainVideoTrackContentConfiguration.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import <UIKit/UIKit.h>
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackMainVideoTrackContentConfiguration : NSObject <UIContentConfiguration>
@property (retain, readonly, nonatomic) EditorTrackItemModel *itemModel;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithItemModel:(EditorTrackItemModel *)itemModel NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
