//
//  UIAlertAction+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertAction (Private)
@property (nonatomic, setter=_setAlertController:) UIAlertController *_alertController;
@end

NS_ASSUME_NONNULL_END
