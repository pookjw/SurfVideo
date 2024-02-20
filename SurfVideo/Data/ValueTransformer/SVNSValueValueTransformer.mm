//
//  SVNSValueValueTransformer.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "SVNSValueValueTransformer.hpp"

@implementation SVNSValueValueTransformer

+ (NSValueTransformerName)name {
    return @"com.pookjw.SurfVideo.SVNSValueValueTransformer";
}

+ (Class)transformedValueClass {
    return NSValue.class;
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    NSError * _Nullable error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value requiringSecureCoding:YES error:&error];
    assert(!error);
    return data;
}

- (id)reverseTransformedValue:(id)value {
    NSError * _Nullable error = nil;
    NSValue *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObject:NSValue.class] fromData:value error:&error];
    assert(!error);
    return result;
}

@end
