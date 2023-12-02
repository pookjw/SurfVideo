//
//  FetchedResultsControllerDelegate.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "FetchedResultsControllerDelegate.hpp"

@implementation FetchedResultsControllerDelegate

- (void)dealloc {
    [_didChangeContentWithSnapshotHandler release];
    [super dealloc];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeContentWithSnapshot:(NSDiffableDataSourceSnapshot<NSString *,NSManagedObjectID *> *)snapshot {
    self.didChangeContentWithSnapshotHandler(controller, snapshot);
}

@end
