# SurfVideo

## TODO

- dispatch_suspend, dispatch_resume

- Composition Track Segment를 Index 기반이 아닌, ID 기반으로

  - Migration을 위해 Core Data Model 생성, Mapping Model 생성

- Trimg Video/Audio

- Transform Caption

- iOS 지원

- Scene Restoration 지원

- Project Thumbnail에 Video Compositor 지원

- Export시 Crash 및 성능 수정

- SVLocalFileFootage *localFileFootage = [[SVLocalFileFootage alloc] initWithContext:managedObjectContext]; 매번 새로 만들어지는 문제

- TODO 주석들 전반적으로 다시 보기

- Queue가 2개여야함 dispatch_suspend를 이용해서

    - 작업이 시작될 때 dispatch_async(queue_1) -> dispatch_suspend로 다른 작업들은 기다리게
    - 작업이 진행되는 동안은 dispatch_async(queue_2)로 진행
    - 완료되면 queue_2에서 queue_1을 dispatch_resume
    - 반복
    - 절대 Lock을 걸지 말 것
