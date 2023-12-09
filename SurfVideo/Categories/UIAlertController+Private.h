//
//  UIAlertController+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/10/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (Private)
@property (retain, nonatomic, setter=_setSeparatedHeaderContentViewController:) UIViewController* _separatedHeaderContentViewController;
@property (retain, nonatomic, setter=_setHeaderContentViewController:) UIViewController* _headerContentViewController;
@property (retain, nonatomic) UIViewController* contentViewController;
@property (copy, nonatomic, getter=_attributedDetailMessage, setter=_setAttributedDetailMessage:) NSAttributedString* _attributedDetailMessage;
@property (copy, nonatomic, getter=_attributedMessage, setter=_setAttributedMessage:) NSAttributedString* attributedMessage;
@property (retain, nonatomic) UIImage* image;
@end

NS_ASSUME_NONNULL_END
