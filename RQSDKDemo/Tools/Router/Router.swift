//
//  Router.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 11/12/2023.
//

import Foundation

extension Router {
    enum ReceiveNotificationFrom {
        case background
        case front
    }
}

/// 路由: 负责跳转处理
/// 例如推送事件跳转
class Router {

    // 不是单例
//    static let shared: Router = .init()

    private init() {}
    
    /// 推送通知跳转处理
    /*
     2024/5/17 这是旧的一键呼叫APNS消息体, 1.3版本后加入新的, 旧的保留只为兼容旧固件旧设备
     事件 / 一键呼叫推送数据结构:
     https://alidocs.dingtalk.com/document/edit?docKey=1X3lE6Q15QRmnJbv&dentryKey=KDeD3kKvCPQ0llwy&type=d
     事件类型定义:
     https://alidocs.dingtalk.com/i/nodes/lyQod3RxJKXQEDRbTZK2lRAa8kb4Mw9r?utm_scene=person_space
     新版离线推送消息体文档
     https://alidocs.dingtalk.com/i/nodes/N7dx2rn0Jb2ajPMyijdjvbmwJMGjLRb3?utm_scene=team_space
     {
         "aps": {
             "alert": {
                 "title": "呼叫测试",
                 "subtitle": "subtitle",
                 "body": "body"
             },
             "sound": "receive_call.mp3"
         },
         "push_type": "DevAlmTrg",
         "push_data": {
             "DevId": 123,
             "EvtId": "123456",
             "TrgType": 1,
             "TrgTime": 1702281403,
             "DevCfg": 1
         }
     }
     */
    /*
     这是新的一键呼叫APNS消息体:
     {
        "push_type": SimplePush,
        "push_data": {
            deviceId = 12885484243;
            pushContent = {
                type = event;
                alarmId = 128854842431715934709;
                alarmType = 64;
                flag = 0;
                value = "";
            };
            pushTime = 1715934819587;
            pushType = 274877906944;
        },
        "aps": {
            alert = {
                body = "X11BBBBBBB:Requesting a call with you";
                title = "Device Alerts";
            };
            badge = 1;
            sound = {
                critical = 1;
                name = "receive_call.mp3";
                volume = 1;
            };
        }
     }
     */

    /*
     普通事件推送:
     {"push_data": {
         deviceId = 12885503603;
         pushContent =     {
             Type = event;
             alarmId = 128855036031717155102;
             alarmType = 2;
             flag = 0;
             value = "";
         };
         pushTime = 1717155111166;
         pushType = 274877906944;
     },
     "aps": {
         alert =     {
             body = "Reoqoo Smart Camera Pro:It was detected activity! Click to view";
             title = "Device Alerts";
         };
         badge = 1;
         sound =     {
             critical = 1;
             name = default;
             volume = 1;
         };
     }, 
     "push_type": SimplePush
     }
     */
    static func apnsHandling(notification: UNNotification, receiveFrom: ReceiveNotificationFrom) {
        let userInfo = notification.request.content.userInfo
        let userInfoJson = JSON.init(userInfo)
        // 事件推送 / 一键呼叫推送 (兼容旧固件)
        if let pushType = userInfoJson["push_type"].string, pushType == "DevAlmTrg" {
            let dev_id = userInfoJson["push_data"]["DevId"].stringValue
            let event_id = userInfoJson["push_data"]["EvtId"].stringValue
            let triggerTypeRawValue = userInfoJson["push_data"]["TrgType"].intValue
            let eventTimestamp = userInfoJson["push_data"]["TrgTime"].doubleValue
            
            // 取出设备
            guard let dev = DeviceManager2.fetchDevice(dev_id), let nav = AppEntranceManager.shared.keyWindow?.rootViewController as? BaseNavigationController, let vc = nav.rt_viewControllers.first else { return }
            
            let eventType = SurveillanceEventType.init(rawValue: triggerTypeRawValue)
            let alarmType = eventType.toAlarmType
            let targetViewEntryType: SurveillanceEntryType = alarmType == .keyCall ? .voip : .playback

            // 如果 前台收到推送 且 事件类型非一键呼叫, return
            if receiveFrom == .front && alarmType != .keyCall {
                return;
            }

            var surveillanceEvent = SurveillanceEvent.init(eventType: eventType, eventId: event_id, startTime: 0, endTime: 0, keyCallContent: "")
            // 如果是一键呼叫事件, 需要传 keyCallContent 参数, 否则会跳转到事件页
            if targetViewEntryType == .voip {
                surveillanceEvent.keyCallContent = "alarmId=" + event_id + "&alarmType=" + String(alarmType.rawValue) + "&code=" + "" + "&pts=" + String(Int(eventTimestamp))
            }
            RQCore.Agent.shared.openSurveillance(device: dev, triggerViewController: vc, entryViewType: targetViewEntryType, surveillanceEvent: surveillanceEvent)
            return
        }

        // 一键呼叫推送 (新)
        if let type = userInfoJson["push_data"]["pushContent"]["Type"].string,
           type == "event",
            let dev_id = userInfoJson["push_data"]["deviceId"].string,
           // == 274877906944 == 1 << 38
           let pushType = userInfoJson["push_data"]["pushType"].int,
            // == 64
           let alarmTypeRaw = userInfoJson["push_data"]["pushContent"]["alarmType"].int,
           let alarmId = userInfoJson["push_data"]["pushContent"]["alarmId"].string,
           let pushTime = userInfoJson["push_data"]["pushTime"].int,
           pushType == 1 << 38,
           alarmTypeRaw == SurveillanceEventType.voip.rawValue {
            // 取出设备
            guard let dev = DeviceManager2.fetchDevice(dev_id), let nav = AppEntranceManager.shared.keyWindow?.rootViewController as? BaseNavigationController, let vc = nav.rt_viewControllers.first else { return }

            let eventType = SurveillanceEventType.init(rawValue: alarmTypeRaw)
            let alarmType = SurveillanceEventType.init(rawValue: alarmTypeRaw).toAlarmType
            var event = SurveillanceEvent.init(eventType: eventType, eventId: alarmId, startTime: 0, endTime: 0, keyCallContent: "")
            // 如果是一键呼叫事件, 需要传 keyCallContent 参数, 否则会跳转到事件页
            event.keyCallContent = "alarmId=" + alarmId + "&alarmType=" + String(alarmType.rawValue) + "&code=" + "" + "&pts=" + String(Int(pushTime))
            RQCore.Agent.shared.openSurveillance(device: dev, triggerViewController: vc, entryViewType: .voip, surveillanceEvent: event)
            return
        }

        // 普通事件推送
        // 从后台收到, 进入插件云回放
        if receiveFrom == .background,
           let type = userInfoJson["push_data"]["pushContent"]["Type"].string,
           type == "event",
           let dev_id = userInfoJson["push_data"]["deviceId"].string,
           // == 274877906944 == 1 << 38
           let pushType = userInfoJson["push_data"]["pushType"].int,
           let alarmTypeRaw = userInfoJson["push_data"]["pushContent"]["alarmType"].int,
           let alarmId = userInfoJson["push_data"]["pushContent"]["alarmId"].string,
           pushType == 1 << 38
        {
            // 取出设备
            guard let dev = DeviceManager2.fetchDevice(dev_id), let nav = AppEntranceManager.shared.keyWindow?.rootViewController as? BaseNavigationController, let vc = nav.rt_viewControllers.first else { return }
            let eventType = SurveillanceEventType.init(rawValue: alarmTypeRaw)
            let event = SurveillanceEvent.init(eventType: eventType, eventId: alarmId, startTime: 0, endTime: 0, keyCallContent: "")
            RQCore.Agent.shared.openSurveillance(device: dev, triggerViewController: vc, entryViewType: .playback, surveillanceEvent: event)
            return
        }
    }

    // 本地测试接收到离线推送用
    static func apnsHandling(userInfoJson: JSON, receiveFrom: ReceiveNotificationFrom) {
        // 普通事件推送
        // 从后台收到, 进入插件云回放
        if receiveFrom == .background,
           let type = userInfoJson["push_data"]["pushContent"]["Type"].string,
           type == "event",
           let dev_id = userInfoJson["push_data"]["deviceId"].string,
           // == 274877906944
           let pushType = userInfoJson["push_data"]["pushType"].int,
           let alarmTypeRaw = userInfoJson["push_data"]["pushContent"]["alarmType"].int,
           let alarmId = userInfoJson["push_data"]["pushContent"]["alarmId"].string,
           pushType == 274877906944
        {
            // 取出设备
            guard let dev = DeviceManager2.fetchDevice(dev_id), let nav = AppEntranceManager.shared.keyWindow?.rootViewController as? BaseNavigationController, let vc = nav.rt_viewControllers.first else { return }
            let eventType = SurveillanceEventType.init(rawValue: alarmTypeRaw)
            let event = SurveillanceEvent.init(eventType: eventType, eventId: alarmId, startTime: 0, endTime: 0, keyCallContent: "")
            RQCore.Agent.shared.openSurveillance(device: dev, triggerViewController: vc, entryViewType: .playback, surveillanceEvent: event)
        }
    }
}
