//
//  BlueToothEquipment.m
//  DefineTest
//
//  Created by 周浩 on 2018/8/29.
//  Copyright © 2018年 周浩. All rights reserved.
//

#import "HBlueTooth.h"

@interface HBlueTooth () <CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) CompeletFinishedBlock openSuccessed;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *myPeripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;//获取的characteristic
@end

@implementation HBlueTooth


- (void)sendData:(NSData *)data{
    [self.myPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
}

//初始化中心设备管理器
- (void)initCentralManager:(CompeletFinishedBlock)compeleted{
    self.openSuccessed = compeleted;
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

//创建完成CBCentralManager对象之后会回调的代理方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOff) {
        NSLog(@"系统蓝牙关闭了，请先打开蓝牙");
    }if (central.state == CBManagerStateUnauthorized) {
        NSLog(@"系统蓝未被授权");
    }if (central.state == CBManagerStateUnknown) {
        NSLog(@"系统蓝牙当前状态不明确");
    }if (central.state == CBManagerStateUnsupported) {
        NSLog(@"系统蓝牙设备不支持");
    }if (central.state == CBManagerStatePoweredOn) {
        NSLog(@"系统蓝牙设备开始扫描外设");
        //扫描外设
        //CBCentralManagerScanOptionAllowDuplicatesKey值为 No，表示不重复扫描已发现的设备
        NSDictionary *optionDic = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [_centralManager scanForPeripheralsWithServices:nil options:optionDic];//如果你将第一个参数设置为nil，Central Manager就会开始寻找所有的服务。
    }
}

//执行扫描的动作之后，如果扫描到外设了，就会自动回调下面的协议方法了

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    //根据名字有选择性地连接蓝牙设备
    NSLog(@"扫描到了设备 -> %@",peripheral.name);
    if([peripheral.name containsString:PERIPHERAL_NAME]){
        _myPeripheral = peripheral;
        _myPeripheral.delegate = self;
        //连接外设
        [_centralManager connectPeripheral:_myPeripheral options:nil];
    }
}

//如果连接成功，就会回调下面的协议方法了
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;{
    //停止中心管理设备的扫描动作，要不然在你和已经连接好的外设进行数据沟通时，如果又有一个外设进行广播且符合你的连接条件，那么你的iOS设备也会去连接这个设备（因为iOS BLE4.0是支持一对多连接的），导致数据的混乱。
    [_centralManager stopScan];
    
    //一次性读出外设的所有服务
    [_myPeripheral discoverServices:nil];
}

//掉线
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"掉线 %@",error);
    self.connect = NO;
}

//连接外设失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接外设失败 %@",error);
    self.connect = NO;
}

//一旦我们读取到外设的相关服务UUID就会回调下面的方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //到这里，说明你上面调用的  [_peripheral discoverServices:nil]; 方法起效果了，我们接着来找找特征值UUID
    NSLog(@"发现服务");
    for (CBService *s in [peripheral services]) {
        [peripheral discoverCharacteristics:nil forService:s];
    }
}

//如果我们成功读取某个特征值UUID，就会回调下面的方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;{
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        NSLog(@"特征 UUID: %@ (%@)", c.UUID.data, c.UUID);
        if ([[c UUID] isEqual:[CBUUID UUIDWithString:PERIPHERAL_UUID]]) {
            self.characteristic = c;
            self.myPeripheral = peripheral;
            NSLog(@"找到可读特征readPowerCharacteristic : %@", c);
            [peripheral setNotifyValue:YES forCharacteristic:c];
            self.connect = YES;
        }
    }
}

//向peripheral中写入数据后的回调函数
- (void)peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"write value success(写入成功) : %@", characteristic);
    [self.myPeripheral readValueForCharacteristic:characteristic];
}

//获取外设发来的数据,不论是read和notify,获取数据都从这个方法中读取
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //    [peripheral readRSSI];
    //    NSNumber* rssi = [peripheral RSSI];
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PERIPHERAL_UUID]]){
        self.receivedData = characteristic.value;
        NSString* value = [self hexadecimalString:self.receivedData];
        //        NSLog(@"characteristic(读取到的) : %@, data : %@, value : %@", characteristic, data, value);
        NSLog(@"didUpdateValueForCharacteristic(读取到的) value = %@",value);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices{
    NSLog(@"didModifyServices");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    NSLog(@"didUpdateValueForDescriptor");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSLog(@"didDiscoverDescriptorsForCharacteristic");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSLog(@"didUpdateNotificationStateForCharacteristic %@",characteristic);
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:PERIPHERAL_UUID]]){
        self.receivedData = characteristic.value;
        NSString* value = [self hexadecimalString:self.receivedData];
        NSLog(@"didUpdateValueForCharacteristic(读取到的) value = %@",value);
    }
}

#pragma mark - 主动断开和重连连接设备
/**
 * 断开连接
 */
- (void)cancelConnect{
    if (self.myPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.myPeripheral];
    }
    self.connect = NO;
}

/**
 * 重新连接
 */
- (void)reConnect{
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}




//将传入的NSData类型转换成NSString并返回
- (NSString*)hexadecimalString:(NSData *)data{
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
}

//将传入的NSString类型转换成ASCII码并返回
- (NSData *)dataWithString:(NSString *)string{
    unsigned char *bytes = (unsigned char *)[string UTF8String];
    NSInteger len = string.length;
    return [NSData dataWithBytes:bytes length:len];
}


@end
