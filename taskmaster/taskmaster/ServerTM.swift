//
//  ServerTM.swift
//  taskmaster
//
//  Created by Михаил Фокин on 14.09.2021.
//

import Foundation
import Kitura
import LoggerAPI

struct Message: Codable {
	let message: String
	let date: Date
	init(message: String, date: Date) {
		self.message = message
		self.date = date
	}
}

public class ServerTM {
  
  // 1
  let router = Router()
  
  public func run() {
	// 2
	Kitura.addHTTPServer(onPort: 8080, with: router)
	// Handle HTTP GET requests to /
	router.get("/") {
		request, response, next in
		let message = Message(message: "Hello", date: Date())
		let jsonDate = try? JSONEncoder().encode(message)
		print(request)
//		if let path = request.queryParameters["path"] {
//			print("Request received:", path)
//			if path == "exit" {
//				print("Server stop.")
//				Kitura.stop()
//				exit(0)
//			}
//			response.send("scanUtil.run(path: path)")
//		} else {
//			response.send("Invalid request.")
//		}
//		let str = String("Hello")
//		str.de
		response.send(String(decoding: jsonDate!, as: UTF8.self))
		next()
	}
	// 3
	Kitura.run()
  }
}
