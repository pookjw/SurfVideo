//
//  EditorMenuOrnamentViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/3/23.
//

#import "EditorMenuOrnamentViewController.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

@interface EditorMenuOrnamentViewController ()

@end

@implementation EditorMenuOrnamentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    reinterpret_cast<void (*)(id, SEL, long)>(objc_msgSend)(self.view, NSSelectorFromString(@"sws_enablePlatter:"), 8);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
