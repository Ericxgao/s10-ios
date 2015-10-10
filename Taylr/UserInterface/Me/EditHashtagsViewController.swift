//
//  EditHashtagsViewController.swift
//  S10
//
//  Created by Tony Xiao on 10/9/15.
//  Copyright © 2015 S10. All rights reserved.
//

import UIKit
import ReactiveCocoa
import MLPAutoCompleteTextField
import Core

class EditHashtagsViewController : UIViewController {
    @IBOutlet weak var textField: MLPAutoCompleteTextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var vm: EditHashtagsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.autoCompleteTableAppearsAsKeyboardAccessory = true
        textField.shouldResignFirstResponderFromKeyboardAfterSelectionOfAutoCompleteRows = false
        textField.autocorrectionType = .No
        
        vm = EditHashtagsViewModel(meteor: Meteor)
        collectionView <~ (vm.hashtags, HashtagCell.self)
    }
}

extension EditHashtagsViewController : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        vm.toggleHashtagAtIndex(indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

// TODO: Eventually use self-sizing UICollectionViewCell instead of hardcoding like this...

private let HashtagFont = UIFont(.cabinRegular, size: 14)

extension EditHashtagsViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let hashtag = vm.hashtags.array[indexPath.item]
        var size = (hashtag.displayText as NSString).boundingRectWithSize(CGSizeMake(1000, 1000),
            options: [], attributes: [NSFontAttributeName: HashtagFont], context: nil).size
        size.width += 10 * 2
        size.height += 8 * 2
        return size
    }
}

// MARK: - MLPAutoCompleteTextField DataSource / Delegate

//extension Hashtag : MLPAutoCompletionObject {
//    public func autocompleteString() -> String! {
//        return text
//    }
//}

extension EditHashtagsViewController : MLPAutoCompleteTextFieldDelegate {
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, shouldConfigureCell cell: UITableViewCell!, withAutoCompleteString autocompleteString: String!, withAttributedString boldedString: NSAttributedString!, forAutoCompleteObject autocompleteObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        cell.textLabel?.text = "#" + autocompleteString
        return false
    }
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, didSelectAutoCompleteString selectedString: String!, withAutoCompleteObject selectedObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) {
        vm.selectHashtag(selectedString.substringFromIndex(1))
        textField.text = nil
        textField.reloadData()
    }
}

extension EditHashtagsViewController : MLPAutoCompleteTextFieldDataSource {
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        // TODO: Dispose me
        vm.autocompleteHashtags(string).onSuccess { hashtags in
            handler(hashtags.map { $0.text })
        }
    }
}
