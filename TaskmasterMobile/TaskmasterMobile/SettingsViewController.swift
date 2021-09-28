//
//  SettingsViewController.swift
//  TaskmasterMobile
//
//  Created by Михаил Фокин on 16.09.2021.
//

import UIKit

class SettingsViewController: UIViewController {
	@IBOutlet weak var ipServer: UITextField!
	@IBOutlet weak var portServer: UITextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let manegerUD = UDManager()
		guard let (ip, port) = manegerUD.getIPPort() else { return }
		self.ipServer.text = ip
		self.portServer.text = String(port)
    }
    
	@IBAction func save(_ sender: UIBarButtonItem) {
		guard let ip = self.ipServer.text, !ip.isEmpty else { return }
		guard let port = self.portServer.text, !port.isEmpty else { return }
		let manegerUD = UDManager()
		manegerUD.setIPPort(ip: ip, port: port)
	}

}
