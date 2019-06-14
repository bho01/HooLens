
//
//  WebViewController.swift
//  HooLens
//
//  Created by Brendon Ho on 6/13/19.
//  Copyright © 2019 Banjo. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController{

    @IBOutlet weak var webby: WKWebView!
    var urll: URL! = URL(string: "http://en.wikipedia.org")
    var tail: String!
    @IBOutlet weak var dismiss: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(urll)
        // Do any additional setup after loading the view.
        dismiss.layer.cornerRadius = 15
        webby.load(URLRequest(url: urll ?? URL(string: "http://en.wikipedia.org")!))
    
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
