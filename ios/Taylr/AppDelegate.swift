//
//  AppDelegate.swift
//  Serendipity
//
//  Created by Tony Xiao on 1/24/15.
//  Copyright (c) 2015 Serendipity. All rights reserved.
//

import UIKit
import CocoaLumberjack
import React
import Branch
import FBSDKCoreKit
import NKRecorder
import Fabric
import DigitsKit
import Crashlytics
import LayerKit
import Branch

struct Dependencies {
    let env: Environment
    let config: AppConfig
    let logger: Logger
    let session: Session
    let analytics: Analytics
    let ouralabs: DDOuralabsLogger
    let crashlytics: DDCrashlyticsLogger
    let oneSignal: OneSingalProvider
    let branch: BranchProvider
    let amplitude: AmplitudeProvider
    let mixpanel: MixpanelProvider
    let intercom: IntercomProvider
    let segment: SegmentProvider
    let uxcam: UXCamProvider
    let layer: LayerService
    let appHubBuild: AHBuildManager
    
    init(launchOptions: [NSObject: AnyObject]?) {
        Fabric.with([Digits(), Crashlytics()])
        env = Environment()
        config = AppConfig(env: env)
        
        // MARK: Setup Logging
        logger = Logger()
        ouralabs = DDOuralabsLogger(apiKey: config.ouralabsKey, livetail: config.audience == .Dev)
        crashlytics = DDCrashlyticsLogger(crashlytics: Crashlytics.sharedInstance())
        crashlytics.logFormatter = TagLogFormatter()
        DDTTYLogger.sharedInstance().logFormatter = TagLogFormatter()
        DDASLLogger.sharedInstance().logFormatter = TagLogFormatter()
        #if Debug
            logger.addLogger(DDNSLogger(viewerHostName: env.devMachineIP))
//        logger.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
        #endif
        logger.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
        logger.addLogger(ouralabs)
        logger.addLogger(crashlytics)

        // MARK: Setup Session & Analytics
        session = Session(userDefaults: NSUserDefaults.standardUserDefaults(), env: env)
        
        // NOTE: When OneSignal inits it automatically calls application.registerForRemoteNotifications()
        oneSignal = OneSingalProvider(appId: config.oneSignalAppId, launchOptions: launchOptions)
        branch = BranchProvider(branchKey: config.branchKey)
        amplitude = AmplitudeProvider(apiKey: config.amplitude.apiKey)
        mixpanel = MixpanelProvider(apiToken: config.mixpanel.token, launchOptions: launchOptions)
        intercom = IntercomProvider(config: config)
        segment = SegmentProvider(writeKey: config.segmentWriteKey)
        uxcam = UXCamProvider(apiKey: config.uxcamKey)
        analytics = Analytics(session: session)
        analytics.addProviders([oneSignal, branch, amplitude, mixpanel, intercom, segment, uxcam, ouralabs, crashlytics])
        Analytics.defaultInstance = analytics
        
        // MARK: Setup Layer (used for receiving remote notifications and such)
        layer = LayerService(layerAppID: config.layerURL)
        
        // MARK: Setup AppHub (over the air app update)
        AppHub.setApplicationID(config.appHubApplicationId)
        appHubBuild = AppHub.buildManager()
        appHubBuild.cellularDownloadsEnabled = true
        appHubBuild.debugBuildsEnabled = (config.audience != .AppStore)
    }
}

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var deps: Dependencies!
    var bridge: RCTBridge!
    
    // MARK: Lifecycle
    
    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        Crashlytics.sharedInstance().delegate = self
        deps = Dependencies(launchOptions: launchOptions)
        DDLogInfo("SESSIONMARKER >>>>>>>> Application Will Launch <<<<<<<<")
        return true
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Start React Native app
        bridge = RCTBridge(delegate: self, launchOptions: launchOptions)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = RootViewController(bridge: bridge)
        window?.makeKeyAndVisible()
        
        deps.branch.branch.initSessionWithLaunchOptions(launchOptions) { params, error in
            DDLogInfo("Initialized branch session params=\(params) error=\(error)")
            self.rnSendAppEvent(.BranchInitialized, body: params)
        }
        deps.appHubBuild.fetchBuildWithCompletionHandler { build, error in
//            DDLogInfo("Fetched new build from app hub id=\(build.identifier) name=\(build.name) desc=\(build.buildDescription) date=\(build.creationDate)")
//            for version in build.compatibleIOSVersions { // Crashes right now...
//                DDLogDebug("\(build.name): Compat Version - \(version)")
//            }
        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        deps.analytics.appDidLaunch(launchOptions)

        // Pre-heat the camera if we can
        VideoMakerViewController.preloadRecorder()
        
        deps.session.appDidLaunch()
        DDLogInfo("SESSIONMARKER >>>>>>>> Application Did Launch <<<<<<<<", tag: [
            "devMachineIP": deps.env.devMachineIP ?? NSNull(),
            "deviceId": deps.env.deviceId,
            "deviceName": deps.env.deviceName,
            "previousBuild": deps.session.previousBuild ?? NSNull(),
            "currentBuild": deps.env.build
        ])
        return true
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        deps.analytics.appWillEnterForeground()
        DDLogInfo("SESSIONMARKER >>>>>>>> Application Will Enter Foreground <<<<<<<<")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        deps.analytics.appDidEnterBackground()
        DDLogInfo("SESSIONMARKER >>>>>>>> Application Did Background <<<<<<<<")
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0 // Clear notification first
        FBSDKAppEvents.activateApp()
    }
    
    // MARK: URL Handling

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        }
        return deps.branch.branch.handleDeepLink(url)
    }

    // MARK: Push Handling
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        DDLogInfo("Did register user notification settings \(notificationSettings)")
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        DDLogInfo("Registered for push \(deviceToken)")
        deps.analytics.appDidRegisterForPushToken(deviceToken)
        if let apsEnv = deps.env.apsEnvironment?.rawValue {
            let pushToken = deviceToken.hexString()
            rnSendAppEvent(.RegisteredPushToken, body: [
                "apsEnv": apsEnv,
                "deviceToken": pushToken
            ])
            deps.analytics.setUserProperties(["Push Token": pushToken])
        } else if !deps.env.isRunningInSimulator {
            DDLogError("Non-simulator build should have valid APS environment")
            // fatalError("Non-simulator build should have valid APS environment")
        }
        do {
            try deps.layer.layerClient.updateRemoteNotificationDeviceToken(deviceToken)
        } catch let error as NSError {
            DDLogError("Unable to update Layer with push token", tag: error)
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code != 3010 {
            DDLogError("Faild to register for push", tag: error)
        } else {
            DDLogWarn("Register for push is not supported in simulator")
        }
        deps.analytics.setUserProperties(["Push Token": NSNull()])
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        DDLogDebug("Did receive notification \(userInfo)")
        deps.analytics.appDidReceivePushNotification(userInfo)
        assert(deps != nil)
        let handled = deps.layer.layerClient.synchronizeWithRemoteNotification(userInfo) { changes, error in
            if let error = error {
                DDLogError("Failed to synchronize remote notification with layer", tag: error)
                completionHandler(.Failed)
            } else {
                let changes = changes ?? []
                DDLogInfo("Synchronized layer remote notification with \(changes.count) changes")
                if changes.count > 0 {
                    completionHandler(.NewData)
                } else {
                    completionHandler(.NoData)
                }
            }
        }
        if !handled {
            completionHandler(.NoData)
        }
    }

    // MARK: Background Transfer
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        deps.layer.layerClient.handleBackgroundContentTransfersForSession(identifier) { changes, error in
            if let error = error {
                DDLogError("Failed to handle layer background transfer", tag: error)
            } else {
                DDLogInfo("Handled layer background transfer with \(changes?.count) changes")
            }
            completionHandler()
        }
    }
}

// MARK: - RCTBridgeDelegate

extension AppDelegate : RCTBridgeDelegate {
    
    func sourceURLForBridge(bridge: RCTBridge!) -> NSURL! {
        if let devMachineIP = deps.env.devMachineIP {
            DDLogInfo("Will return ReactNative sourceURL hostname=\(devMachineIP)")
            return NSURL("http://\(devMachineIP):8081/index.ios.bundle?platform=ios&dev=true")
        } else if deps.env.isRunningInSimulator {
            return NSURL("http://localhost:8081/index.ios.bundle?platform=ios&dev=true")
        } else if deps.env.build == "0" {
            return NSBundle.mainBundle().URLForResource("main", withExtension: "jsbundle")
        } else {
            let build = deps.appHubBuild.currentBuild
            return build.bundle.URLForResource("main", withExtension: "jsbundle")
        }
    }
    
    func extraModulesForBridge(bridge: RCTBridge!) -> [AnyObject]! {
        // TODO: Move as many 'modules' from AppDependencies into here as possible
        // So that their lifecycle may be managed by bridge. Also implement RCTInvalidating
        return [
            ConversationListViewManager(layer: deps.layer, session: deps.session),
            ConversationViewManager(layer: deps.layer, session: deps.session),
            BridgeManager(env: deps.env, config: deps.config),
            deps.session,
            deps.analytics,
            deps.logger,
            deps.layer,
            deps.intercom,
        ]
    }
}

// MARK: - CrashlyticsDelegate

extension AppDelegate : CrashlyticsDelegate {
    func crashlyticsDidDetectReportForLastExecution(report: CLSReport, completionHandler: (Bool) -> Void) {
        DDLogError("Crash detected during last execution identifier=\(report.identifier)", tag: report.customKeys)
        deps.analytics.track("Crash Detected")
        completionHandler(true)
    }
}
