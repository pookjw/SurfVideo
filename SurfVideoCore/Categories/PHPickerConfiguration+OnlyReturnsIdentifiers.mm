//
//  PHPickerConfiguration+OnlyReturnsIdentifiers.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import "PHPickerConfiguration+OnlyReturnsIdentifiers.hpp"
#import <objc/runtime.h>
#import <algorithm>

@implementation PHPickerConfiguration (OnlyReturnsIdentifiers)

- (void)set_sv_onlyReturnsIdentifiers:(BOOL)sv_onlyReturnsIdentifiers {
    object_setInstanceVariable(self, "__onlyReturnsIdentifiers", (void **)&sv_onlyReturnsIdentifiers);
}

- (BOOL)sv_onlyReturnsIdentifiers {
    BOOL result = NO;
    object_getInstanceVariable(self, "__onlyReturnsIdentifiers", (void **)result);
    return result;
}

@end
