//
//  LoginViewController.swift
//  Serendipity
//
//  Created by Tony Xiao on 1/28/15.
//  Copyright (c) 2015 Serendipity. All rights reserved.
//

import Foundation
import PKHUD
import DigitsKit
import ReactiveCocoa
import Meteor
import Bond
import Core

class LoginViewController : BaseViewController {

    @IBOutlet weak var loginButton: DesignableButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    let vm = LoginViewModel(delegate: Globals.accountService)
    
    override func commonInit() {
        screenName = "Signup"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vm.loginButtonText ->> loginButton.titleBond
        vm.logoutButtonText ->> logoutButton.titleBond
        vm.loginAction <~ loginButton
        vm.logoutAction <~ logoutButton
        
        vm.loginAction.values.observe(next: { [unowned self] in
            assert(NSThread.isMainThread(), "Only on main")
            switch Globals.accountService.state.value {
            case .LoggedIn:
                self.performSegue(.LoginToCreateProfile, sender: self)
            case .Onboarded:
                self.performSegue(.Main_RootTab, sender: self)
            default:
                assertionFailure("Expecting either LoggedIn or Onboarded")
            }
        })
        vm.loginAction.errors.observe(next: { [unowned self] error in
            if error.domain == METDDPErrorDomain {
                self.showAlert(LS(.errUnableToLoginTitle), message: LS(.errUnableToLoginMessage))
            } else if error.domain == DGTErrorDomain {
                // Ignoring digits error for now
                Log.warn("Ignoring digits error, not handling for now \(error)")
            }
        })
        vm.loginAction.executing.producer.start(next: { executing in
            if executing {
                PKHUD.showActivity(dimsBackground: true)
            } else {
                PKHUD.hide(animated: false)
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segue = segue as? LinkedStoryboardPushSegue where segue.matches(.Main_RootTab) {
            segue.replaceStrategy = .Stack
        }
    }
    
    // MARK: Actions
    
    @IBAction func viewTerms(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(vm.termsAndConditionURL)
    }
    
    @IBAction func viewPrivacy(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(vm.privacyURL)
    }
}