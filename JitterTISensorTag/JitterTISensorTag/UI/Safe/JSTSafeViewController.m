//
// Created by Blazej Marcinkiewicz on 25/01/15.
// ***REMOVED***
//

#import "JSTSafeViewController.h"
#import "JSTSensorManager.h"
#import "JSTAppDelegate.h"
#import "JSTSensorTag.h"
#import "JSTGyroscopeSensor.h"
#import "JSTSafeView.h"
#import "JSTSafe.h"
#import "JSTSafeCombinationValue.h"

@interface JSTSafeViewController ()
@property(nonatomic, strong) JSTSensorManager *sensorManager;
@property(nonatomic, strong) JSTSensorTag *sensor;
@property(nonatomic) BOOL isCalibrated;
@property(nonatomic) float lastRead;
@property(nonatomic) float currentRead;
@property(nonatomic) float currentValue;
@property(nonatomic) int resetCounter;
@property(nonatomic, strong) NSArray *values;
@property(nonatomic, strong) JSTSafe *safe;
@end

@implementation JSTSafeViewController {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sensorManager = [JSTSensorManager sharedInstance];
        self.sensorManager.delegate = self;

        JSTSafeCombinationValue *value1 = [[JSTSafeCombinationValue alloc] init];
        value1.direction = JSTSafeRotationDirectionLeft;
        value1.rotationValue = 18;

        JSTSafeCombinationValue *value2 = [[JSTSafeCombinationValue alloc] init];
        value2.direction = JSTSafeRotationDirectionRight;
        value2.rotationValue = 3;

        self.safe = [[JSTSafe alloc] initWithCombinationValue:@[value1, value2]];
    }

    return self;
}

- (void)dealloc {
    self.sensor.gyroscopeSensor.sensorDelegate = nil;
    [self.sensorManager disconnectSensor:self.sensor];
}

- (void)loadView {
    self.view = [[JSTSafeView alloc] init];
}

- (JSTSafeView *)safeView {
    if (self.isViewLoaded) {
        return (JSTSafeView *) self.view;
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.sensorManager.state == CBCentralManagerStatePoweredOn) {
        if ([self.sensorManager hasPreviouslyConnectedSensor]) {
            [self.sensorManager connectLastSensor];
        } else {
            [self.sensorManager connectNearestSensor];
        }
    }
}

#pragma mark - Sensor manager delegate

- (void)manager:(JSTSensorManager *)manager didConnectSensor:(JSTSensorTag *)sensor {
    self.sensor = sensor;
    sensor.gyroscopeSensor.sensorDelegate = self;
    [sensor.gyroscopeSensor configureWithValue:JSTSensorGyroscopeAllAxis];
    [sensor.gyroscopeSensor setPeriodValue:10];
    [sensor.gyroscopeSensor setNotificationsEnabled:YES];
}

- (void)manager:(JSTSensorManager *)manager didDisconnectSensor:(JSTSensorTag *)sensor {

}

- (void)manager:(JSTSensorManager *)manager didFailToConnectToSensorWithError:(NSError *)error {

}

- (void)manager:(JSTSensorManager *)manager didDiscoverSensor:(JSTSensorTag *)sensor {

}

- (void)manager:(JSTSensorManager *)manager didChangeStateTo:(CBCentralManagerState)state {
    if (manager.state == CBCentralManagerStatePoweredOn) {
        if ([manager hasPreviouslyConnectedSensor]) {
            [manager connectLastSensor];
        } else {
            [manager connectNearestSensor];
        }
    }
}

#pragma mark - Sensor delegate

- (void)sensorDidUpdateValue:(JSTBaseSensor *)sensor {
    if ([sensor isKindOfClass:[JSTGyroscopeSensor class]]) {
        JSTGyroscopeSensor *gyroscopeSensor = (JSTGyroscopeSensor *) sensor;
        if (!self.isCalibrated) {
            self.isCalibrated = YES;
            [gyroscopeSensor calibrate];
        } else {
            [self.safe updateWithRead:gyroscopeSensor.value.z];

            __weak JSTSafeViewController *weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{

                NSMutableString *valuesString = [[NSMutableString alloc] init];
                for (JSTSafeCombinationValue *value in [self.safe.values copy]) {
                    [valuesString appendString:[NSString stringWithFormat:@"%@ %@-", value.direction == JSTSafeRotationDirectionLeft ? @"L" : @"R", @(value.rotationValue)]];
                }
                if (valuesString.length > 0) {
                    [valuesString replaceCharactersInRange:NSMakeRange([valuesString length] - 1, 1) withString:@""];
                }
                weakSelf.safeView.resultLabel.text = [NSString stringWithFormat:@"%d %@", self.safe.currentSafeValue, self.safe.isCombinationCorrect ? @"YES" : @"NO"];

                weakSelf.safeView.rotationLabel.text = valuesString;
                [weakSelf.safeView setNeedsLayout];
            });
        }
    }
}

- (void)sensorDidFailCommunicating:(JSTBaseSensor *)sensor withError:(NSError *)error {

}

- (void)sensorDidFinishCalibration:(JSTBaseSensor *)sensor {

}

@end