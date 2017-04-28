//
//  AppDelegate.m
//  dsfs
//
//  Created by yzk on 14-8-21.
//  Copyright (c) 2014年 cooperlink. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    application.applicationIconBadgeNumber = 0;
    [[UIApplication sharedApplication] cancelAllLocalNotifications]; //清除本地通知的缓存
    
    
    UIUserNotificationType type=UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
    UIUserNotificationSettings *setting=[UIUserNotificationSettings settingsForTypes:type categories:nil];
    [[UIApplication sharedApplication]registerUserNotificationSettings:setting];
    
    
    self.window.backgroundColor = [UIColor whiteColor];
    UIViewController *vc = [[UIViewController alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //在程序已经进入后台后保持程序运行
    [self remainRunBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self adjustBadgeNumberWithLocalNotification];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

//当程序在前台或点击通知进入应用时，会回调改方法
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    
    if (application.applicationState == UIApplicationStateActive) {
        if (notification)
        {
            [self adjustBadgeNumberWithLocalNotification];
        }
    }

//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"标题"
//                                                    message:notification.alertBody
//                                                   delegate:nil
//                                          cancelButtonTitle:@"确定"
//                                          otherButtonTitles:nil];
//    [alert show];
}

- (void)remainRunBackground
{
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
    {
        backgroundSupported = device.multitaskingSupported;
    }
    if (backgroundSupported && _bgTask==UIBackgroundTaskInvalid)
    {
        UIApplication *app = [UIApplication sharedApplication];
        _bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            while (app.applicationState==UIApplicationStateBackground && _bgTask!=UIBackgroundTaskInvalid  && [app backgroundTimeRemaining] > 10)
            {
                [NSThread sleepForTimeInterval:1];
                NSLog(@"background task %@ left time %d.", @(_bgTask), (int)[app backgroundTimeRemaining]);
                
                if ([app backgroundTimeRemaining] < 580)
                {
                    [self scheduleNotificationInterval:5];
                    break;
                }
            }
            
            NSLog(@"background task %@ finished.", @(_bgTask));
            [app endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
            
        });
    }
}

- (void)scheduleNotificationInterval:(int)interval
{
    NSDate *itemDate = [NSDate date];
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    localNotif.fireDate = [itemDate dateByAddingTimeInterval:interval];
    localNotif.timeZone = [NSTimeZone systemTimeZone];
    localNotif.alertBody = @"测试本地通知消息，后台提示功能。";
    localNotif.alertAction = NSLocalizedString(@"看你妹", nil);
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.repeatInterval = 0;
    localNotif.applicationIconBadgeNumber = [[[UIApplication sharedApplication] scheduledLocalNotifications] count]+1;
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"123" forKey:@"key"];
    localNotif.userInfo = infoDict;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

- (void)adjustBadgeNumberWithLocalNotification
{
    //这里注意，如果这样写，则会使通知栏里面的通知清空
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    //如果单纯这样写，则不会消失
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    int count =(int)[[[UIApplication sharedApplication] scheduledLocalNotifications] count];
    //[[UIApplication sharedApplication] scheduledLocalNotifications]为计划要发的通知（已经发出的不包含在内）
    if(count>0)
    {
        NSMutableArray *newarry= [NSMutableArray arrayWithCapacity:0];
        
        //1、修改已经添加进入系统，但是还没有发送出去的通知的badgeNumber
        for (int i=0; i<count; i++)
        {
            UILocalNotification *notif=[[[UIApplication sharedApplication] scheduledLocalNotifications] objectAtIndex:i];
            notif.applicationIconBadgeNumber=i+1;
            [newarry addObject:notif];
        }
        
        //2、取消系统中原来的全部的通知
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        //3、将修改过badgeNumber的重新添加进入系统
        if (newarry.count>0)
        {
            for (int i=0; i<newarry.count; i++)
            {
                UILocalNotification *notif = [newarry objectAtIndex:i];
                [[UIApplication sharedApplication] scheduleLocalNotification:notif];
            }
        }
    }
}



@end
