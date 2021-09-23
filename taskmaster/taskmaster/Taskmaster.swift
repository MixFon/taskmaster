//
//  Taskmaster.swift
//  taskmaster
//
//  Created by Михаил Фокин on 30.08.2021.
//

import Foundation

struct Taskmaster {
	static var dataProcesses: [DataProcess]?
	private var processesConfig: String = "precesses_config.xml"
	let lock = NSLock()

	enum Command: String {
		case help
		case start
		case status
		case stop
		case restart
		case exit
		case reload
	}
	
	init?(processesConfig: String) {
		let xmlManager = XMLDataManager()
		guard let dataProcesses = xmlManager.getDataProcesses(xmlFile: processesConfig) else { return nil }
		self.processesConfig = processesConfig
		let set = Set<DataProcess>(dataProcesses)
		Taskmaster.dataProcesses = [DataProcess](set)
		creatingAllProcesses()
		startProcessesAutostart()
	}
	
	/// Возвращает вмассив и информацией о загруженном процессе
	func allInfoPrecesses() -> [InfoProcess]? {
		return Taskmaster.dataProcesses?.map({$0.info})
	}
	
	/// Перехват сигналов.
	static func signalHandler(signal: Int32)->Void {
		guard let sgnl = InfoProcess.Signals(rawValue: signal) else { print("ErrSig01"); return }
		if sgnl == .SIGINT || sgnl == .SIGTERM {
			Taskmaster.exitTaskmaster()
		}
		guard let stopProcesses = self.dataProcesses?.filter({ $0.info.stopSignal == sgnl } ) else  {
			print("ErrSig01")
			return
		}
		for process in stopProcesses {
			guard let index = self.dataProcesses?.firstIndex(where:
				{ $0.info.nameProcess == process.info.nameProcess } ) else { print("ErrFind"); continue }
			if let isRun = self.dataProcesses?[index].process?.isRunning {
				if isRun == true {
					self.dataProcesses?[index].process?.terminate()
				}
			}
		}
	}

	/// Выполнение заданной программы.
	func executeCommand(command: Command, arguments: String?) {
		guard let arguments = arguments?.split(whereSeparator: { $0 == "," }).map( { String($0) } ) else { return }
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
	
	/// Чтение и исполнение команд.
//	func runTaskmaster() {
//		while let line = readLine() {
//			let commands = getCommands(line: line)
//			if commands.count < 1 { continue }
//			guard let first = commands.first else { continue }
//			guard let command = Command(rawValue: first) else {
//				Logs.writeLogsToFileLogs("Invalid command: \(line)")
//				continue
//			}
//			let arguments = commands[1...].map( {String($0)} )
//			print("command: \(command.rawValue)")
//			executeCommand(command: command, arguments: arguments)
//		}
//	}
	
	/// Перезагружает файл с конфигурациями и обновляет данные процессов.
	private func reloadConfigFile() {
		let xmlManager = XMLDataManager()
		guard let newProcess = xmlManager.getDataProcesses(xmlFile: self.processesConfig) else { return }
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
			let status = Taskmaster.dataProcesses?[index].info.status
			let timeStartProcess = Taskmaster.dataProcesses?[index].info.timeStartProcess
			let timeStopProcess = Taskmaster.dataProcesses?[index].info.timeStopProcess
			let statusFinish = Taskmaster.dataProcesses?[index].info.statusFinish
			
			Taskmaster.dataProcesses?[index] = newProcess
			
			Taskmaster.dataProcesses?[index].process = process
			Taskmaster.dataProcesses?[index].info.status = status
			Taskmaster.dataProcesses?[index].info.timeStartProcess = timeStartProcess
			Taskmaster.dataProcesses?[index].info.timeStopProcess = timeStopProcess
			Taskmaster.dataProcesses?[index].info.statusFinish = statusFinish
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
		let finishRunningProcesses = processes.filter( { $0.info.status == .running || $0.info.status == .finish || $0.info.status == .fatal })
		stopArrayProcess(runingProcess: finishRunningProcesses)
		creatingArrayProcesses(dataProcesses: finishRunningProcesses)
		commandStart(arguments: arguments)
	}
	
	/// Остановка запущенных процессов,  переданных в аргументе.
	private func commandStop(arguments: [String]) {
		guard let first = arguments.first else { return }
		if first.lowercased() == "all" {
			guard let dp = Taskmaster.dataProcesses?.filter( { $0.info.status == .running } ) else { return }
			stopArrayProcess(runingProcess: dp)
			return
		}
		let processes = getProcessesToName(arguments: arguments)
		let runningProcesses = processes.filter( { $0.info.status == .running } )
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
		let noStartProcess = processes.filter( { $0.info.status == .no_start } )
		startArrayProcesses(dataProcesses: noStartProcess)
	}
	
	/// Поиск в списке процессов элементов по имени процесса
	private func getProcessesToName(arguments: [String]) -> [DataProcess] {
		var dataProcesses = [DataProcess]()
		for argument in arguments {
			let arr = Taskmaster.dataProcesses!.filter({
				guard let name = $0.info.nameProcess else { return false }
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
		let dataProcessNoStart = dataProcesses.filter( { $0.info.status == .no_start } )
		startArrayProcesses(dataProcesses: dataProcessNoStart)
	}
	
	/// Вывод статуса по процессам.
	private func printStatus() {
		guard let dataProcesses = Taskmaster.dataProcesses else {print("ErrStat"); return }
		printMessage("State\tPID\tName\tTime")
		for data in dataProcesses {
			guard let status = data.info.status else { print("Cont"); continue }
			let time = DateFormatter.getTimeInterval(data.info.timeStartProcess, data.info.timeStopProcess)
			printMessage(String(format:
				"%@\t%5d\t%@\t%@", status.rawValue, data.process?.processIdentifier ?? -1, data.info.nameProcess ?? "", time))
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
		let data = dataProcesses.filter(){ $0.info.autoStart == true }
		startArrayProcesses(dataProcesses: data)
	}
	
	/// Запускает массив процессов.
	private func startArrayProcesses(dataProcesses: [DataProcess]) {
		for dataProcess in dataProcesses {
			startProcess(dataProcess)
		}
	}
	
	/// Уставнока заданного статуса
	private func setStatus(dataProcess: DataProcess, status: InfoProcess.Status) {
		guard let index = findElement(dataProcess: dataProcess) else { return }
		Taskmaster.dataProcesses?[index].info.status = status
	}
	
	/// Запускает одит переданный процесс
	private func startProcess(_ dataProcess: DataProcess) {
		guard let process = dataProcess.process else { return }
		do {
			let start = DispatchTime.now()
			try process.run()
			let end = DispatchTime.now()
			if let startingTime = dataProcess.info.startTime {
				let diff = DispatchTime(uptimeNanoseconds: startingTime)
				if diff.uptimeNanoseconds < end.uptimeNanoseconds - start.uptimeNanoseconds {
					throw "Error start time"
				}
			}
			guard let index = findElement(dataProcess: dataProcess) else { return }
			self.lock.lock()
			Taskmaster.dataProcesses?[index].info.idProcess = Int(process.processIdentifier)
			Taskmaster.dataProcesses?[index].info.timeStartProcess = Date()
			Taskmaster.dataProcesses?[index].info.timeStopProcess = nil
			Taskmaster.dataProcesses?[index].info.statusFinish = nil
			setStatus(dataProcess: dataProcess, status: .running)
			self.lock.unlock()
			guard let name = Taskmaster.dataProcesses?[index].info.nameProcess else { print("Err4"); return }
			print("run process \(process.processIdentifier)", name)
			Logs.writeLogsToFileLogs("Start task: \(process.processIdentifier) \(name)")
		} catch {
			if let index = findElement(dataProcess: dataProcess) {
				if let startRetries = Taskmaster.dataProcesses?[index].info.startRetries {
					if startRetries > 0 {
						Taskmaster.dataProcesses?[index].info.startRetries! -= 1
						print("Retry", Taskmaster.dataProcesses![index].info.startRetries!)
						startProcess(Taskmaster.dataProcesses![index])
						return
					}
				}
			}
			setStatus(dataProcess: dataProcess, status: .fatal)
			Logs.writeLogsToFileLogs("Invalid run process: \(process.processIdentifier)")
		}
	}
	
	/// Вызивается при завершении работы процесса.
	private func processFinish(process: Process) {
		self.lock.lock()
		guard let index = Taskmaster.dataProcesses?.firstIndex(where: { elem in
			guard let id = elem.info.idProcess else { return false }
			return id == process.processIdentifier
		} ) else {
			print("Error 00")
			self.lock.unlock()
			return
		}
		Taskmaster.dataProcesses?[index].info.timeStopProcess = Date()
		guard let dataProcess = Taskmaster.dataProcesses?[index] else {
			print("Error 02")
			self.lock.unlock()
			return
		}
		Taskmaster.dataProcesses?[index].info.statusFinish = getStatusFinish(dataProcess, process)
		Taskmaster.dataProcesses?[index].info.status = .finish
		guard let name = dataProcess.info.nameProcess else {
			print("Error 01")
			self.lock.unlock()
			return
		}
		print("Finish task: \(process.processIdentifier) (\(name))")
		Logs.writeLogsToFileLogs("Finish task: \(process.processIdentifier) (\(name))")
		selectRestartMode(dataProcess: dataProcess)
		self.lock.unlock()
	}
	
	/// Нужно ли перезапускать программу по завершении always, newer, unexpected
	private func selectRestartMode(dataProcess: DataProcess) {
		switch dataProcess.info.autoRestart {
		case .never:
			return
		case .unexpected where dataProcess.info.statusFinish == .fail:
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
		guard let name = dataProcess.info.nameProcess else { return }
		let processes = getProcessesToName(arguments: [name])
		startArrayProcesses(dataProcesses: processes)
	}
	
	/// Возвращает статус завершения программы. Успех если код найден, провал, если код не найден
	private func getStatusFinish(_ dataProcess: DataProcess, _ process: Process) -> InfoProcess.Finish {
		if let codes = dataProcess.info.exitCodes {
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
		if Taskmaster.dataProcesses != nil { return }
		for dataProcess in Taskmaster.dataProcesses! {
			if let process = dataProcess.process {
				if process.isRunning {
					process.terminate()
				}
			}
		}
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
			{ $0.info.nameProcess == dataProcess.info.nameProcess } ) else { return nil }
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
		var dataProcess = dataProcess
		guard let number = dataProcess.info.numberProcess else { return }
		dataProcess.info.numberProcess = 1
		guard let index = findElement(dataProcess: dataProcess) else { return }
		if number > 1 {
			let copies = number - 1
			if copies < dataProcess.info.countCopies { return }
			Taskmaster.dataProcesses?[index].info.countCopies = max(copies, dataProcess.info.countCopies)
			Taskmaster.dataProcesses?[index].info.numberProcess = 1
			creatingDublicateProcess(dataProcess: dataProcess, count: copies - dataProcess.info.countCopies)
		}
		Taskmaster.dataProcesses?[index].process = getProcess(dataProcess: dataProcess)
		setStatus(dataProcess: dataProcess, status: .no_start)
	}
	
	/// Создание будликатов процессов заданного количества и добавление их в общий массив.
	private func creatingDublicateProcess(dataProcess: DataProcess, count: Int) {
		for i in 0..<count {
			var newProcess = dataProcess
			var number = i
			guard let nameProcess = newProcess.info.nameProcess else { continue }
			var name = "\(nameProcess)_\(number)"
			while Taskmaster.dataProcesses!.contains(where: {$0.info.nameProcess == name}) {
				number += 1
				name = "\(nameProcess)_\(number)"
			}
			newProcess.info.nameProcess = name
			newProcess.info.stdOut = addNumberToEnd(path: newProcess.info.stdOut, number: number)
			newProcess.info.stdErr = addNumberToEnd(path: newProcess.info.stdErr, number: number)
			newProcess.process = getProcess(dataProcess: newProcess)
			newProcess.info.status = .no_start
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
		guard let command = dataProcess.info.command else { return nil }
		process.executableURL = URL(fileURLWithPath: command)
		if dataProcess.info.arguments != nil {
			process.arguments = dataProcess.info.arguments
		}
		process.environment = dataProcess.info.environmenst
		process.terminationHandler = processFinish
		if let workingDir = dataProcess.info.workingDir {
			process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
		}
		if let pathStderr = dataProcess.info.stdErr {
			process.standardError = getFileHandle(path: pathStderr)
		} else {
			process.standardError = FileHandle.nullDevice
		}
		if let pathStdout = dataProcess.info.stdOut {
			process.standardOutput = getFileHandle(path: pathStdout)
		} else {
			process.standardOutput = FileHandle.nullDevice
		}
		return process
	}
	
	/// Останавливает один процесс
	private func stopProcess(dataProcess: DataProcess) {
		let index = findElement(dataProcess: dataProcess)!
		let queue = DispatchQueue.global(qos: .default)
		guard let process = dataProcess.process else { return }
		if !process.isRunning { return }
		Taskmaster.dataProcesses?[index].info.status = .stoping
		let timeInterval = dataProcess.info.stopTime
		queue.async {
			let _ = Timer.scheduledTimer(withTimeInterval: timeInterval ?? 0.0, repeats: false, block: { timer in
				if process.isRunning {
					process.terminate()
				}
			})
			if process.isRunning {
				process.interrupt()
				process.waitUntilExit()
			}
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
