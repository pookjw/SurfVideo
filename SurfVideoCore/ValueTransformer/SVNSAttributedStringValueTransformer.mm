//
//  SVNSAttributedStringValueTransformer.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "SVNSAttributedStringValueTransformer.hpp"

@implementation SVNSAttributedStringValueTransformer

+ (void)load {
    SVNSAttributedStringValueTransformer *nsAttributedStringValueTransformer = [SVNSAttributedStringValueTransformer new];
    [NSValueTransformer setValueTransformer:nsAttributedStringValueTransformer forName:SVNSAttributedStringValueTransformer.name];
    [nsAttributedStringValueTransformer release];
}

+ (NSValueTransformerName)name {
    return @"com.pookjw.SurfVideo.SVNSAttributedStringValueTransformer";
}

+ (Class)transformedValueClass {
    return NSAttributedString.class;
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
    NSAttributedString *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObject:NSAttributedString.class] fromData:value error:&error];
    assert(!error);
    return result;
}

@end
