//
//  NSObject+SVKeyValueObservation.m
//  
//
//  Created by Jinwoo Kim on 6/11/23.
//

#import <SurfVideoCore/NSObject+SVKeyValueObservation.h>
#import <SurfVideoCore/SVKeyValueObservation+Private.h>

@implementation NSObject (KeyValueObservation)

- (SVKeyValueObservation *)observeValueForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options changeHandler:(void (^)(id _Nonnull, NSDictionary * _Nonnull))changeHandler {
    SVKeyValueObservation *observation = [[SVKeyValueObservation alloc] initWithObject:self forKeyPath:keyPath options:options callback:changeHandler];
    return [observation autorelease];
}

@end
