//
//  UDManager.swift
//  TaskmasterMobile
//
//  Created by Михаил Фокин on 16.09.2021.
//

import UIKit

class UDManager: UIViewController {
	let userDefaults = UserDefaults.standard
	
	func getIPPort() ->(String, Int)? {
		guard let ip = userDefaults.object(forKey: "ip") as? String else { return nil }
		guard let port = userDefaults.object(forKey: "port") as? Int else { return nil }
		return (ip, port)
	}
	
	func setIPPort(ip: String, port: String) {
		userDefaults.setValue(ip, forKey: "ip")
		userDefaults.setValue(Int(port) ?? 8080, forKey: "port")
	}
}
