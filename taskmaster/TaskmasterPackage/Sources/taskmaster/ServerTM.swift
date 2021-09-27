//
//  ServerTM.swift
//  taskmaster
//
//  Created by Михаил Фокин on 14.09.2021.
//

import Foundation
import Kitura
import LoggerAPI
import DataProcess

public class ServerTM {
	
	let tascmaster: Taskmaster
	let router: Router
	var serverInfo: ServerInfo
	
	init?() {
		let managerXML = XMLDataManager()
		guard let serverInfo = managerXML.getServerInfo(xmlFile: "server_config.xml") else { return nil }
		self.serverInfo = serverInfo
		let argumentsCommandLine = CommandLine.arguments
		if argumentsCommandLine.count == 2 {
			self.serverInfo.processFileConfig = argumentsCommandLine[1]
		}
		guard let taskmaster = Taskmaster(processesConfig: self.serverInfo.processFileConfig) else { return nil }
		self.tascmaster = taskmaster
		self.router = Router()
	}
	
	struct ServerInfo {
		var processFileConfig: String = "precesses_config.xml"
		var fileLogs: String = "taskmaster.log"
		var port: Int = 8080
	}
	
	enum QueryParameters: String {
		case command
		case arguments
		case type
		enum TypeStream: String {
			case stdout
			case stderr
		}
	}
	
	public func run() {
		
		Kitura.addHTTPServer(onPort: self.serverInfo.port, with: router)
		// Handle HTTP GET requests to /
		router.get("/") {
			request, response, next in
			guard let cmd = request.queryParameters[QueryParameters.command.rawValue] else { next(); return }
			guard let command = Command(rawValue: cmd) else { next(); return }
			switch command {
			case .status:
				self.sendStatus(response: response)
			case .exit:
				Taskmaster.exitTaskmaster()
			case .stream:
				self.sendStreamProcess(request: request, response: response)
			default:
				let parametersArguments = request.queryParameters[QueryParameters.arguments.rawValue]
				self.tascmaster.executeCommand(command: command, arguments: parametersArguments)
				self.sendStatus(response: response)
			}
		}
		Kitura.run()
	}
	
	/// Отправка потока ошибок или потока вывода
	private func sendStreamProcess(request: RouterRequest, response: RouterResponse) {
		guard let nameProcess = request.queryParameters[QueryParameters.arguments.rawValue] else {
			response.send("Missing query parameter argument.")
			return
		}
		guard let typeStream = request.queryParameters[QueryParameters.type.rawValue] else {
			response.send("Missing query parameter type.")
			return
		}
		guard let type = QueryParameters.TypeStream(rawValue: typeStream) else {
			response.send("The type is specified incorrectly. stdout or stderr")
			return
		}
		guard let stream = self.tascmaster.getStream(nameProcess: nameProcess, type: type) else {
			response.send("Error read stream of \(nameProcess)")
			return
		}
		response.send(stream)
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
