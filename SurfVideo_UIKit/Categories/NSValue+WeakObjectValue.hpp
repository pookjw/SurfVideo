//
//  NSValue+WeakObjectValue.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface NSValue (WeakObjectValue)
+ (__kindof NSValue *)sv_weakObjectValueWithObject:(id)object;
- (id _Nullable)weakObjectValue; // only for NSWeakObjectValue (-[NSWeakObjectValue weakObjectValue])
@end

NS_ASSUME_NONNULL_END
