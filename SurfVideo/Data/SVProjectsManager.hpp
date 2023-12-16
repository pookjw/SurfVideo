//
//  SVProjectsManager.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>
#import <functional>
#import "SVTrack.hpp"
#import "SVVideoTrack.hpp"
#import "SVFootage.hpp"
#import "SVPHAssetFootage.hpp"
#import "SVClip.hpp"
#import "SVVideoClip.hpp"

NS_ASSUME_NONNULL_BEGIN

class SVProjectsManager {
public:
    static SVProjectsManager& getInstance() {
        static SVProjectsManager instance;
        return instance;
    }
    
    SVProjectsManager(const SVProjectsManager&) = delete;
    SVProjectsManager& operator=(const SVProjectsManager&) = delete;
    
    void context(void (^completionHandler)(NSManagedObjectContext * _Nullable context, NSError * _Nullable error));
private:
    SVProjectsManager();
    ~SVProjectsManager();
    
    bool _isInitialized;
    NSManagedObjectContext *_context;
    NSPersistentContainer *_container;
    dispatch_queue_t _queue;
    
    void initialize(NSError * __autoreleasing * _Nullable error);
    NSManagedObjectModel *v0_managedObjectModel();
};

NS_ASSUME_NONNULL_END
