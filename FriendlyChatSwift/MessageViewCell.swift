//
//  TableViewCell.swift
//  BVChat
//
//  Created by Lusenii Kromah on 10/3/16.
//  Copyright © 2016 Black Valley. All rights reserved.
//

import UIKit

class MessageViewCell: UITableViewCell {
   
 
    @IBOutlet weak var profilePic: UIImageView!
    
    
    @IBOutlet weak var firstnameLabel: UILabel!
    
    
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
