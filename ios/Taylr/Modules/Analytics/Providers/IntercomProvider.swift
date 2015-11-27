//
//  IntercomProvider.swift
//  Taylr
//
//  Created by Tony Xiao on 11/22/15.
//  Copyright © 2015 S10. All rights reserved.
//

import Foundation
import Intercom
import CocoaLumberjack
import UXCam

// TODO: Add more information to Intercom
// https://doc.intercom.io/api/#user-model
// Ampiltude URL
// Ouralabs URL (damn it...)
// Crashlytics URL?
// Branch URL?
// Segment URL?

@objc(TSIntercomProvider)
public class IntercomProvider : BaseAnalyticsProvider {

    let config: AppConfig
    
    init(config: AppConfig) {
        self.config = config
        Intercom.setApiKey(config.intercom.apiKey, forAppId: config.intercom.appId)
    }
    
    override func updateIdentity() {
        if let userId = context.userId {
            if let email = context.email {
                Intercom.registerUserWithUserId(userId, email: email)
            } else {
                Intercom.registerUserWithUserId(userId)
            }
            setUserProperties(["Taylr URL": "https://\(config.serverHostName)/admin/users/\(userId)"])
        } else {
            Intercom.registerUnidentifiedUser()
        }
        setUserProperties([
            "Device ID": context.deviceId,
            "Device Name": context.deviceName,
            "Mixpanel URL": "https://mixpanel.com/report/\(config.mixpanel.projectId)/explore/#user?distinct_id=\(context.deviceId)",
            "Amplitude URL": "https://amplitude.com/app/\(config.amplitude.appId)/activity/search?userId=\(context.userId ?? context.deviceId)"
        ])
        // Explicit dependency please
        OneSignal.defaultClient().IdsAvailable { [weak self] userId, _ in
            self?.setUserProperties(["OneSignal UserID": userId])
        }
    }
    
    override func appLaunch() {
        updateIdentity()
    }
    
    override func appOpen() { }
    
    override func appClose() {
        if let url = UXCam.urlForCurrentUser() {
            setUserProperties(["UXCam URL": "http://\(url)"])
        }
    }
    
    override func login(isNewUser: Bool) {
        updateIdentity()
        track("Login", properties: ["New User": isNewUser])
    }
    
    override func logout() {
        track("Logout")
        Intercom.reset()
        updateIdentity()
    }
    
    override func updateEmail() {
        Intercom.updateUserWithAttributes(["email": context.email ?? NSNull()])
    }
    
    override func updateFullname() {
        Intercom.updateUserWithAttributes(["name": context.fullname ?? NSNull()])
    }
    
    override func setUserProperties(properties: [NSObject : AnyObject]) {
        DDLogDebug("Intercom setUserProperties properties=\(properties)")
        Intercom.updateUserWithAttributes(["custom_attributes": properties])
    }
    
    override func track(event: String, properties: [NSObject : AnyObject]? = nil) {
        if let properties = properties {
            Intercom.logEventWithName(event, metaData: properties)
        } else {
            Intercom.logEventWithName(event)
        }
    }
    
    override func screen(name: String, properties: [NSObject : AnyObject]? = nil) {
        // Intentionally nil, do not track screens in Intercom
    }
    
    func registerPushToken(pushToken: NSData) {
        Intercom.setDeviceToken(pushToken)
    }
}

// MARK: - JS API

extension Intercom {
    
    @objc func presentMessageComposer() {
        dispatch_async(dispatch_get_main_queue()) {
            Intercom.presentMessageComposer()
        }
    }
    
    @objc func presentConversationList() {
        dispatch_async(dispatch_get_main_queue()) {
            Intercom.presentConversationList()
        }
    }
}
