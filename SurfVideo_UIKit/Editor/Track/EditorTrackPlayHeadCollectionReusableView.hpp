//
//  EditorTrackPlayHeadCollectionReusableView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/15/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackPlayHeadCollectionReusableView : UICollectionReusableView
@property (class, readonly, nonatomic) NSString *elementKind;
@end

NS_ASSUME_NONNULL_END
