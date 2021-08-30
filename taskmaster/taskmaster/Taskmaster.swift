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
		if let pathStdout = dataProcess.stdOut {
			process.standardOutput = getFileHandle(path: pathStdout)
		}
		if let pathStderr = dataProcess.stdErr {
			process.standardError = getFileHandle(path: pathStderr)
		}
		do {
			try process.run()
		} catch {
			Logs.writeLogsToFileLogs(massage: "Invalid run command: \(command)")
		}
	}
	
	/// Возвращает file hendle. Если файл не создан, создает его.
	private func getFileHandle(path: String) -> Any? {
		let fileManager = FileManager.default
		if !fileManager.fileExists(atPath: path) {
			do {
				let fileURL = URL(fileURLWithPath: path)
				try "".write(to: fileURL, atomically: true, encoding: .utf8)
			} catch {
				Logs.writeLogsToFileLogs(massage: "Invalid exist file \(path)")
				return nil
			}
		}
		if let fileHandle = FileHandle(forWritingAtPath: path) {
			fileHandle.seekToEndOfFile()
			return fileHandle
		}
		return nil
	}
}
