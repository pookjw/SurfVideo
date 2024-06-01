//
//  CALayer+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (Private)
#if TARGET_OS_VISION
@property (copy) NSDictionary *separatedOptions;
#endif
@end

NS_ASSUME_NONNULL_END
