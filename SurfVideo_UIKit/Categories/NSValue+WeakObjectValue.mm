//
//  NSValue+WeakObjectValue.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "NSValue+WeakObjectValue.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation NSValue (WeakObjectValue)
#pragma clang diagnostic pop

+ (__kindof NSValue *)sv_weakObjectValueWithObject:(id)object {
    __kindof NSValue *weakObjectValue = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass("NSWeakObjectValue") alloc], sel_registerName("initWithObject:"), object);
    return [weakObjectValue autorelease];
}

@end
