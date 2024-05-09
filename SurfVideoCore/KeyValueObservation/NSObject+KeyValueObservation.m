//
//  NSObject+KeyValueObservation.m
//  
//
//  Created by Jinwoo Kim on 6/11/23.
//

#import <SurfVideoCore/NSObject+KeyValueObservation.h>
#import <SurfVideoCore/KeyValueObservation+Private.h>

@implementation NSObject (KeyValueObservation)

- (KeyValueObservation *)observeValueForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options changeHandler:(void (^)(id _Nonnull, NSDictionary * _Nonnull))changeHandler {
    KeyValueObservation *observation = [[KeyValueObservation alloc] initWithObject:self forKeyPath:keyPath options:options callback:changeHandler];
    return [observation autorelease];
}

@end
