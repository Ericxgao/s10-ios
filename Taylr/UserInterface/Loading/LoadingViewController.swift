//
//  LoadingViewController.swift
//  S10
//
//  Created by Tony Xiao on 7/3/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Core

class LoadingViewController : UIViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Globals.accountService.state.producer
            |> skipWhile { $0 == AccountService.State.Indeterminate }
            |> futureSuccess { state in
                assert(NSThread.isMainThread(), "Must be on main")
                switch state {
                case .LoggedOut:
                    self.performSegue(.Onboarding_Login, sender: self)
                case .LoggedIn:
                    self.performSegue(.Onboarding_Signup, sender: self)
                case .SignedUp:
                    self.performSegue(.LoadingToDiscover, sender: self)
                default:
                    fatalError("impossible account status")
                }
            }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segue = segue as? AdvancedPushSegue {
            segue.animated = false
            segue.replaceStrategy = .Stack
            if let vc = segue.destinationViewController as? SignupViewController {
                vc.viewModel = SignupInteractor(meteor: Meteor, user: Meteor.user!)
                // TODO: Move this type of stuff into the router
                let onboarding = UIStoryboard(name: "Onboarding", bundle: nil)
                let login = onboarding.instantiateInitialViewController() as! UIViewController
                segue.replaceStrategy = .BackStack([login])
            }
        }
    }
    
}