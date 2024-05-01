//
//  NSManagedObjectContext+CheckThread.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/1/24.
//

#import "NSManagedObjectContext+CheckThread.hpp"
#include <pthread/pthread.h>

@implementation NSManagedObjectContext (CheckThread)

- (BOOL)sv_isThreadOfManagedObjectContext {
    return self == pthread_getspecific(0x59);
}

- (void)sv_performBlock:(void (^)())block {
    if (self == pthread_getspecific(0x59)) {
        block();
    } else {
        [self performBlock:block];
    }
}

@end
