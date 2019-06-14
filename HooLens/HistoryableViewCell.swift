//
//  HistoryableViewCell.swift
//  HooLens
//
//  Created by Brendon Ho on 6/13/19.
//  Copyright © 2019 Banjo. All rights reserved.
//

import UIKit

class HistoryableViewCell: UITableViewCell {

    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var object: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
