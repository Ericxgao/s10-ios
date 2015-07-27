//
//  ProfileInfoCells.swift
//  S10
//
//  Created by Tony Xiao on 7/26/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import Bond
import Core

class TaylrProfileInfoCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    func bind(vm: TaylrProfileInfoViewModel) {
        vm.jobTitle ->> titleLabel
        vm.employer ->> subtitleLabel
        vm.about ->> aboutLabel
    }
}

class ConnectedProfileInfoCell : UITableViewCell {
    
}