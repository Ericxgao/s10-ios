//
//  NewConnectionViewController.swift
//  Serendipity
//
//  Created by Tony Xiao on 2/12/15.
//  Copyright (c) 2015 Serendipity. All rights reserved.
//

import Foundation

@objc(NewConnectionViewController)
class NewConnectionViewController : BaseViewController {
    
    var connection: Connection!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatar: UserAvatarView!
    @IBOutlet weak var promptLabel: DesignableLabel!
    @IBOutlet weak var waveView: WaveView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatar.whenTapEnded(didTapOnAvatar)
        titleLabel.text = LS(R.Strings.itsAKetch)
        avatar.user = connection.user
        promptLabel.rawText = LS(R.Strings.singleMatchPrompt, connection.user!.firstName!, connection.user!.firstName!)
    }

    func didTapOnAvatar() {
        let profileVC = ProfileViewController()
        profileVC.user = self.connection.user
        self.presentViewController(profileVC, animated: true)
    }

    @IBAction func goToDock(sender: AnyObject) {
        performSegue(.NewConnectionToDock)
    }
}