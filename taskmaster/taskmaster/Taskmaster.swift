//
//  Taskmaster.swift
//  taskmaster
//
//  Created by Михаил Фокин on 30.08.2021.
//

import Foundation

class Taskmaster {
	private var dataProcesses: [DataProcess]?
	private var fileProcessSetting: String = "server_config.xml"
	
	init() {
		// Чтение настроек запуска сервера.
		let xmlManager = XMLDataManager()
		self.dataProcesses = xmlManager.getProcesses(xmlFile: self.fileProcessSetting)
	}
	
	/// Запуск дочерних процессов
	func run() {
		guard let dataProcesses = self.dataProcesses else { return }
		for dataProcess in dataProcesses {
			runProcess(dataProcess: dataProcess)
		}
	}
	
	/// Запуск одного дочернего процесса на основе считанной информации.
	private func runProcess(dataProcess: DataProcess) {
		let process = Process()
		guard let command = dataProcess.command else { return }
		process.executableURL = URL(fileURLWithPath: command)
		process.arguments = dataProcess.arguments
		process.environment = dataProcess.environmenst
		if let workingDir = dataProcess.workingDir {
			process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
		}
//		let outputPipe = Pipe()
//		process.standardOutput = outputPipe
//		let errorPipe = Pipe()
//		process.standardError = errorPipe
		if let pathStdout = dataProcess.stdOut {
			if let fileHandle = FileHandle(forWritingAtPath: pathStdout) {
				fileHandle.seekToEndOfFile()
				//_ = try? fileHandle?.seekToEnd()
				//_ = try? fileHandle?.synchronize()
				process.standardOutput = fileHandle
	//			let outputPipe = Pipe()
	//			process.standardOutput = outputPipe
				//print(process.standardOutput)
			} else {
				
			}
		}
		if let pathStderr = dataProcess.stdErr {
			process.standardError = FileHandle(forWritingAtPath: pathStderr)
			//print(process.standardError)
		}
		do {
			try process.run()
//			let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
//			let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//			print(String(decoding: outputData, as: UTF8.self) )
//			print(String(decoding: errorData, as: UTF8.self) )
		} catch {
			print("Invalid run \(dataProcess.command!)")
		}
		
	}
}
