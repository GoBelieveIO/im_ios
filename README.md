#gobelieve iOS
gobelieve iOS SDK

##生成demo的workspace
1. cp demo/dev.podspec ./
2. pod install

##应用集成到自己的客户端

1. podfile

        pod 'gobelieve', :git => 'https://github.com/GoBelieveIO/im_ios.git'

3. 在AppDelegate初始化deviceID以及message handler

        [IMService instance].deviceID = deviceID;
        [IMService instance].peerMessageHandler = [PeerMessageHandler instance];
        [IMService instance].groupMessageHandler = [GroupMessageHandler instance];
        [IMService instance].customerMessageHandler = [CustomerMessageHandler instance];

4. 在AppDelegate中监听系统网络变化

        -(void)startRechabilityNotifier {
            self.reach = [GOReachability reachabilityForInternetConnection];
            self.reach.reachableBlock = ^(GOReachability*reach) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"internet reachable");
                    [[IMService instance] onReachabilityChange:YES];
                });
            };
            
            self.reach.unreachableBlock = ^(GOReachability*reach) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"internet unreachable");
                    [[IMService instance] onReachabilityChange:NO];
                });
            };
            
            [self.reach startNotifier];

        }

        [self startRechabilityNotifier];
        [IMService instance].reachable = [self.reach isReachable];

5. 登录成功之后设置token和uid, token和uid从应用本身的登录接口获得

        [IMService instance].token = ""
        [PeerMessageHandler instance].uid = uid
        [GroupMessageHandler instance].uid = uid
        [CustomerMessageHandler instance].uid = uid

        SyncKeyHandler *handler = [[SyncKeyHandler alloc] initWithFileName:fileName];
        [IMService instance].syncKeyHandler = handler;

6. 初始化消息db

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:dbPath]) {
            NSString *p = [[NSBundle mainBundle] pathForResource:@"gobelieve" ofType:@"db"];
            [fileManager copyItemAtPath:p toPath:dbPath error:nil];
        }
        FMDatabase *db = [[FMDatabase alloc] initWithPath:dbPath];
        BOOL r = [db openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_WAL vfs:nil];
        if (!r) {
            NSLog(@"open database error:%@", [db lastError]);
            db = nil;
            NSAssert(NO, @"");
        }

        [PeerMessageDB instance].db = db;
        [GroupMessageDB instance].db = db;
        [CustomerMessageDB instance].db = db;

7. 启动IMService开始接受消息

        [[IMService instance] start];

8. 添加消息observer，处理相应类型的消息

        //连接状态
        [[IMService instance] addConnectionObserver:ob];

        //点对点消息
        [[IMService instance] addPeerMessageObserver:ob];
        //群组消息
        [[IMService instance] addGroupMessageObserver:ob];
        //直播的聊天室消息
        [[IMService instance] addRoomMessageObserver:ob];
        //实时消息,用于voip的信令
        [[IMService instance] addRTMessageObserver:ob];
        //系统消息
        [[IMService instance] addSystemMessageObserver:ob];

        
9. app进入后台,断开socket链接

        [[IMService instance] enterBackground];


10. app返回前台,重新链接socket
 
        [[IMService instance] enterForeground]; 

12. 发送点对点消息

        PeerMessageViewController* msgController = [[PeerMessageViewController alloc] init];
        msgController.peerUID = peerUID;
        msgController.peerName = @"";
        msgController.currentUID = uid;
        [self.navigationController pushViewController:msgController animated:YES];

13. 发送群组消息

        GroupMessageViewController* msgController = [[GroupMessageViewController alloc] init];
        msgController.groupID = groupID;
        msgController.groupName = @"";
        msgController.currentUID = uid;
        [self.navigationController pushViewController:msgController animated:YES];

14. 用户注销

        [[IMService instance] stop]