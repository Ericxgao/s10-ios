//
//  ProfileViewController.swift
//  Serendipity
//
//  Created by Tony Xiao on 1/27/15.
//  Copyright (c) 2015 Serendipity. All rights reserved.
//

import Foundation
import SwipeView
import SDWebImage

@objc(ProfileViewController)
class ProfileViewController : BaseViewController, SwipeViewDelegate, SwipeViewDataSource {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var swipeView: SwipeView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var workLabel: UILabel!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    var user : User? {
        willSet {
            willChangeValueForKey("user")
        }
        didSet {
            didChangeValueForKey("user")
            if isViewLoaded() { reloadData() }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Find better solution than hardcoding keypath string
        RAC(navigationItem, "title") <~ racObserve("user.firstName")
        RAC(nameLabel, "text") <~ racObserve("user.firstName")
        RAC(aboutLabel, "text") <~ racObserve("user.about")
        RAC(locationLabel, "text") <~ racObserve("user.location")
        RAC(workLabel, "text") <~ racObserve("user.work")
        RAC(schoolLabel, "text") <~ racObserve("user.education")
        RAC(ageLabel, "text") <~ racObserve("user.age").map { age in
            return (age as? NSNumber)?.stringValue
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    // MARK: -
    @IBAction func goBack(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func reloadData() {
        swipeView.reloadData()
        swipeView.scrollToItemAtIndex(0, duration: 0)
        pageControl.numberOfPages = numberOfItemsInSwipeView(swipeView)
    }
    
    // MARK: - SwipeView Delegate / Data Soruce
    
    func numberOfItemsInSwipeView(swipeView: SwipeView!) -> Int {
        return user?.photos != nil ? (user?.photos?.count)! : 0
    }
    
    func swipeView(swipeView: SwipeView!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        let v = view != nil ? view as UIImageView : UIImageView()
        v.contentMode = .ScaleAspectFit
        let url = user?.photos![index].url
        v.sd_setImageWithURL(NSURL(string: url!))
        return v
    }
    
    func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView!) {
        pageControl.currentPage = swipeView.currentPage
    }
    
    func swipeViewItemSize(swipeView: SwipeView!) -> CGSize {
        return swipeView.frame.size
    }
    
}