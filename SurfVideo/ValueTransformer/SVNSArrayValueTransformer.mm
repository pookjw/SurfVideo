//
//  SVNSArrayValueTransformer.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/8/24.
//

#import "SVNSArrayValueTransformer.hpp"

@implementation SVNSArrayValueTransformer

+ (void)load {
    SVNSArrayValueTransformer *nsArrayValueTransformer = [SVNSArrayValueTransformer new];
    [NSValueTransformer setValueTransformer:nsArrayValueTransformer forName:SVNSArrayValueTransformer.name];
    [nsArrayValueTransformer release];
}

+ (NSValueTransformerName)name {
    return @"com.pookjw.SurfVideo.SVNSArrayValueTransformer";
}

+ (Class)transformedValueClass {
    return NSArray.class;
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
    NSArray *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:NSArray.class, NSNumber.class, nil] fromData:value error:&error];
    assert(!error);
    return result;
}

@end
