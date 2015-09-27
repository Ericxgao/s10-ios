//
//  MeteorService.swift
//  Taylr
//
//  Created by Tony Xiao on 4/10/15.
//  Copyright (c) 2015 S10 Inc. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveCocoa
import SugarRecord
import Meteor

public class MeteorService : NSObject {
    public let meteor: METCoreDataDDPClient // TODO: MAKE PRIVATE
    private var mainContext : NSManagedObjectContext { return meteor.mainQueueManagedObjectContext }
    private let _user = MutableProperty<User?>(nil)
    
    public let account: PropertyOf<METAccount?>
    public let connectionStatus: PropertyOf<METDDPConnectionStatus>
    public let loggedIn: PropertyOf<Bool>
    public let userId: PropertyOf<String?>
    public let settings: Settings
    public var offline: Bool { return !meteor.networkReachable }
    let user: PropertyOf<User?>

    public init(serverURL: NSURL) {
        let bundle = NSBundle(forClass: MeteorService.self)
        let model = NSManagedObjectModel.mergedModelFromBundles([bundle])
        meteor = METCoreDataDDPClient(serverURL: serverURL, account: nil, managedObjectModel: model)
        account = meteor.dyn("account").optional(METAccount).readonly()
        connectionStatus = meteor.dyn("connectionStatus").force(NSNumber)
            .map { METDDPConnectionStatus(rawValue: Int($0.intValue))! }
        user = PropertyOf(nil, _user.producer.observeOn(UIScheduler()))
        loggedIn = user.map { $0 != nil }
        userId = user.map { $0?.documentID }
        let name = "settings"
        let c = MeteorCollection(meteor.database.collectionWithName(name))
        let s = MeteorSubscription(meteor: meteor, subscription: meteor.addSubscriptionWithName(name))
        settings = Settings(collection: c, subscription: s)
        super.init()
        meteor.delegate = self
        SugarRecord.addStack(MeteorCDStack(meteor: meteor))
    }

    public func startup() {
        meteor.account = METAccount.defaultAccount()
        meteor.connect()
    }

    // MARK: - Publications & Collections & RPC

    func collection(name: String) -> MeteorCollection {
        return MeteorCollection(meteor.database.collectionWithName(name))
    }
    
    func subscribe(name: String, _ params: AnyObject...) -> MeteorSubscription {
        let sub = meteor.addSubscriptionWithName(name, parameters: params)
        return MeteorSubscription(meteor: meteor, subscription: sub)
    }
    
    public func call(name: String, _ params: AnyObject...) -> MeteorMethod {
        let promise = Promise<AnyObject?, NSError>()
        return MeteorMethod(stubValue: meteor.callMethodWithName(name, parameters: params) { res, error in
            if let error = error {
                promise.failure(error)
            } else {
                promise.success(res)
            }
        }, future: promise.future)
    }

    // MARK: - Device

    func connectDevice(env: Environment) -> RACSignal {
        // Technically this should be a barrier method, but barrier is not exposed by meteor-ios at the moment
        return meteor.call("connectDevice", [env.deviceId, [
            "appId": env.appId,
            "version": env.version,
            "build": env.build
        ]])
    }

    public func updateDevicePush(apsEnv: String, pushToken: String? = nil) -> MeteorMethod {
        return call("device/update/push", [
            "apsEnv": apsEnv,
            "pushToken": pushToken ?? NSNull()
        ])
    }

    public func updateDeviceLocation(location: CLLocation) -> RACSignal {
        return meteor.call("device/update/location", [[
            "lat": location.coordinate.latitude,
            "long": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "timestamp": location.timestamp
        ]])
    }

    // TODO: Add permission statuses for push, location, etc

    // MARK: - Authentication
    func login(method method: String, params: [AnyObject]?) -> RACSignal {
        // HACK ALERT: Delegate callback does not happen in time for Meteor.user
        // to be populated by the time completion gets called.
        // Instead we will force compute the user before returning signal
        return meteor.loginWithMethod(method, params: params).doCompleted {
            if let userId = self.meteor.userID {
                self._user.value = self.mainContext.objectInCollection("users", documentID: userId) as? User
            }
        }
    }

    public func debugLoginWithUserId(userId: String) -> RACSignal {
        return login(method: "login", params: [[
            "debug": ["userId": userId]
        ]])
    }

    public func loginWithDigits(userId userId: String, authToken: String, authTokenSecret: String, phoneNumber: String) -> RACSignal {
        return login(method: "login", params: [[
            "digits": [
                "userId": userId,
                "authToken": authToken,
                "authTokenSecret": authTokenSecret,
                "phoneNumber": phoneNumber
            ]
        ]]).delay(0.1)
    }

    func verifyCode(code: String) -> RACSignal {
        return meteor.call("confirmInviteCode", [code])
    }

    func confirmRegistration() -> RACSignal {
        return meteor.call("confirmRegistration", [])
    }

    func loginWithFacebook(accessToken accessToken: String, expiresAt: NSDate) -> RACSignal {
        return login(method: "login", params: [[
            "fb-access": [
                "accessToken": accessToken,
                "expireAt": expiresAt.timeIntervalSince1970
            ]
        ]])
    }

    public func loginWithPhoneNumber(phoneNumber: String) -> RACSignal {
        return login(method: "login", params: [[
            "phone-access": [
                "id": phoneNumber,
            ]
        ]])
    }

    public func logout() -> RACSignal {
        meteor.account = nil // No reason to wait for network to clear account
        return meteor.logout()
    }

    public func deleteAccount() -> RACSignal {
        return meteor.call("deleteAccount")
    }

    // MARK: - Services

    public func addService(serviceTypeId: String, accessToken: String) -> RACSignal {
        return meteor.call("me/service/add", [serviceTypeId, accessToken])
    }

    func removeService(serviceId: String) -> RACSignal {
        return meteor.call("me/service/remove", [serviceId])
    }

    // MARK: - Profile

    func updateProfile(values: NSDictionary) -> RACSignal {
        return meteor.call("me/update", [values])
    }

    // MARK: - Candidates

    func hideUser(user: User) -> RACSignal {
        return meteor.call("user/hide", [user], stub: {
            user.delete()
            return nil
        })
    }

    // MARK: - Users

    func nudgeUser(user: User) -> RACSignal {
        return meteor.call("user/action", [user, "nudge"], stub: {
            return nil
        })
    }

    func blockUser(user: User) -> RACSignal {
        return meteor.call("user/block", [user])
    }

    func reportUser(user: User, reason: String) -> RACSignal {
        return meteor.call("user/report", [user, reason])
    }

    // MARK: - Messages
    
    func expireMessages(messages: [Message]) -> RACSignal {
        return meteor.call("messages/expire", [messages.map { $0.documentID! }]) {
            let context = messages.first?.context()
            context?.beginWriting()
            for message in messages {
                let connection = message.connection
                let estimatedUnreadCount = (connection.unreadCount?.integerValue ?? 1) - 1
                connection.unreadCount = max(estimatedUnreadCount, 0)
                connection.updatedAt = NSDate()
                message.delete()
            }
            context?.endWriting()
            return nil
        }
    }

    // MARK: - Tasks

    func startVideoMessageTask(taskId: String, recipientId: String) -> RACSignal {
        return meteor.call("task/start", [taskId, "VideoMessage", ["recipientId": recipientId]])
    }

    func startInviteTask(taskId: String, recipientInfo: String) -> RACSignal {
        return meteor.call("task/start", [taskId, "Invite", ["recipientInfo": recipientInfo]])
    }

    func startProfilePicTask(taskId: String) -> RACSignal {
        return meteor.call("startTask", [taskId, "PROFILE_PIC"])
    }

    func finishTask(taskId: String) -> RACSignal {
        return meteor.call("finishTask", [taskId])
    }

    func startTask(taskId: String, type: String, metadata: NSDictionary) -> RACSignal {
        return meteor.call("startTask", [taskId, type, metadata])
    }

}

extension MeteorService : METDDPClientDelegate {
    // MARK: Meteor Logging

    public func client(client: METDDPClient, willSendDDPMessage message: [NSObject : AnyObject]) {
        Log.verbose("DDP > \(message)")
    }
    public func client(client: METDDPClient, didReceiveDDPMessage message: [NSObject : AnyObject]) {
        Log.verbose("DDP < \(message)")
    }

    public func client(client: METDDPClient, didSucceedLoginToAccount account: METAccount) {
        let user = self.mainContext.objectInCollection("users", documentID: account.userID) as? User
        assert(user != nil, "User must exist after account logs in")
        _user.value = user
    }

    public func client(client: METDDPClient, didFailLoginWithWithError error: NSError) {
        _user.value = nil
    }

    public func clientDidLogout(client: METDDPClient) {
        _user.value = nil
    }
}
