//
//  AnalyticsService.swift
//  Taylr
//
//  Created by Tony Xiao on 4/15/15.
//  Copyright (c) 2015 S10 Inc. All rights reserved.
//

import Foundation
import ReactiveCocoa
import AnalyticsSwift
import Amplitude_iOS
import Mixpanel

public class CurrentUser {
    public enum AccountStatus : String {
        case Pending = "pending"
        case Active = "active"
    }
    
    // CurrentUser
    public let userId: PropertyOf<String?>
    public let firstName: PropertyOf<String?>
    public let lastName: PropertyOf<String?>
    public let gradYear: PropertyOf<String?>
    
    public init() {
        userId = PropertyOf(nil)
        firstName = PropertyOf(nil)
        lastName = PropertyOf(nil)
        gradYear = PropertyOf(nil)
    }
}

@objc(TSAnalytics)
class AnalyticsService : NSObject {
    private let env: Environment
    private let currentUser: CurrentUser
    private let segment: AnalyticsSwift.Analytics
    private let amplitude: Amplitude
    private let mixpanel: Mixpanel

    private let cd = CompositeDisposable()

    init(config: AppConfig, env: Environment) {
        self.env = env
        self.currentUser = CurrentUser()
        segment = AnalyticsSwift.Analytics.create(config.segmentWriteKey)
        amplitude = Amplitude.instance()
        amplitude.trackingSessionEvents = true
        amplitude.initializeApiKey(config.amplitudeKey)
        mixpanel = Mixpanel.sharedInstanceWithToken(config.mixpanelToken)
        super.init()
        if env.build != "0" {
            UXCam.startWithKey(config.uxcamKey)
        }
        
        cd += currentUser.userId.producer.startWithNext { [weak self] userId in
            self?.identify(userId)
        }
        let propertyList = [
            "First Name": currentUser.firstName,
            "Last Name": currentUser.lastName,
            "Grad Year": currentUser.gradYear
        ]
        for (name, property) in propertyList {
            cd += property.producer.startWithNext { [weak self] value in
                if let value = value {
                    self?.setUserProperties([name: value])
                }
            }
        }
        setUserProperties(["TestFlightBeta": env.isRunningTestFlightBeta])
        setUserProperties(["Audience": config.audience.rawValue])
        
    }

    deinit {
        cd.dispose()
    }

    private func identify(userId: String?) {
        if let userId = currentUser.userId.value {
            segment.enqueue(IdentifyMessageBuilder().userId(userId))
            mixpanel.identify(userId)
            amplitude.setUserId(userId)
        } else {
            segment.enqueue(IdentifyMessageBuilder().anonymousId(env.deviceId))
            mixpanel.identify(env.deviceId)
//            amplitude.setUserId(nil) // Setting this to nil leads to Perma crash. So let's not set to nil
            // Also we probably would benefit from less reactivity and more just simple logic
        }
        Log.verbose("[analytics] identify \(userId)")
        flush()
    }

    func setUserProperties(properties: [String: AnyObject]) {
        let msg = IdentifyMessageBuilder().traits(properties)
        if let userId = currentUser.userId.value {
            segment.enqueue(msg.userId(userId))
        } else {
            segment.enqueue(msg.anonymousId(env.deviceId))
        }
        amplitude.setUserProperties(properties, replace: true)
        Log.verbose("[analytics] setUserProperties: \(properties)")
        // Only track properties to mixpanel post-digits login
        if let userId = currentUser.userId.value where userId == mixpanel.distinctId {
            var props = properties
            props["$first_name"] = props.removeValueForKey("First Name")
            props["$last_name"] = props.removeValueForKey("Last Name")
            mixpanel.people.set(props)
        }
        flush()
    }
    
    @objc func track(event: String, properties: [String: AnyObject]? = nil) {
        let msg = TrackMessageBuilder(event: event).properties(properties ?? [:])
        if let userId = currentUser.userId.value {
            segment.enqueue(msg.userId(userId))
        } else {
            segment.enqueue(msg.anonymousId(env.deviceId))
        }
        amplitude.logEvent(event, withEventProperties: properties)
        // Only track events to mixpanel post-digits login
        if let userId = currentUser.userId.value where userId == mixpanel.distinctId {
            mixpanel.track(event, properties: properties)
        }
        Log.verbose("[analytics] track '\(event)' properties: \(properties)")
        flush()
    }

    func flush() {
        segment.flush()
        amplitude.uploadEvents()
        mixpanel.flush()
    }
}
