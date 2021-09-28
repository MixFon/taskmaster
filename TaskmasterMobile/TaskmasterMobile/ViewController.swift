//
//  ViewController.swift
//  TaskmasterMobile
//
//  Created by Михаил Фокин on 16.09.2021.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var table: UITableView!
	
	var infoPrecesses: [InfoProcess]?
	let cellName: String = "cellName"
	
	enum Command: String {
		case help
		case start
		case status
		case stop
		case restart
		case exit
		case reload
		case stream
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.table.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: self.cellName)
		sendResponseCommand(command: .status, arguments: ["all"])
	}
	
	@IBAction func pressExit(_ sender: UIButton) {
		sendResponseCommand(command: .exit, arguments: ["all"])
	}
	
	@IBAction func settings(_ sender: UIBarButtonItem) {
		let sroryboard = UIStoryboard(name: "Main", bundle: nil)
		guard let settings = sroryboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else { return }
		show(settings, sender: nil)
	}
	
	@IBAction func pressReload(_ sender: UIButton) {
		sendResponseCommand(command: .reload, arguments: ["all"])
	}
	
	@IBAction func pressStatus(_ sender: UIButton) {
		sendResponseCommand(command: .status, arguments: ["all"])
	}
	
	@IBAction func pressStart(_ sender: UIButton) {
		sendCommandSelectedName(command: .start)
	}
	
	@IBAction func pressStop(_ sender: UIButton) {
		sendCommandSelectedName(command: .stop)
	}
	
	@IBAction func pressRestart(_ sender: UIButton) {
		sendCommandSelectedName(command: .restart)
	}
	
	private func sendCommandSelectedName(command: Command) {
		guard let info = self.infoPrecesses else { return }
		var nameStart = [String]()
		for (i, element) in info.enumerated() {
			let cell = self.table.cellForRow(at: IndexPath(row: i, section: 0)) as? TableViewCell
			if cell?.selectOurlet.isSelected == true {
				guard let nameProcess = element.nameProcess else { continue }
				nameStart.append(nameProcess)
			}
		}
		sendResponseCommand(command: command, arguments: nameStart)
	}
	
	private func sendResponseCommand(command: Command, arguments: [String]) {
		let managerUD = UDManager()
		guard let (ip, port) = managerUD.getIPPort() else { return }
		let argument = arguments.joined(separator: ",")
		let urlString = "http://\(ip):\(port)?command=\(command)&arguments=\(argument)"
		guard let url = URL(string: urlString) else {
			showAlert(title: "Error url.", message: "The request is malformed.")
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		let session = URLSession.shared
		session.dataTask(with: request) { (data, response, error) in
			if let response = response as? HTTPURLResponse, response.statusCode != 200 {
				DispatchQueue.main.async {
					self.showAlert(title: "Error response.", message: "Status \(response.statusCode)")
				}
				return
			}
			guard let data = data else {
				DispatchQueue.main.async {
					self.showAlert(title: "Error response.", message: "")
				}
				return
			}
			do {
				self.infoPrecesses = try JSONDecoder().decode([InfoProcess].self, from: data)
				DispatchQueue.main.async {
					self.table.reloadData()
				}
			} catch {
				DispatchQueue.main.async {
					self.showAlert(title: "Error response.", message: "Status \(error.localizedDescription)")
				}
			}
		}.resume()
	}
	
	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let info = infoPrecesses else { return 0 }
		return info.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let info = infoPrecesses else { return UITableViewCell() }
		let cell = self.table.dequeueReusableCell(withIdentifier: self.cellName, for: indexPath) as! TableViewCell
		cell.name.text = info[indexPath.row].nameProcess ?? "nil"
		cell.status.text = info[indexPath.row].status?.getStatus() ?? "nil"
		cell.status.textColor = info[indexPath.row].status?.getColor() ?? UIColor()
		return cell
	}
	
	// Вызывается при нажании на ячейку.
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let infoProcess = self.infoPrecesses else { return }
		let sroryboard = UIStoryboard(name: "Main", bundle: nil)
		guard let infoVC = sroryboard.instantiateViewController(withIdentifier: "InfoViewController") as? InfoViewController else { return }
		infoVC.info = infoProcess[indexPath.row]
		show(infoVC, sender: nil)
		
	}
	
	// Задает размер ячейки
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
}
