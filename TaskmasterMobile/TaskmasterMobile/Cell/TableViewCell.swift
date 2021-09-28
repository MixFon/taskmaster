//
//  TableViewCell.swift
//  TaskmasterMobile
//
//  Created by Михаил Фокин on 16.09.2021.
//

import UIKit

class TableViewCell: UITableViewCell {
	@IBOutlet weak var name: UILabel!
	@IBOutlet weak var status: UILabel!
	@IBOutlet weak var selectOurlet: UIButton!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		selectOurlet.isSelected = false
    }
	
	@IBAction func selectButton(_ sender: UIButton) {
		selectOurlet.isSelected = !selectOurlet.isSelected
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
