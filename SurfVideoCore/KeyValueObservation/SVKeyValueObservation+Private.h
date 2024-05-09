//
//  SVKeyValueObservation+Private.h
//
//
//  Created by Jinwoo Kim on 6/11/23.
//

#import <SurfVideoCore/SVKeyValueObservation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVKeyValueObservation (Private)
- (instancetype)initWithObject:(id)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callback:(void (^)(id object, NSDictionary *change))callback;
@end

NS_ASSUME_NONNULL_END
