////
////  ARPhotoPickerViewController+CellLayout.swift
////  SurfVideo_UIKit
////
////  Created by Jinwoo Kim on 6/10/24.
////
//
//#if os(iOS) && !targetEnvironment(simulator)
//
//extension ARPhotoPickerViewController {
//    enum CellLayout {
//        /*
//         +----------------------------------------------+
//         |                                              |
//         | <-1-> +----+ <-2-> +----+ <-2-> +----+ <-1-> |
//         |       |    |       |    |       |    |       |
//         |       |    |       |    |       |    |       |
//         |       +----+       +----+       +----+       |
//         |       ^            ^            ^            |
//         |       |            |            |            |
//         |       2            2            2            |
//         |       |            |            |            |
//         |       v            v            v            |
//         |       +----+       +----+       +----+       |
//         |       |    |       |    |       |    |       |
//         |       |    |       |    |       |    |       |
//         |       +----+       +----+       +----+       |
//         |       <-3->        <-3->        <-3->        |
//         +----------------------------------------------+
//         
//         1 : containerPadding
//         2 : cellPadding
//         3 : cellSize
//         */
//        
//        static let containerPadding: Float = 0.05
//        static let cellPadding: Float = 0.003
//        static let cellSize: Float = 0.1
//        static let lineCount: Int = 6
//        static let containerSize: Float = containerPadding + cellSize * Float(lineCount) + cellPadding * Float(lineCount + 1)
//    }
//}
//
//#endif
