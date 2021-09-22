//
//  ServerTM.swift
//  taskmaster
//
//  Created by Михаил Фокин on 14.09.2021.
//

import Foundation
import Kitura
import LoggerAPI

public class ServerTM {
	
	let tascmaster: Taskmaster
	let router: Router
	let serverInfo: ServerInfo
	
	init?() {
		let managerXML = XMLDataManager()
		guard let serverInfo = managerXML.getServerInfo(xmlFile: "server_config.xml") else { return nil }
		self.serverInfo = serverInfo
		guard let taskmaster = Taskmaster(processesConfig: serverInfo.processFileConfig) else { return nil }
		self.tascmaster = taskmaster
		self.router = Router()
	}
	
	struct ServerInfo {
		var processFileConfig: String = "precesses_config.xml"
		var fileLogs: String = "taskmaster.log"
		var port: Int = 8080
	}
	
	public func run() {
		
		Kitura.addHTTPServer(onPort: self.serverInfo.port, with: router)
		// Handle HTTP GET requests to /
		router.get("/") {
			request, response, next in
			print("Request received:", request)
			guard let parametersCommand = request.queryParameters["command"] else { next(); return }
			guard let command = Taskmaster.Command(rawValue: parametersCommand) else { next(); return }
			print(Taskmaster.Command.RawValue())
			switch command {
			case .status:
				self.sendStatus(response: response)
			case .exit:
				Taskmaster.exitTaskmaster()
			default:
				let parametersArguments = request.queryParameters["arguments"]
				self.tascmaster.executeCommand(command: command, arguments: parametersArguments)
				self.sendStatus(response: response)
			}
		}
		Kitura.run()
	}
	
	private func getAllInfoString() -> String? {
		guard let infoProcesses = self.tascmaster.allInfoPrecesses() else { return nil }
		guard let dataJSON = try? JSONEncoder().encode(infoProcesses) else { return nil }
		return String(decoding: dataJSON, as: UTF8.self)
	}
	
	private func sendStatus(response: RouterResponse) {
		guard let infoString = self.getAllInfoString() else { return }
		response.send(infoString)
	}
}
