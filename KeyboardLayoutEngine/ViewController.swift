//
//  ViewController.swift
//  KeyboardLayoutEngine
//
//  Created by Cem Olcay on 06/05/16.
//  Copyright © 2016 Prototapp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        textView.becomeFirstResponder()
    super.viewDidLoad()
  }
}
