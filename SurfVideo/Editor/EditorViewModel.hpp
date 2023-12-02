//
//  EditorViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <Foundation/Foundation.h>
#import <memory>
#import "SVVideoProject.hpp"

NS_ASSUME_NONNULL_BEGIN

class EditorViewModel {
public:
    EditorViewModel(NSSet<NSUserActivity *> *userActivities);
    ~EditorViewModel();
    EditorViewModel(const EditorViewModel&) = delete;
    EditorViewModel& operator=(const EditorViewModel&) = delete;
    
    void initialize(std::shared_ptr<EditorViewModel> ref, void (^completionHandler)(NSError * _Nullable error));
private:
    dispatch_queue_t _queue;
    const NSSet<NSUserActivity *> *_userActivites;
};

NS_ASSUME_NONNULL_END
