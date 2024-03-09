//
//  SVRunLoop.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/9/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface SVRunLoop : NSObject
@property (class, retain, readonly, nonatomic) SVRunLoop *globalRenderRunLoop;
- (instancetype)initWithThreadName:(NSString * _Nullable)threadName;
- (void)runBlock:(void (^)())block; // autoreleasepool은 제공하지 않음
@end

NS_ASSUME_NONNULL_END
