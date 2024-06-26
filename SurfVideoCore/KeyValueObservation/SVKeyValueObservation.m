//
//  SVKeyValueObservation.m
//  
//
//  Created by Jinwoo Kim on 6/11/23.
//

#import <SurfVideoCore/SVKeyValueObservation.h>
#import <SurfVideoCore/SVKeyValueObservation+Private.h>
#import <objc/runtime.h>

// idea from https://github.com/apple/swift-corelibs-foundation/blob/bd2e810a3ff5adf12410666cee74725d94f2dd25/Darwin/Foundation-swiftoverlay/NSObject.swift#L163

static void *_associationKey = NULL;

@interface _SVKeyValueObservationHelper : NSObject
@property (class, readonly, nonatomic) void *associationKey;
@property (weak, nullable) id object;
@property (copy) NSString *keyPath;
@property (copy) void (^callback)(id, NSDictionary *);
@end

@implementation _SVKeyValueObservationHelper

+ (void *)associationKey {
    if (_associationKey) return _associationKey;
    _associationKey = malloc(__SIZEOF_INT__);
    return _associationKey;
}

- (instancetype)initWithObject:(id)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callback:(void (^)(id _Nonnull, NSDictionary * _Nonnull))callback {
    if (self = [self init]) {
        self.object = object;
        self.keyPath = keyPath;
        self.callback = callback;
        
        objc_setAssociatedObject(object, _SVKeyValueObservationHelper.associationKey, self, OBJC_ASSOCIATION_RETAIN);
        [object addObserver:self forKeyPath:keyPath options:options context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [_keyPath release];
    [_callback release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    self.callback(object, change);
}

- (void)invalidate {
    if (self.object == nil) return;
    [self.object removeObserver:self forKeyPath:self.keyPath context:NULL];
    objc_setAssociatedObject(self.object, _SVKeyValueObservationHelper.associationKey, nil, OBJC_ASSOCIATION_ASSIGN);
    self.object = nil;
}

@end

@interface SVKeyValueObservation ()
@property (retain) _SVKeyValueObservationHelper *helper;
@end

@implementation SVKeyValueObservation

- (instancetype)initWithObject:(id)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options callback:(void (^)(id _Nonnull, NSDictionary * _Nonnull))callback {
    if (self = [self init]) {
        _SVKeyValueObservationHelper *helper = [[_SVKeyValueObservationHelper alloc] initWithObject:object forKeyPath:keyPath options:options callback:callback];
        self.helper = helper;
        [helper release];
    }
    
    return self;
}

- (void)dealloc {
    [_helper invalidate];
    [_helper release];
    [super dealloc];
}

- (void)invalidate {
    [self.helper invalidate];
}

@end
