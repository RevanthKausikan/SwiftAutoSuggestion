//
//  SwiftAutoSuggestionView.swift
//  Pods-SwiftAutoSuggestionView
//
//  Created by Revanth Kausikan on 06/06/20.
//

import UIKit

public enum SuggestionDirection {
    ///Suggestion list won't expand or shrink.
    case fixed
    ///Suggestion list will grow or shrink on the top.
    case top
    ///Suggestion list will grow or shrink on the bottom.
    case bottom
}

public protocol SwiftAutoSuggestionDelegate {
    ///Returns selected data from suggestion list.
    /// * parameter data: Selected value among the list of suggestion data.
    func swiftAutosuggestionDidSelectCell(with data: Any)
    ///Implements default layout unless implemented.
    func swiftAutoSuggestion(customize cell: UITableViewCell, with data: Any)
    ///Dynamic height based on cell's content is considered unless implemented.
    func swiftAutoSuggestionCellHeight() -> CGFloat?
}

//implementation of default methods
public extension SwiftAutoSuggestionDelegate {
    func swiftAutoSuggestion(customize cell: UITableViewCell, with data: Any) {
        cell.textLabel?.text = data as? String
    }
    
    func swiftAutoSuggestionCellHeight() -> CGFloat? {
        return nil
    }
}

public class  SwiftAutoSuggestionView: UIView {
    
    //Mandatory
    open var delegate: SwiftAutoSuggestionDelegate? = nil
    ///Top constraint for SwiftAutoSuggestion.
    open var suggestionTopConstraint: NSLayoutConstraint?
    ///Bottom constraint for SwiftAutoSuggestion.
    open var suggestionBottomConstraint: NSLayoutConstraint?
    ///Left constraint for SwiftAutoSuggestion.
    open var suggestionLeftConstraint: NSLayoutConstraint?
    ///Right constraint for SwiftAutoSuggestion.
    open var suggestionRightConstraint: NSLayoutConstraint?
    ///Height constraint for SwiftAutoSuggestion.
    open var suggestionHeightConstraint: NSLayoutConstraint?
    
    ///Describes the growth direction of the suggestion list. Default is `.bottom`.
    open var suggestionDirection: SuggestionDirection = .bottom
    open var customCellIdentifier: String? = nil
    
    ///Extra space on the top of the suggestion list. Default is `0`.
    open var suggestionTableTopInset: CGFloat = 0
    ///Extra space on the bottom of the suggestion list. Default is `0`.
    open var suggestionTableBottomInset: CGFloat = 0
    
    ///Time taken to show/hide the suggestion list. Default is `0.1`.
    open var suggestionFadeDuration: Double = 0.1
    open var suggestionTableViewBackgroundColor: UIColor = .white
    ///Constant space between keyboard's top and suggestion's bottom. Default is `8`.
    open var constantKeyboardTopSpace: CGFloat = 8
    
    private let suggestionTableView = UITableView()
    private var data = NSArray()
    private var keyBoardFrameMinY: CGFloat?
    private var cellIdentifier: String {
        if let identifier = customCellIdentifier, identifier != "" {
            return identifier
        }
        return "suggestionCell"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initialize()
    }
    
    private func initialize() {
        setupTableView()
        self.clipsToBounds = true
        
        self.backgroundColor = suggestionTableViewBackgroundColor
        
        self.layer.cornerRadius = 7
        self.layer.borderWidth = 0.75
        self.layer.borderColor = UIColor.darkGray.cgColor
        
        self.layer.shadowRadius = 5
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowOpacity = 0.75
        
        self.isHidden = true
        self.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupTableView() {
        
        suggestionTableView.dataSource = self
        suggestionTableView.delegate = self
        suggestionTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        self.addSubview(suggestionTableView)
        
        suggestionTableView.translatesAutoresizingMaskIntoConstraints = false
        
        suggestionTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        suggestionTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        suggestionTableView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0).isActive = true
        suggestionTableView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        
        let view = UIView()
        view.backgroundColor = suggestionTableViewBackgroundColor
        suggestionTableView.backgroundView = view
        
        suggestionTableView.contentInset = UIEdgeInsets(top: suggestionTableTopInset, left: 0,
                                                        bottom: suggestionTableBottomInset, right: 0)
        suggestionTableView.tableFooterView = UIView()
        suggestionTableView.tableHeaderView = UIView()
    }
    
    private func refreshConstraints() {
        switch suggestionDirection {
        case .bottom:
            suggestionBottomConstraint?.isActive = false
        case .top:
            suggestionTopConstraint?.isActive = false
        case .fixed:
            return
        }
        refreshHeightConstraint()
    }
    
    private func refreshHeightConstraint() {
        var suggestedHeight = suggestionTableTopInset + suggestionTableBottomInset
        
        //Get content height of the tableView
        if let cellHeight = delegate?.swiftAutoSuggestionCellHeight() {
            suggestedHeight += (cellHeight * CGFloat(data.count))
        } else {
            suggestedHeight += suggestionTableView.contentSize.height
        }
        
        //Adjust height based on physical boundaries
        if suggestionDirection == .bottom {
            //Fit within view not occupied by keyboard
            if let keyboardTop = keyBoardFrameMinY {
                let suggestionBottom = self.frame.minY + suggestedHeight
                if suggestionBottom > keyboardTop {
                    suggestedHeight -= suggestionBottom - keyboardTop + constantKeyboardTopSpace
                }
            }
        } else if suggestionDirection == .top {
            //Fit within status + navigation bar
            if let presentingVC = delegate as? UIViewController {
                let topLimit =  UIApplication.shared.statusBarFrame.size.height
                    + (presentingVC.navigationController?.navigationBar.frame.height ?? 0.0)
                let suggestionTop = self.frame.maxY - suggestedHeight
                if suggestionTop < topLimit {
                    suggestedHeight -= topLimit - suggestionTop
                }
            }
        }
        
        //Assign the height
        if let height = suggestionHeightConstraint {
            height.constant = suggestedHeight
        } else {
            suggestionHeightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil,
                                                            attribute: .notAnAttribute, multiplier: 1,
                                                            constant: suggestedHeight)
            self.addConstraint(suggestionHeightConstraint!)
        }
        self.layoutIfNeeded()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyBoardFrameMinY = keyboardRectangle.minY
        }
//        if !self.isHidden {
//            refreshConstraints()
//        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyBoardFrameMinY = keyboardRectangle.minY
        } else {
            keyBoardFrameMinY = nil
        }
//        refreshConstraints()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - Extensions
extension SwiftAutoSuggestionView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.backgroundColor = suggestionTableViewBackgroundColor
        cell.textLabel?.textColor = .black
        delegate?.swiftAutoSuggestion(customize: cell, with: data[indexPath.row])
        return cell
    }
}

extension SwiftAutoSuggestionView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.swiftAutosuggestionDidSelectCell(with: data[indexPath.row])
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return delegate?.swiftAutoSuggestionCellHeight() ?? UITableView.automaticDimension
    }
}

//MARK: - Exposed methods
extension SwiftAutoSuggestionView {
    open func showSuggestion(with suggestionData: NSArray) {
        UIView.animate(withDuration: suggestionFadeDuration) {
            self.alpha = 1
            self.isHidden = false
        }
        self.data = suggestionData
        self.suggestionTableView.reloadData()
        refreshConstraints()
    }
    
    open func hideSuggestion() {
        UIView.animate(withDuration: suggestionFadeDuration,
                       animations: { self.alpha = 0 },
                       completion: { _ in self.isHidden = true })
    }
}


