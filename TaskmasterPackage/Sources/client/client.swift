//
//  File.swift
//  
//
//  Created by Михаил Фокин on 27.09.2021.
//

import Foundation
import DataProcess

class Client {
	private var host: String
	private var port: String
	
	init(host: String, port: String) {
		self.host = host
		self.port = port
	}
	
	func run() {
		while let line = readLine() {
			if line.isEmpty { continue }
			let words = line.split(separator: " ").map( { String($0) } )
			guard let commamd = Command(rawValue: words[0]) else {
				print("Invalid command:", words[0])
				continue
			}
			sendRequest(command: commamd, arguments: words[1...].map( { String($0) } ))
		}
	}
	
	private func sendRequest(command: Command, arguments: [String]) {
		guard let url = getURL(command: command, arguments: arguments) else { return }
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		let session = URLSession.shared
		session.dataTask(with: request) { (data, response, error) in
			if let response = response as? HTTPURLResponse, response.statusCode != 200 {
				print("Error response. Status \(response.statusCode)")
				return
			}
			guard let data = data else {
				print("Error response.")
				return
			}
			do {
				if command == .stream {
					let stream = String(decoding: data, as: UTF8.self)
					print(stream)
				} else {
					let info = try JSONDecoder().decode([InfoProcess].self, from: data)
					self.showInfo(info: info)
				}
			} catch {
				print("Invalid parsing JSON.")
			}
		}.resume()
	}
	
	private func getURL(command: Command, arguments: [String]) -> URL? {
		let urlString: String
		if command == .stream {
			if arguments.count != 2 {
				print("Invalid arguments!")
				print("Usege:")
				print("stream name_process stderr/stdout")
				return nil
			}
			let name = arguments[0]
			let type = arguments[1]
			urlString = "http://\(self.host):\(self.port)?command=stream&arguments=\(name)&type=\(type)"
		} else {
			let argument = arguments.joined(separator: ",")
			urlString = "http://\(self.host):\(self.port)?command=\(command)&arguments=\(argument)"
		}
		guard let url = URL(string: urlString) else {
			print("Error url. The request is malformed.")
			return nil
		}
		return url
	}
	
	private func showInfo(info: [InfoProcess]) {
		for oneInfo in info {
			print("***************************************************************")
			let mirror = Mirror(reflecting: oneInfo)
			for (lable, value) in mirror.children {
				guard let lable = lable else { continue }
				guard let value = getValue(value: value) else { continue }
				print(lable.camelCaseToSnakeCase(), value)
			}
		}
	}
	
	private func getValue(value: Any) -> String? {
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
		} else if let value = value as? AutoRestart {
			return String(describing: value.rawValue)
		} else if let value = value as? Signals {
			return String(describing: value.rawValue)
		} else if let value = value as? Double {
			return String(value)
		} else if let value = value as? [String: String] {
			return String(describing: value)
		}
		return nil
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
