//
//  StreamViewController.swift
//  TaskmasterMobile
//
//  Created by Михаил Фокин on 25.09.2021.
//

import UIKit

class StreamViewController: UIViewController {
	
	@IBOutlet weak var textField: UITextView!
	var nameProcess: String?

    override func viewDidLoad() {
        super.viewDidLoad()
		guard let nameProcess = self.nameProcess else { return }
		self.title = nameProcess
		//print(nameProcess)
    }
	
	@IBAction func pressError(_ sender: UIButton) {
		guard let nameProcess = self.nameProcess else { return }
		sendResponseOutput(nameProcess: nameProcess, type: "stderr")
	}
	
	@IBAction func pressOutput(_ sender: UIButton) {
		guard let nameProcess = self.nameProcess else { return }
		sendResponseOutput(nameProcess: nameProcess, type: "stdout")
	}
	
	private func sendResponseOutput(nameProcess: String, type: String) {
		let managerUD = UDManager()
		guard let (ip, port) = managerUD.getIPPort() else { return }
		let urlString = "http://\(ip):\(port)?command=stream&arguments=\(nameProcess)&type=\(type)"
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
			let string = String(decoding: data, as: UTF8.self)
			DispatchQueue.main.async {
				self.textField.text = string
			}
			
		}.resume()
	}
	
	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}

}
