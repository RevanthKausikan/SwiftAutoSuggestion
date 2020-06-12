//
//  ExampleViewController.swift
//  SwiftAutoSuggestion_Example
//
//  Created by Revanth Kausikan on 07/06/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//


import UIKit
import SwiftAutoSuggestion


class ExampleViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var autoSuggestionView: SwiftAutoSuggestionView!
    
    @IBOutlet weak var autoSuggestionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var autoSuggestionBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var autoSuggestionRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var autoSuggestionLeftConstraint: NSLayoutConstraint!
    
    let data1 = ["Item 1","Item2","Long string item","Very loooong string item, probably the longest in this list"]
    let data2 = ["1","2","a","B","❝","✅","☢","👀","Φ","֍","ڪ","⃟","Ⴂ","అ","ழ","⇪","⥁","🢗","","~","&","%","⨆","⎳","⏹"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSuggestionView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func setupSuggestionView() {
        autoSuggestionView.delegate = self
        autoSuggestionView.suggestionTopConstraint = autoSuggestionTopConstraint
        autoSuggestionView.suggestionBottomConstraint = autoSuggestionBottomConstraint
        autoSuggestionView.suggestionRightConstraint = autoSuggestionRightConstraint
        autoSuggestionView.suggestionLeftConstraint = autoSuggestionLeftConstraint
        autoSuggestionView.suggestionDirection = .bottom
    }
    
    @IBAction func textFieldEditingChange(_ sender: UITextField) {
        if sender == topTextField, let textCount = topTextField.text?.count {
            if textCount == 0 {
                autoSuggestionView.hideSuggestion()
                return
            }
            
            if textCount % 2 == 0 {
                autoSuggestionView.showSuggestion(with: data1 as NSArray)
            } else {
                autoSuggestionView.showSuggestion(with: data2 as NSArray)
            }
        }
    }
}


extension ExampleViewController: SwiftAutoSuggestionDelegate {
    func swiftAutosuggestionDidSelectCell(with data: Any) {
        //Use the data
        resultLabel.text = data as? String
        //Hide the suggestion
        autoSuggestionView.hideSuggestion()
    }
}

