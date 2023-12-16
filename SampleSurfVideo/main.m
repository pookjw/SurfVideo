//
//  main.m
//  SampleSurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSURL *momURL = [NSBundle.mainBundle URLForResource:@"Model" withExtension:@"mom" subdirectory:@"Model.momd"];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
        
        [model.entities enumerateObjectsUsingBlock:^(NSEntityDescription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSLog(@"============ %@ ============", obj);
            [obj.properties enumerateObjectsUsingBlock:^(__kindof NSPropertyDescription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                NSLog(@"%@", obj);
                
                if ([obj isKindOfClass:NSDerivedAttributeDescription.class]) {
                    NSDerivedAttributeDescription *dea = (NSDerivedAttributeDescription *)obj;
                    NSLog(@"%@", dea);
                    NSLog(@"%@", dea.derivationExpression);
                    NSLog(@"%@", ((NSExpression *)dea.derivationExpression.arguments.firstObject).keyPath);
                    NSLog(@"%@", dea.derivationExpression.function);
                }
            }];
        }];
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
