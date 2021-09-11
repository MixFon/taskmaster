//
//  Taskmaster.swift
//  taskmaster
//
//  Created by Михаил Фокин on 30.08.2021.
//

import Foundation

class Taskmaster {
	static var dataProcesses: [DataProcess]?
	private var fileProcessSetting: String = "server_config.xml"
	let lock = NSLock()
	static var close: (Int32)->Void = {
		print("Signal",$0)
	}

	enum Commands: String {
		case help
		case start
		case status
		case stop
		case restart
		case exit
		case reload
	}
	
	init() {
		// Тут Чтение настроек запуска сервера.
		let xmlManager = XMLDataManager()
		guard let dataProcesses = xmlManager.getProcesses(xmlFile: self.fileProcessSetting) else { return }
		let set = Set<DataProcess>(dataProcesses)
		Taskmaster.dataProcesses = [DataProcess](set)
		creatingAllProcesses()
		startProcessesAutostart()
	}
	
	static func signalHandler(signal: Int32)->Void {
		guard let sgnl = DataProcess.Signals(rawValue: signal) else { print("ErrSig01"); return }
		if sgnl == .SIGINT || sgnl == .SIGTERM {
			Taskmaster.exitTaskmaster()
		}
		guard let stopProcesses = self.dataProcesses?.filter({ $0.stopSignal == sgnl } ) else  {
			print("ErrSig01")
			return
		}
		print("Couns elemts:", stopProcesses.count)
		for process in stopProcesses {
			guard let index = self.dataProcesses?.firstIndex(where:
				{ $0.nameProcess == process.nameProcess } ) else { print("ErrFind"); continue }
			self.dataProcesses?[index].process?.terminate()
		}
		print("Signal", sgnl, signal)
//		dataProcesses?.forEach( {print($0.nameProcess ?? "Nil")} )
	}

	
	/// Чтение и исполнение команд.
	func runTaskmaster() {
		while let line = readLine() {
			let commands = getCommands(line: line)
			if commands.count < 1 { continue }
			guard let first = commands.first else { continue }
			guard let command = Commands(rawValue: first) else {
				Logs.writeLogsToFileLogs("Invalid command: \(line)")
				continue
			}
			let arguments = commands[1...].map( {String($0)} )
			print("command: \(command.rawValue)")
			switch command {
			case .help:
				printHelp()
			case .status:
				printStatus()
			case .exit:
				Taskmaster.exitTaskmaster()
			case .start:
				commandStart(arguments: arguments)
			case .stop:
				commandStop(arguments: arguments)
			case .restart:
				commandRestart(arguments: arguments)
			case .reload:
				reloadConfigFile()
			}
		}
	}
	
	/// Перезагружает файл с конфигурациями и обновляет данные процессов.
	private func reloadConfigFile() {
		let xmlManager = XMLDataManager()
		guard let newProcess = xmlManager.getProcesses(xmlFile: self.fileProcessSetting) else { return }
		guard let oldProcess = Taskmaster.dataProcesses else { return }
		let newSet = Set<DataProcess>(newProcess)
		let oldSet = Set<DataProcess>(oldProcess)
		let sub = newSet.subtracting(oldSet)
		let arrSub = [DataProcess](sub)
		Taskmaster.dataProcesses?.append(contentsOf: arrSub)
		creatingArrayProcesses(dataProcesses: arrSub)
		let newArrayProcess = [DataProcess](newSet)
		updateDataProcesses(newProcesses: newArrayProcess)
	}
	
	/// Обновляет данные в массиве процессов
	private func updateDataProcesses(newProcesses: [DataProcess]) {
		for newProcess in newProcesses {
			guard let index = findElement(dataProcess: newProcess) else { print("Err02"); return }
			let process = Taskmaster.dataProcesses?[index].process
			let status = Taskmaster.dataProcesses?[index].status
			let timeStartProcess = Taskmaster.dataProcesses?[index].timeStartProcess
			let timeStopProcess = Taskmaster.dataProcesses?[index].timeStopProcess
			let statusFinish = Taskmaster.dataProcesses?[index].statusFinish
			
			Taskmaster.dataProcesses?[index] = newProcess
			
			Taskmaster.dataProcesses?[index].process = process
			Taskmaster.dataProcesses?[index].status = status
			Taskmaster.dataProcesses?[index].timeStartProcess = timeStartProcess
			Taskmaster.dataProcesses?[index].timeStopProcess = timeStopProcess
			Taskmaster.dataProcesses?[index].statusFinish = statusFinish
		}
	}
	
	/// Перезапуск остановленных и запушенных процессов
	private func commandRestart(arguments: [String]) {
		guard let first = arguments.first else { return }
		if first.lowercased() == "all" {
			restartAllProcesses()
			return
		}
		let processes = getProcessesToName(arguments: arguments)
		let finishRunningProcesses = processes.filter( { $0.status == .running || $0.status == .finish || $0.status == .errorStart })
		stopArrayProcess(runingProcess: finishRunningProcesses)
		creatingArrayProcesses(dataProcesses: finishRunningProcesses)
		commandStart(arguments: arguments)
	}
	
	/// Остановка запущенных процессов,  переданных в аргументе.
	private func commandStop(arguments: [String]) {
		guard let first = arguments.first else { return }
		if first.lowercased() == "all" {
			Taskmaster.stopAllProcesses()
			return
		}
		let processes = getProcessesToName(arguments: arguments)
		let runningProcesses = processes.filter( { $0.status == .running } )
		stopArrayProcess(runingProcess: runningProcesses)
	}
	
	/// Запуск процессов переданных в виде аргументов. Запускает только те, которые не были запущены.
	private func commandStart(arguments: [String]) {
		guard let first = arguments.first else { return }
		if first.lowercased() == "all" {
			startAllProcess()
			return
		}
		let processes = getProcessesToName(arguments: arguments)
		let noStartProcess = processes.filter( { $0.status == .noStart } )
		startArrayProcesses(dataProcesses: noStartProcess)
	}
	
	/// Поиск в списке процессов элементов по имени процесса
	private func getProcessesToName(arguments: [String]) -> [DataProcess] {
		var dataProcesses = [DataProcess]()
		for argument in arguments {
			let arr = Taskmaster.dataProcesses!.filter({
				guard let name = $0.nameProcess else { return false }
				return name == argument
			})
			dataProcesses.append(contentsOf: arr)
		}
		return dataProcesses
	}
	
	/// Печатает подсказку
	private func printHelp() {
		printMessage(
			"""
			Commands:
			help			: Show help
			exit			: Exit the program
			status			: Show status process
			reload			: Reloading the xml settings file
			start <processes>	: Starts desired program(s)
			stop <processes>	: Stop desired program(s)
			restart <processes>	: Restart desired program(s)
			""")
	}
	
	/// Разделение строки на слова.
	private func getCommands(line: String) -> [String] {
		let commands = line.split() { $0 == " " }.map( { String($0) } )
		return commands
	}
	
	/// Создание всех процессов на основе считанной информации из файла конфигураций
	private func creatingAllProcesses() {
		guard let dataProcesses = Taskmaster.dataProcesses else { return }
		creatingArrayProcesses(dataProcesses: dataProcesses)
	}
	
	/// Запуск всех незапущенных процессов
	private func startAllProcess() {
		guard let dataProcesses = Taskmaster.dataProcesses else { return }
		let dataProcessNoStart = dataProcesses.filter( { $0.status == .noStart } )
		//creatingArrayProcesses(dataProcesses: dataProcessNoStart)
		//let process = dataProcessNoStart.compactMap( { $0.process } )
		startArrayProcesses(dataProcesses: dataProcessNoStart)
	}
	
	/// Вывод статуса по процессам.
	private func printStatus() {
		guard let dataProcesses = Taskmaster.dataProcesses else { return }
		printMessage("State\tPID\tName\tTime")
		for data in dataProcesses {
			guard let status = data.status else { print("Cont"); continue }
			let time = DateFormatter.getTimeInterval(data.timeStartProcess, data.timeStopProcess)
			printMessage(String(format:
				"%@\t%5d\t%@\t%@", status.rawValue, data.process?.processIdentifier ?? -1, data.nameProcess ?? "", time))
		}
	}
	
	private func printMessage(_ string: String) {
		print(string)
	}
	
	/// Завершение работы основной программы
	static func exitTaskmaster() {
		Logs.writeLogsToFileLogs("Taskmaster stop")
		stopAllProcesses()
		exit(0)
	}
	
	/// Перезапуск всех процессов
	private func restartAllProcesses() {
		Taskmaster.stopAllProcesses()
		creatingAllProcesses()
		startAllProcess()
	}
	
	/// Запуск процессов, которые должны запускаться вместе со стартом программы.
	private func startProcessesAutostart() {
		guard let dataProcesses = Taskmaster.dataProcesses else { return }
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
		Taskmaster.dataProcesses?[index].status = status
	}
	
	/// Запускает одит переданный процесс
	private func startProcess(_ dataProcess: DataProcess) {
		guard let process = dataProcess.process else { return }
		do {
			let start = DispatchTime.now()
			try process.run()
			let end = DispatchTime.now()
			if let startingTime = dataProcess.startTime {
				let diff = DispatchTime(uptimeNanoseconds: startingTime)
				if diff.uptimeNanoseconds < end.uptimeNanoseconds - start.uptimeNanoseconds { throw NSError() }
			}
			guard let index = findElement(dataProcess: dataProcess) else { return }
			Taskmaster.dataProcesses?[index].timeStartProcess = Date()
			Taskmaster.dataProcesses?[index].timeStopProcess = nil
			Taskmaster.dataProcesses?[index].statusFinish = nil
			setStatus(dataProcess: dataProcess, status: .running)
			guard let name = Taskmaster.dataProcesses?[index].nameProcess else { print("Err4"); return }
			print("run process \(process.processIdentifier)", name)
			Logs.writeLogsToFileLogs("Start task: \(process.processIdentifier)")
		} catch {
			if let index = findElement(dataProcess: dataProcess) {
				if let startRetries = Taskmaster.dataProcesses?[index].startRetries {
					if startRetries > 0 {
						Taskmaster.dataProcesses?[index].startRetries! -= 1
						print("Retry", Taskmaster.dataProcesses![index].startRetries!)
						startProcess(Taskmaster.dataProcesses![index])
						return
					}
				}
			}
			setStatus(dataProcess: dataProcess, status: .errorStart)
			Logs.writeLogsToFileLogs("Invalid run process: \(process.processIdentifier)")
		}
	}
	
	/// Вызивается при завершении работы процесса.
	private func processFinish(process: Process) {
		self.lock.lock()
		guard let index = Taskmaster.dataProcesses?.firstIndex(where:
			{ $0.process?.processIdentifier == process.processIdentifier } ) else { print("Error 00"); return }
		Taskmaster.dataProcesses?[index].timeStopProcess = Date()
		guard let dataProcess = Taskmaster.dataProcesses?[index] else { print("Error 02"); return }
		Taskmaster.dataProcesses?[index].statusFinish = getStatusFinish(dataProcess, process)
		Taskmaster.dataProcesses?[index].status = .finish
		guard let name = dataProcess.nameProcess else { print("Error 01"); return }
		print("finish:", name, process.processIdentifier)
		print("terminatio Statio", process.terminationStatus)
		Logs.writeLogsToFileLogs("Finish task: \(process.processIdentifier) (\(name))")
		selectRestartMode(dataProcess: dataProcess)
		self.lock.unlock()
	}
	
	/// Нужно ли перезапускать программу по завершении always, newer, unexpected
	private func selectRestartMode(dataProcess: DataProcess) {
		switch dataProcess.autoRestart {
		case .never:
			return
		case .unexpected where dataProcess.statusFinish == .fail:
			restarMode(dataProcess: dataProcess)
		case .always:
			restarMode(dataProcess: dataProcess)
		default:
			return
		}
	}
	
	/// Перезапуск процесса в случае флага always или unexpected
	private func restarMode(dataProcess: DataProcess) {
		createProcess(dataProcess: dataProcess)
		guard let name = dataProcess.nameProcess else { return }
		let processes = getProcessesToName(arguments: [name])
		startArrayProcesses(dataProcesses: processes)
	}
	
	/// Возвращает статус завершения программы. Успех если код найден, провал, если код не найден
	private func getStatusFinish(_ dataProcess: DataProcess, _ process: Process) -> DataProcess.Finish {
		if let codes = dataProcess.exitCodes {
			if codes.contains(process.terminationStatus) {
				return .success
			} else {
				return .fail
			}
		}
		if process.terminationStatus == 0 {
			return .success
		} else {
			return .fail
		}
	}
	
	/// Остановка всех процессов.
	static func stopAllProcesses() {
		Taskmaster.dataProcesses?.forEach( {
			if $0.process != nil {
				if $0.process!.isRunning {
					$0.process?.terminate()
				}
			}
		})
//		guard let dataProcesses = Taskmaster.dataProcesses else { return }
//		let isRuningProcess = dataProcesses.filter( { $0.process?.isRunning == true } )
//		stopArrayProcess(runingProcess: isRuningProcess)
	}
	
	/// Остановка массива процессов
	private func stopArrayProcess(runingProcess dataProcess: [DataProcess]) {
		for process in dataProcess {
			stopProcess(dataProcess: process)
		}
	}
	
	/// Поитк заданного элемента.
	private func findElement(dataProcess: DataProcess) -> Array<DataProcess>.Index? {
		guard let index = Taskmaster.dataProcesses?.firstIndex(where:
			{ $0.nameProcess == dataProcess.nameProcess } ) else { return nil }
		return index
	}
	
	/// Создание массива процессов.
	private func creatingArrayProcesses(dataProcesses: [DataProcess]) {
		for dataProcess in dataProcesses {
			createProcess(dataProcess: dataProcess)
		}
	}
	
	/// Создание одного процесса по заданной информации и добавление/обнавление в массиве
	private func createProcess(dataProcess: DataProcess) {
		//self.dataProcesses?.forEach({print($0.nameProcess)})
		var dataProcess = dataProcess
		guard let number = dataProcess.numberProcess else { return }
		dataProcess.numberProcess = 1
		guard let index = findElement(dataProcess: dataProcess) else { return }
		if number > 1 {
			Taskmaster.dataProcesses?[index].numberProcess = 1
			creatingDublicateProcess(dataProcess: dataProcess, count: number - 1)
		}
		Taskmaster.dataProcesses?[index].process = getProcess(dataProcess: dataProcess)
		setStatus(dataProcess: dataProcess, status: .noStart)
	}
	
	/// Создание будликатов процессов заданного количества и добавление их в общий массив.
	private func creatingDublicateProcess(dataProcess: DataProcess, count: Int) {
		for i in 0..<count {
			var newProcess = dataProcess
			var number = i
			guard let nameProcess = newProcess.nameProcess else { continue }
			var name = "\(nameProcess)_\(number)"
			while Taskmaster.dataProcesses!.contains(where: {$0.nameProcess == name}) {
				number += 1
				name = "\(nameProcess)_\(number)"
			}
			newProcess.nameProcess = name
			newProcess.stdOut = addNumberToEnd(path: newProcess.stdOut, number: number)
			newProcess.stdErr = addNumberToEnd(path: newProcess.stdErr, number: number)
			newProcess.process = getProcess(dataProcess: newProcess)
			newProcess.status = .noStart
			Taskmaster.dataProcesses?.append(newProcess)
		}
	}
	
	/// Добавляет число к в конец пути перед расширением.
	private func addNumberToEnd(path: String?, number: Int) -> String? {
		if let path = path {
			var url = URL(string: path)
			let extention = url?.pathExtension
			url?.deletePathExtension()
			guard let absolute = url?.absoluteString else { return nil }
			let result = absolute + "_\(number)"
			guard var newUrl = URL(string: result) else { return nil }
			if let exten = extention {
				newUrl.appendPathExtension(exten)
			}
			return newUrl.absoluteString
		}
		return nil
	}
	
	/// Создание одного дочернего процесса на основе считанной информации.
	/// - Parameters:
	///   - dataProcess: Информация о процессе, который должен быть запущен
	/// - Returns:
	/// 	Созданый процесс
	private func getProcess(dataProcess: DataProcess) -> Process? {
		let process = Process()
		guard let command = dataProcess.command else { return nil }
		process.executableURL = URL(fileURLWithPath: command)
		if dataProcess.arguments != nil {
			process.arguments = dataProcess.arguments
		}
		process.environment = dataProcess.environmenst
		process.terminationHandler = processFinish
		if let workingDir = dataProcess.workingDir {
			process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
		}
		if let pathStderr = dataProcess.stdErr {
			process.standardError = getFileHandle(path: pathStderr)
		} else {
			process.standardError = FileHandle.nullDevice
		}
		if let pathStdout = dataProcess.stdOut {
			process.standardOutput = getFileHandle(path: pathStdout)
		} else {
			process.standardOutput = FileHandle.nullDevice
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
		do {
			let fileURL = URL(fileURLWithPath: path)
			try "".write(to: fileURL, atomically: true, encoding: .utf8)
		} catch {
			Logs.writeLogsToFileLogs("Invalid exist file \(path)")
			return nil
		}
		if let fileHandle = FileHandle(forWritingAtPath: path) {
			return fileHandle
		}
		return nil
	}
}
