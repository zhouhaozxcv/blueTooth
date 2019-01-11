//
//  BlueToothEquipment.h
//  DefineTest
//
//  Created by 周浩 on 2018/8/29.
//  Copyright © 2018年 周浩. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define PERIPHERAL_NAME      @"BK3260 BLE"
#define PERIPHERAL_UUID      @"FFF4"

typedef void(^CompeletFinishedBlock)(id x);

@interface HBlueTooth : NSObject

@property (nonatomic) BOOL connect;///<是否连接状态
@property (nonatomic) NSData *receivedData;///<接收到的数据data

///初始化中心设备管理器
- (void)initCentralManager:(CompeletFinishedBlock)compeleted;

///发送数据
- (void)sendData:(NSData *)data;

///取消连接
- (void)cancelConnect;

///重新连接
- (void)reConnect;

@end
