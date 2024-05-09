//
//  EditorTrackAudioTrackSegmentContentConfiguration.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import <UIKit/UIKit.h>
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackAudioTrackSegmentContentConfiguration : NSObject <UIContentConfiguration>
@property (retain, readonly, nonatomic) EditorTrackItemModel *itemModel;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithItemModel:(EditorTrackItemModel *)itemModel NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
