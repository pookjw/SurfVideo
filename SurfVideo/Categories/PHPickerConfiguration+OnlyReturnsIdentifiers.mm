//
//  PHPickerConfiguration+OnlyReturnsIdentifiers.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import "PHPickerConfiguration+onlyReturnsIdentifiers.hpp"
#import <objc/message.h>
#import <algorithm>

@implementation PHPickerConfiguration (OnlyReturnsIdentifiers)

- (void)set_sv_onlyReturnsIdentifiers:(BOOL)sv_onlyReturnsIdentifiers __attribute__((objc_direct)) {
    *[self sv_onlyReturnsIdentifiers_ptr] = sv_onlyReturnsIdentifiers;
}

- (BOOL)sv_onlyReturnsIdentifiers __attribute__((objc_direct)) {
    return *[self sv_onlyReturnsIdentifiers_ptr];
}

- (BOOL *)sv_onlyReturnsIdentifiers_ptr __attribute__((objc_direct)) {
    unsigned int ivarsCount;
    Ivar *ivars = class_copyIvarList([self class], &ivarsCount);
    
    auto ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
        auto name = ivar_getName(ivar);
        return !std::strcmp(name, "__onlyReturnsIdentifiers");
    });
    
    ptrdiff_t offset = ivar_getOffset(*ivar);
    delete ivars;
    
    uintptr_t base = reinterpret_cast<uintptr_t>(self);
    auto location = reinterpret_cast<BOOL *>(base + offset);
    
    return location;
}

@end
