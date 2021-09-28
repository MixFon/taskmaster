//
//  InfoViewController.swift
//  TaskmasterMobile
//
//  Created by Михаил Фокин on 16.09.2021.
//

import UIKit

class InfoViewController: UIViewController {
	
	@IBOutlet weak var table: UITableView!
	
	var info: InfoProcess?
	var array = [(String, String)]()
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		guard let info = self.info else { return }
		let mirror = Mirror(reflecting: info)
		for (lable, value) in mirror.children {
			guard let lable = lable else { continue }
			let value = getValue(value: value)
			self.array.append((lable.camelCaseToSnakeCase(), value))
		}
    }
	
	@IBAction func pressStream(_ sender: UIButton) {
		guard let nameProcess = self.info?.nameProcess else { return }
		let sroryboard = UIStoryboard(name: "Main", bundle: nil)
		guard let streamVC = sroryboard.instantiateViewController(withIdentifier: "StreamViewController") as? StreamViewController else { return }
		streamVC.nameProcess = nameProcess
		show(streamVC, sender: nil)
	}

	private func getValue(value: Any) -> String {
		if let value = value as? String {
			return value
		} else if let value = value as? [String] {
			return String(value.joined(separator: " "))
		} else if let value = value as? Int {
			return String(value)
		} else if let value = value as? Int64 {
			return String(value)
		} else if let value = value as? Bool {
			return String(value)
		} else if let value = value as? [Int] {
			return String(value.map( {String($0) } ).joined(separator: " "))
		} else if let value = value as? [Int32] {
			return String(value.map( {String($0) } ).joined(separator: " "))
		} else if let value = value as? Int {
			return String(value)
		} else if let value = value as? InfoProcess.AutoRestart {
			return String(describing: value.rawValue)
		} else if let value = value as? InfoProcess.Signals {
			return String(describing: value.rawValue)
		} else if let value = value as? Double {
			return String(value)
		} else if let value = value as? [String: String] {
			return String(describing: value)
		}
		return "Not specified"
	}

}

extension InfoViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.array.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
		let elem = self.array[indexPath.row]
		cell.textLabel?.text = elem.0
		cell.detailTextLabel?.text = elem.1
		return cell
	}
	
}

extension String {
	func camelCaseToSnakeCase() -> String {
		let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
		let normalPattern = "([a-z0-9])([A-Z])"
		return self.processCamalCaseRegex(pattern: acronymPattern)?
			.processCamalCaseRegex(pattern: normalPattern)?.lowercased() ?? self.lowercased()
	}
	
	fileprivate func processCamalCaseRegex(pattern: String) -> String? {
		let regex = try? NSRegularExpression(pattern: pattern, options: [])
		let range = NSRange(location: 0, length: count)
		return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1 $2")
	}
}
