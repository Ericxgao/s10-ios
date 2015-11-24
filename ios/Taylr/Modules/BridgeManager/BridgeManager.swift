//
//  BridgeManager.swift
//  Taylr
//
//  Created by Tony Xiao on 11/18/15.
//  Copyright © 2015 S10. All rights reserved.
//

import Foundation
import CocoaLumberjack
import ReactiveCocoa
import React

private let kRNSendAppEventNotificationName = "rnSendAppEvent"

enum NativeAppEvent : String {
    case RegisteredPushToken = "RegisteredPushToken"
    case NavigationPush = "Navigation.push"
    case NavigationPop = "Navigation.pop"
    case BranchInitialized = "Branch.initialized"
    case ProfileShowMoreOptions = "Profile.showMoreOptions"
}

extension NSObject {
    func rnSendAppEvent(name: NativeAppEvent, body: AnyObject?) {
        var userInfo: [String: AnyObject] = ["name": name.rawValue]
        userInfo["body"] = body
        NSNotificationCenter.defaultCenter()
            .postNotificationName(kRNSendAppEventNotificationName, object: self, userInfo: userInfo)
    }
}

@objc(TSBridgeManager)
class BridgeManager : NSObject {
    
    weak var bridge: RCTBridge?
    let azure = AzureClient()
    
    override init() {
        super.init()
        listenForNotification(kRNSendAppEventNotificationName).startWithNext { [weak self] note in
            if let dispatcher = self?.bridge?.eventDispatcher,
                let name = note.userInfo?["name"] as? String {
                    let body = note.userInfo?["body"]
                    DDLogInfo("Will send AppEvent \(name) body=\(body)")
                    dispatcher.sendAppEventWithName(name, body: body)
            }
        }
    }
}

// MARK: - BridgeManager JS API

extension BridgeManager {
    @objc func uploadToAzure(remoteURL: NSURL, localURL: NSURL, contentType: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        azure.put(remoteURL, file: localURL, contentType: contentType).promise(resolve, reject).start(Event.sink(error: { error in
            DDLogError("Unable to upload to azure \(remoteURL) \(error)")
        }, completed: {
            DDLogDebug("Successfully uploaded to azure \(remoteURL)")
        }))
    }
    
    @objc func getDefaultAccount(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(METAccount.defaultAccount()?.toJson())
    }
    
    @objc func setDefaultAccount(account: METAccount?) {
        METAccount.setDefaultAccount(account)
    }
}

enum RouteId : String {
    case Profile = "profile"
    case Conversation = "conversation"
}

extension UIViewController {
    func rnNavigationPush(routeId: RouteId, args: [String: AnyObject]) {
        rnSendAppEvent(.NavigationPush, body: ["routeId": routeId.rawValue, "args": args])
    }
    
    func rnNavigationPop() {
        rnSendAppEvent(.NavigationPop, body: nil)
    }
}

extension METAccount {
    func toJson() -> NSDictionary {
        return [
            "userId": userID,
            "resumeToken": resumeToken,
            "expiryDate": expiryDate?.timeIntervalSince1970 ?? NSNull()
        ]
    }
    
    class func fromJson(json: NSDictionary) -> METAccount? {
        guard let userID = json["userId"] as? String,
            let resumeToken = json["resumeToken"] as? String else {
                return nil
        }
        let expiryDate = RCTConvert.NSDate(json["expiryDate"])
        return Taylr.METAccount(userID: userID, resumeToken: resumeToken, expiryDate: expiryDate)
    }
}

extension RCTConvert {
    @objc class func METAccount(json: AnyObject?) -> Taylr.METAccount? {
        guard let json = json as? Foundation.NSDictionary else {
            return nil
        }
        return Taylr.METAccount.fromJson(json)
    }
}
