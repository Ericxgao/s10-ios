//
//  EditProfileViewController.swift
//  S10
//
//  Created by Tony Xiao on 7/14/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import UIKit
import ReactiveCocoa
import JVFloatLabeledTextField
import Core

class EditProfileViewController : UITableViewController {
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstNameField: JVFloatLabeledTextField!
    @IBOutlet weak var lastNameField: JVFloatLabeledTextField!
    @IBOutlet weak var aboutTextView: JVFloatLabeledTextView!
    @IBOutlet weak var usernameLabel: JVFloatLabeledTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fix for tableview layout http://stackoverflow.com/questions/18880341/why-is-there-extra-padding-at-the-top-of-my-uitableview-with-style-uitableviewst
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.01))
        coverImageView.clipsToBounds = true
        avatarImageView.makeCircular()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
}