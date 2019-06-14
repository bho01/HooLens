//
//  HistoryViewController.swift
//  HooLens
//
//  Created by Brendon Ho on 6/6/19.
//  Copyright © 2019 Banjo. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import DeckTransition

struct History{
    
    var object: String
    var date: String
    
}

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tbView: UITableView!
    
    var ref:DatabaseReference!
    var histories = [History]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tbView.delegate = self
        tbView.dataSource = self
        // Do any additional setup after loading the view.
        self.ref = Database.database().reference()
        
        ref.child("history").queryOrderedByKey().observe(DataEventType.childAdded, with: { (snapshot) in
            
            let entire = snapshot.value as? NSDictionary
            let obj = entire!["value"] as! String
            let date = entire!["date"] as! String
            
            self.histories.insert(History(object: obj, date: date), at: 0)
            
            self.tbView.reloadData()
            
        })
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return histories.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tbView.dequeueReusableCell(withIdentifier: "historyCell") as! HistoryableViewCell
        
        let objc = cell.object as UILabel
        objc.text = histories[indexPath.row].object
        
        let datec = cell.date as UILabel
        datec.text = histories[indexPath.row].date
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "web") as! WebViewController
        let selectedCell = self.tbView.cellForRow(at: indexPath) as! HistoryableViewCell
        
        controller.urll = URL(string: "http://en.wikipedia.org/wiki/\(convertToURLable(string: selectedCell.object.text ?? "http://en.wikipedia.org/wiki/"))")
        self.tbView.deselectRow(at: indexPath, animated: true)
        self.present(controller, animated: true, completion: nil)
        
    }
    
    func convertToURLable(string: String) -> String{
        
        var newString = string
        
        if(string.contains(" ")){
            
            newString = string.replacingOccurrences(of: " ", with: "_")
            
        }
        
        return newString
        
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
