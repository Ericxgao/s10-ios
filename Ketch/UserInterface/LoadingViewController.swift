//
//  LoadingViewController.swift
//  Ketch
//
//  Created by Tony Xiao on 4/5/15.
//  Copyright (c) 2015 Ketch. All rights reserved.
//

import Foundation

class LoadingViewController : BaseViewController {
    
    @IBOutlet weak var loadingView: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadingView.setHiddenAnimated(hidden: false, duration: 0.75)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        loadingView.setHiddenAnimated(hidden: true, duration: 0.25)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destVC as? NewConnectionViewController {
            vc.connection = Globals.flowService.newMatchToShow
        }
        if let vc = segue.destVC as? GameViewController {
            vc.candidates = Array(Candidate.candidateQueue()[0...2])
        }
    }
    
    override func stateDidUpdateWhileViewActive(state: FlowService.State) {
        switch state {
        case .Signup:
            self.performSegue(.Signup_Signup)
        case .Waitlist:
            self.performSegue(.Signup_Waitlist)
        case .Welcome:
            self.performSegue(.Signup_Welcome)
        case .NewMatch:
            self.performSegue(.LoadingToNewConnection)
        case .NewGame:
            self.performSegue(.LoadingToGame)
        case .BoatSailed:
            self.performSegue(.LoadingToNoGame)
        case .Loading:
            break
        }
    }
    
    // MARK: - Actions
    
    @IBAction func unwindToLoading(sender: UIStoryboardSegue) {
    }
    
}