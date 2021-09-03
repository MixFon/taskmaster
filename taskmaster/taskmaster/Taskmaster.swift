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
	
	enum Commands: String {
		case start
		case status
		case stop
		case restart
		case exit
	}
	
	init() {
		// Тут Чтение настроек запуска сервера.
		let xmlManager = XMLDataManager()
		self.dataProcesses = xmlManager.getProcesses(xmlFile: self.fileProcessSetting)
		startProcessesAutostart()
	}
	
	/// Чтение и исполнение команд.
	func runTaskmaster() {
		while let line = readLine() {
			guard let command = Commands(rawValue: line) else {
				Logs.writeLogsToFileLogs(massage: "Invalid command: \(line)")
				continue
			}
			print("command: \(command.rawValue)")
			switch command {
			case .start:
				startAllProcesses()
			case .status:
				startAllProcesses()
			case .stop:
				stopAllProcesses()
			case .exit:
				exitTaskmaster()
			case .restart:
				restartAllProcesses()
			}
		}
	}
	
	/// Вывод статуса по процессам.
	private func printStatus() {
		
	}
	
	/// Завершение работы основной программы
	private func exitTaskmaster() {
		Logs.writeLogsToFileLogs(massage: "Taskmaster stop")
		exit(0)
	}
	
	private func restartAllProcesses() {
		stopAllProcesses()
		startAllProcesses()
	}
	
	/// Запуск процессов, которые должны запускаться вместе со стартом программы.
	private func startProcessesAutostart() {
		guard let dataProcesses = self.dataProcesses else { return }
		let processes = dataProcesses.filter(){ $0.autoStart == true }
		startArrayProcesses(dataProcesses: processes)
	}
	
	/// Запуск всех процессов, которы не были запучены
	private func startAllProcesses() {
		guard let dataProcesses = self.dataProcesses else { return }
		let notRunProcess = dataProcesses.filter( { data in
			guard let process = data.process else { return true }
			return process.isRunning == false
		})
		startArrayProcesses(dataProcesses: notRunProcess)
	}
	
	/// Вызивается при завершении работы процесса.
	private func taskFinish(process: Process) {
		print(process.processIdentifier)
		Logs.writeLogsToFileLogs(massage: "Stop task: \(process.processIdentifier)")
	}
	
	/// Остановка всех процессов.
	private func stopAllProcesses() {
		guard let dataProcesses = self.dataProcesses else { return }
		let isRuningProcess = dataProcesses.filter( { $0.process?.isRunning == true } )
		stopArrayProcess(runingProcess: isRuningProcess)
	}
	
	/// Остановка массива процессов
	private func stopArrayProcess(runingProcess dataProcess: [DataProcess]) {
		for process in dataProcess {
			stopProcess(dataProcess: process)
		}
	}
	
	/// Запуск массива процессов.
	private func startArrayProcesses(dataProcesses: [DataProcess]) {
		for var dataProcess in dataProcesses {
			if let number = dataProcess.numberProcess {
				dataProcess.numberProcess = 1
				if number > 1 {
					for i in 0..<number {
						var newProcess = dataProcess
						guard let nameProcess = newProcess.nameProcess else { continue }
						newProcess.nameProcess = "\(nameProcess)_\(i)"
						newProcess.process = startProcess(dataProcess: newProcess)
						self.dataProcesses?.append(newProcess)
					}
				} else {
					if let index = self.dataProcesses?.firstIndex(where: { $0.nameProcess == dataProcess.nameProcess}) {
						self.dataProcesses?[index].process = startProcess(dataProcess: dataProcess)
					}
				}
			}
		}
	}
	
	/// Запуск одного дочернего процесса на основе считанной информации.
	/// - Parameters:
	///   - dataProcess: Информация о процессе, который должен быть запущен
	/// - Returns:
	/// 	созданый процесс
	private func startProcess(dataProcess: DataProcess) -> Process? {
		let process = Process()
		guard let command = dataProcess.command else { return nil }
		process.executableURL = URL(fileURLWithPath: command)
		process.arguments = dataProcess.arguments
		process.environment = dataProcess.environmenst
		process.terminationHandler = taskFinish
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
			Logs.writeLogsToFileLogs(massage: "Start task: \(process.processIdentifier) (\(dataProcess.nameProcess ?? ""))")
			print("run process \(dataProcess.nameProcess!)")
		} catch {
			Logs.writeLogsToFileLogs(massage: "Invalid run command: \(command)")
		}
		return process
	}
	
	/// Останавливает один процесс
	private func stopProcess(dataProcess: DataProcess) {
		dataProcess.process?.terminate()
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
