//
//  JWSearchInterfaceController.swift
//  BusRider
//
//  Created by John Wong on 5/2/15.
//  Copyright (c) 2015 John Wong. All rights reserved.
//

import WatchKit
import Foundation
import UIKit

class JWSearchInterfaceController: WKInterfaceController {
    
    struct Storyboard {
        static let interfaceControllerName = "JWCityInterfaceController"
        
        struct RowTypes {
            static let item = "JWSearchControllerRowType"
            static let noItem = "JWSearchControllerNoRowType"
            static let errorItem = "JWSearchControllerErrorRowType"
        }
        
        struct Controllers {
            static let lineDetail = "lineDetail"
        }
    }
    
    var searchRequest = JWSearchRequest()
    var searchItems = JWSearchListItem()
    
    @IBOutlet weak var interfaceTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        openInputController()
        self.addMenuItem(with: WKMenuItemIcon.repeat, title: "重新输入", action: #selector(JWSearchInterfaceController.openInputController))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadData(_ keyword: String) {
        self.interfaceTable.setNumberOfRows(1, withRowType: Storyboard.RowTypes.noItem)
        
        searchRequest.keyWord = keyword
        searchRequest.load { [weak self](result, error) -> Void in
            if let weakSelf = self {
                if let error = error {
                    weakSelf.interfaceTable.setNumberOfRows(1, withRowType: Storyboard.RowTypes.errorItem)
                    let itemRowController = weakSelf.interfaceTable.rowController(at: 0) as! JWSearchControllerRowType
                    itemRowController.setText(error.localizedDescription)
                } else if let result = result {
                    weakSelf.searchItems = JWSearchListItem(dictionary: result as [AnyHashable: Any])
                    let totalCount = weakSelf.searchItems?.lineList.count
                    if totalCount! > 0 {
                        weakSelf.interfaceTable.setNumberOfRows(totalCount!, withRowType: Storyboard.RowTypes.item)
                        for index in 0 ..< weakSelf.searchItems!.lineList.count {
                            weakSelf.configureRowControllerAtIndex(index)
                        }
                    } else {
                        weakSelf.interfaceTable.setNumberOfRows(1, withRowType: Storyboard.RowTypes.errorItem)
                        let itemRowController = weakSelf.interfaceTable.rowController(at: 0) as! JWSearchControllerRowType
                        itemRowController.setText("没有结果")
                    }
                }
            }
        }
    }
    
    func configureRowControllerAtIndex(_ index: Int) {
        let itemRowController = self.interfaceTable.rowController(at: index) as! JWSearchControllerRowType
        if index < (self.searchItems?.lineList.count)! {
            let item: JWSearchLineItem = self.searchItems!.lineList[index] as! JWSearchLineItem
            itemRowController.setText(item.lineNumber)
        }
    }
    
    @IBAction func openInputController() {
        if (TARGET_OS_SIMULATOR > 0) {
            loadData("2")
            return
        }
        
        var initialPhrases = Array<String>()
        let allCollectItems = JWUserDefaultsUtil.allCollectItems()
        if let _ = allCollectItems {
            for item in JWUserDefaultsUtil.allCollectItems() {
                if let collectItem = item as? JWCollectItem {
                    initialPhrases.append(collectItem.lineNumber)
                }
            }
        }
        
        self.presentTextInputController(withSuggestions: initialPhrases, allowedInputMode: WKTextInputMode.plain) {
            [weak self](results) -> Void in
            if let results = results, let weakSelf = self , results.count > 0 {
                var aResult = results[0] as! String;
                aResult = aResult.replacingOccurrences(of: "路", with: "", options: NSString.CompareOptions(), range: nil)
                weakSelf.loadData(aResult)
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if rowIndex < (self.searchItems?.lineList.count)! {
            let item: JWSearchLineItem = self.searchItems!.lineList[rowIndex] as! JWSearchLineItem
            self.pushController(withName: Storyboard.Controllers.lineDetail, context: item.lineId)
        }
    }
    
}
