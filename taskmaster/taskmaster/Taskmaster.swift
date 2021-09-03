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
		creatingAllProcesses()
		startProcessesAutostart()
	}
	
	/// Чтение и исполнение команд.
	func runTaskmaster() {
		while let line = readLine() {
			guard let command = Commands(rawValue: line) else {
				Logs.writeLogsToFileLogs("Invalid command: \(line)")
				continue
			}
			print("command: \(command.rawValue)")
			switch command {
			case .start:
				startAllProcess()
				//creatingAllProcesses()
			case .status:
				printStatus()
			case .stop:
				stopAllProcesses()
			case .exit:
				exitTaskmaster()
			case .restart:
				restartAllProcesses()
			}
		}
	}
	
	/// Создание всех процессов на основе считанной информации из файла конфигураций
	private func creatingAllProcesses() {
		guard let dataProcesses = self.dataProcesses else { return }
		creatingArrayProcesses(dataProcesses: dataProcesses)
	}
	
	/// Запуск всех процессов
	private func startAllProcess() {
		guard let dataProcesses = self.dataProcesses else { return }
		let dataProcessNoStart = dataProcesses.filter( { $0.status == .noStart } )
		//creatingArrayProcesses(dataProcesses: dataProcessNoStart)
		//let process = dataProcessNoStart.compactMap( { $0.process } )
		startArrayProcesses(dataProcesses: dataProcessNoStart)
	}
	
	/// Вывод статуса по процессам.
	private func printStatus() {
		guard let dataProcesses = self.dataProcesses else { return }
		printMessage("State\tPID\tName")
		for data in dataProcesses {
			guard let status = data.status else { continue }
			printMessage(String(format:
				"%@\t%5d\t%@", status.rawValue, data.process?.processIdentifier ?? -1, data.nameProcess ?? ""))
		}
	}
	
	private func printMessage(_ string: String) {
		print(string)
	}
	
	/// Завершение работы основной программы
	private func exitTaskmaster() {
		Logs.writeLogsToFileLogs("Taskmaster stop")
		stopAllProcesses()
		exit(0)
	}
	
	/// Перезапуск всех процессов
	private func restartAllProcesses() {
		stopAllProcesses()
		creatingAllProcesses()
		startAllProcess()
	}
	
	/// Запуск процессов, которые должны запускаться вместе со стартом программы.
	private func startProcessesAutostart() {
		guard let dataProcesses = self.dataProcesses else { return }
		let data = dataProcesses.filter(){ $0.autoStart == true }
		startArrayProcesses(dataProcesses: data)
	}
	
	/// Запускает массив процессов.
	private func startArrayProcesses(dataProcesses: [DataProcess]) {
		for dataProcess in dataProcesses {
			startProcess(dataProcess)
		}
	}
	
	/// Уставнока заданного статуса
	private func setStatus(dataProcess: DataProcess, status: DataProcess.Status) {
		guard let index = findElement(dataProcess: dataProcess) else { return }
		self.dataProcesses?[index].status = status
	}
	
	/// Запускает одит переданный процесс
	private func startProcess(_ dataProcess: DataProcess) {
		guard let process = dataProcess.process else { return }
		do {
			try process.run()
			setStatus(dataProcess: dataProcess, status: .running)
			Logs.writeLogsToFileLogs("Start task: \(process.processIdentifier)")
			print("run process \(process.processIdentifier)")
		} catch {
			setStatus(dataProcess: dataProcess, status: .errorStart)
			Logs.writeLogsToFileLogs("Invalid run process: \(process.processIdentifier)")
		}
	}
	
	/// Вызивается при завершении работы процесса.
	private func taskFinish(process: Process) {
		print(process.processIdentifier)
		guard let index = self.dataProcesses?.firstIndex(where:
			{ $0.process?.processIdentifier == process.processIdentifier } ) else { return }
		self.dataProcesses?[index].status = .stop
		self.dataProcesses?[index].process = nil
		guard let name = self.dataProcesses?[index].nameProcess else { return }
		Logs.writeLogsToFileLogs("Stop task: \(process.processIdentifier) (\(name))")
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
	
	/// Поитк заданного элемента.
	private func findElement(dataProcess: DataProcess) -> Array<DataProcess>.Index? {
		guard let index = self.dataProcesses?.firstIndex(where:
			{ $0.nameProcess == dataProcess.nameProcess } ) else { return nil }
		return index
	}
	
	/// Создание массива процессов.
	private func creatingArrayProcesses(dataProcesses: [DataProcess]) {
		for var dataProcess in dataProcesses {
			guard let number = dataProcess.numberProcess else { continue }
			dataProcess.numberProcess = 1
			guard let index = findElement(dataProcess: dataProcess) else { continue }
			if number > 1 {
				self.dataProcesses?[index].numberProcess = 1
				creatingDublicateProcess(dataProcess: dataProcess, count: number - 1)
			}
			self.dataProcesses?[index].process = creatingProcess(dataProcess: dataProcess)
			setStatus(dataProcess: dataProcess, status: .noStart)
		}
	}
	
	/// Создание будликатов процессов заданного количества и добавление их в общий массив.
	private func creatingDublicateProcess(dataProcess: DataProcess, count: Int) {
		for i in 0..<count {
			var newProcess = dataProcess
			guard let nameProcess = newProcess.nameProcess else { continue }
			newProcess.nameProcess = "\(nameProcess)_\(i)"
			newProcess.process = creatingProcess(dataProcess: newProcess)
			newProcess.status = .noStart
			self.dataProcesses?.append(newProcess)
		}
	}
	
	/// Создание одного дочернего процесса на основе считанной информации.
	/// - Parameters:
	///   - dataProcess: Информация о процессе, который должен быть запущен
	/// - Returns:
	/// 	Созданый процесс
	private func creatingProcess(dataProcess: DataProcess) -> Process? {
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
				Logs.writeLogsToFileLogs("Invalid exist file \(path)")
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
