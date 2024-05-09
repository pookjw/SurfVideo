//
//  NSObject+SVKeyValueObservation.h
//  
//
//  Created by Jinwoo Kim on 6/11/23.
//

#import <SurfVideoCore/SVKeyValueObservation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KeyValueObservation)
- (SVKeyValueObservation *)observeValueForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options changeHandler:(void (^)(id object, NSDictionary *changes))changeHandler;
@end

NS_ASSUME_NONNULL_END
