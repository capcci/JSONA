//
//  ViewController.swift
//  JSONA
//
//  Created by Chenhsin Won on 2019/09/30.
//  Copyright © 2019 Chenhsin Won. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController {

    @IBOutlet weak var clearAndPaste: UIButton!
    @IBOutlet weak var showTextView: UITextView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        showTextView.text = ""
        inputTextView.text = ""
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notify:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged(notify:)), name: UIPasteboard.changedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notify:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notify:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(notify:)), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func clearAndPaste(_ sender: UIButton) {
        let pasteboardString = UIPasteboard.general.string
        inputTextView.text = pasteboardString
        textDidChange(notify: Notification(name: UITextView.textDidChangeNotification))
        inputTextView.resignFirstResponder()
    }
    
    func updateClearPasteButton() {
        let pasteboardString = UIPasteboard.general.string ?? ""
        clearAndPaste.isHidden =  pasteboardString == "" || fomatJsonString(str: pasteboardString) == "Formatting failed"
    }
    
    @objc func applicationDidBecomeActive(notify: Notification) {
        updateClearPasteButton()
    }
    
    @objc func pasteboardChanged(notify: Notification) {
        updateClearPasteButton()
    }
    
    @objc func keyboardWillShow(notify: Notification) {
        guard let userInfo = notify.userInfo else { return }
        guard let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        inputBottomConstraint.constant = -keyboardRect.height
        self.view.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(notify: Notification) {
        inputBottomConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    
    @objc func textDidChange(notify: Notification) {
        showTextView.text = fomatJsonString(str: inputTextView.text)
    }
    
    func fomatJsonString(str: String) -> String {
        if str == "" { return "" }
        var json = str
        
        json = json.replacingOccurrences(of: "    ", with: "")
        json = json.replacingOccurrences(of: "(\\\\)", with: "\\\\\\\\", options: String.CompareOptions.regularExpression, range: json.range(of: json))
        json = json.replacingOccurrences(of: "(\r)", with: "\\\\r", options: String.CompareOptions.regularExpression, range: json.range(of: json))
        json = json.replacingOccurrences(of: "(\n)", with: "\\\\n", options: String.CompareOptions.regularExpression, range: json.range(of: json))
        
        let jsString = "JSON.stringify(JSON.parse(\'\(json)\'),null,2)"
        var string =  JSContext().evaluateScript(jsString)?.toString()
        
        if string == "" || string == "undefined" { string = "Formatting failed" }
        return string!
    }
}

