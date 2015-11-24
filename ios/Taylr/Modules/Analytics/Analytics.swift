//
//  Analytics.swift
//  Taylr
//
//  Created by Tony Xiao on 11/18/15.
//  Copyright © 2015 S10. All rights reserved.
//

import Foundation
import CocoaLumberjack

public let Analytics = TSAnalytics()

@objc(TSAnalytics)
public class TSAnalytics : NSObject {
    var providers: [AnalyticsProvider] = []
    
    @objc func identify(userId: String) {
        for provider in providers {
            provider.identifyUser?(userId)
        }
        DDLogInfo("Identify userId=\(userId)")
    }
    
    @objc func track(event: String, properties: [String: AnyObject]? = nil) {
        for provider in providers {
            provider.track?(event, properties: properties)
        }
        DDLogDebug("Track event=\(event) properties=\(properties)")
    }
    
    @objc func setUserProperties(properties: [String: AnyObject]? = nil) {
        guard let properties = properties else {
            return
        }
        for provider in providers {
            provider.setUserProperties?(properties)
        }
        DDLogDebug("Set user properties=\(properties)")
    }
    
    @objc func incrementUserProperty(propertyName: String, amount: NSNumber) {
        for provider in providers {
            provider.incrementUserProperty?(propertyName, amount: amount)
        }
        DDLogDebug("Increment user property name=\(propertyName) amount=\(amount)")
    }
    

}
