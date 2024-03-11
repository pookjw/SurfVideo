//
//  UIListContentConfiguration+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/12/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIListContentConfiguration (Private)
+ (instancetype)_defaultInsetGroupedCellConfiguration;
+ (instancetype)_interactiveInsetGroupedHeaderConfiguration;
+ (instancetype)_prominentInsetGroupedHeaderConfiguration;
@end

NS_ASSUME_NONNULL_END
