//
//  XMLDataManager.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation
import DataProcess

class XMLDataManager: NSObject  {
	var parser: XMLParser?
	var processes: [DataProcess] = []
	var infoProcesses: InfoProcess?
	var infoServer = ServerTM.ServerInfo()
	var fillData: ((String, Int, Int) -> Void)?
	
	enum Element: String {
		case name
		case command
		case arguments
		case numberprocces
		case autostart
		case autorestart
		case exitcodes
		case starttime
		case startretries
		case stopsignal
		case stoptime
		case stdout
		case stderr
		case environmenst
		case workingdir
		case umask

		// Ниже поля для настроек файла конфигураций сервера.
		case filelogs
		case port
		case processconfig
	}
	
	/// Считывает xml файл настроек и возвращает массив процессов
	/// - Parameters:
	///   - xmlFile: Относительный путь до файла.
	/// - Returns: Массив процессов, считанных из файла.
	func getDataProcesses(xmlFile: String) -> [DataProcess]? {
		if !parsingXML(xmlFile: xmlFile) { return nil }
		return self.processes
	}
	
	/// Парсит файл настроек сервера.
	func getServerInfo(xmlFile: String) -> ServerTM.ServerInfo? {
		if !parsingXML(xmlFile: xmlFile) { return nil }
		return self.infoServer
	}
	
	/// Производит парсинг xml файла. Поиск файла идет в дериктории приложения.
	private func parsingXML(xmlFile: String) -> Bool {
		let fileManager = FileManager.default
		var currentDirUrl = URL(fileURLWithPath: fileManager.currentDirectoryPath)
		currentDirUrl.appendPathComponent(xmlFile)
		guard let parser = XMLParser(contentsOf: currentDirUrl.absoluteURL) else {
			print("Invalid opened xml file:", xmlFile)
			return false
		}
		self.parser = XMLParser(contentsOf: currentDirUrl.absoluteURL)
		parser.delegate = self
		if !parser.parse() {
			print("Error read xml file:", xmlFile)
			Logs.writeLogsToFileLogs("Error read xml file.")
			return false
		}
		return true
	}
	
	/// Парсит путь до команды и возвращает имя запускаемой программы
	private func getProcessName(command: String?) -> String? {
		guard let command = command else { return nil }
		let elements = command.split() {$0 == "/"}.map( { String($0) } )
		guard let lastElem = elements.last else { return nil }
		return lastElem
	}
	
	/// Считывает имя программы
	private func readName(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.nameProcess = data
		Logs.writeLogsToFileLogs("The following program name was read: \(data)")
	}
	
	/// Считывает путь до программы, которую. необходимо запустить. Так же заполняет имя процесса.
	private func readCommand(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.command = data
		if self.infoProcesses?.nameProcess == nil {
			self.infoProcesses?.nameProcess = getProcessName(command: data)
		}
		if self.infoProcesses?.nameProcess == nil {
			self.infoProcesses?.nameProcess = self.infoProcesses?.command
		}
		Logs.writeLogsToFileLogs("The following program command was read: \(data)")
	}
	
	/// Считывает аргументы предаваемые в запускаемый процесс.
	private func readArguments(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.arguments = data.split() { $0 == " " }.map{ String($0) }
		Logs.writeLogsToFileLogs("The following program arguments were read: \(data)")
	}
	
	/// Считывает  количество процессов, которое нужно запустить и поддерживать работу
	private func readNumberProcess(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.numberProcess = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Считывает переменную bool для определения нужно ли запускать приложение при старте.
	private func readAautoStart(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.autoStart = Bool(data)
		if self.infoProcesses?.autoStart == nil {
			Logs.writeLogsToFileLogs(
				"Error reading a variable of type bool. \(data) line \(line), collumn \(column)")
		} else {
			Logs.writeLogsToFileLogs("A boolean variable has been read: \(data)")
		}
	}
	
	/// Считывает переменную never, always, или unexpected которая горит, слудует ли перезагружать программу.
	private func readAutoRestart(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		if let autoRestart = AutoRestart(rawValue: data) {
			self.infoProcesses?.autoRestart = autoRestart
			Logs.writeLogsToFileLogs("The reboot option has been read: \(data)")
		}
		else {
			Logs.writeLogsToFileLogs(
				"Invalid reboot option (never, always, or unexpected). \(data) line \(line), collumn \(column)")
		}
	}
	
	/// Считывает ожидаемые коды возврата приложения.
	private func readExitCodes(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.exitCodes = data.split() { $0 == " " }.compactMap{ Int32($0) }
		if self.infoProcesses?.exitCodes == nil {
			Logs.writeLogsToFileLogs(
				"Error reading the return codes. \(data) line \(line), collumn \(column)")
		} else {
			Logs.writeLogsToFileLogs("The return codes were read: \(data)")
		}
	}
	
	/// Считывает как долго должна быть запущена программа, чтобы считалсть успешно запущенной..
	private func readStartTime(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.startTime = UInt64(data)
	}
	
	/// Считывает как долго ждать после остановки программы перед тем как убить процесс
	private func readStopTime(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.stopTime = Double(data)
	}
	
	/// Считывает количество повторов перезапуска программы.
	private func readStartRetries(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.startRetries = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Считывает сигнал, используемый для остановки программы.
	private func readStopSignal(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		guard let sgnl = Signals(signal: data) else { return }
		self.infoProcesses?.stopSignal = sgnl
		Logs.writeLogsToFileLogs("Read stop signal: \(data)")
	}
	
	/// Считывает куда направлять выходной поток программы.
	private func readStdOut(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.stdOut = data
		Logs.writeLogsToFileLogs("The following stdout was read: \(data)")
	}
	
	/// Считывает куда направлять выходной поток программы.
	private func readStdErr(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.stdErr = data
		Logs.writeLogsToFileLogs("The following stderr was read: \(data)")
	}
	
	/// Считывает переменные окружения
	private func readEnvironmenst(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		let words = data.split(){ $0 == " " }.map( { String($0) } )
		for word in words {
			let env = word.split(){ $0 == "=" }.map( { String($0) } )
			if env.count == 2 {
				if self.infoProcesses?.environmenst == nil {
					self.infoProcesses?.environmenst = [String: String]()
				}
				self.infoProcesses?.environmenst?[env[0]] = env[1]
				Logs.writeLogsToFileLogs("The following Environmenst was read: \(env[0]):\(env[1])")
			}
		}
	}
	
	/// Считывает рабочую директорию запускаемой программы.
	private func readWorkingDir(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.workingDir = data
		Logs.writeLogsToFileLogs("The following working dir was read: \(data)")
	}
	
	/// Считывает права доступа
	private func readUMask(data: String, line: Int, column: Int) {
		if self.infoProcesses == nil { return }
		self.infoProcesses?.umask = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Переводит строку в целочисленный тип
	private func convertStringToInt(data: String, line: Int, column: Int) -> Int? {
		guard let number = Int(data) else {
			Logs.writeLogsToFileLogs(
				"Error reading a variable of type int. \(data) line \(line), collumn \(column)")
			return nil
		}
		if number < 0 {
			Logs.writeLogsToFileLogs("Negative integer: \(number) line \(line), collumn \(column)")
			return nil
		} else {
			Logs.writeLogsToFileLogs("A integer variable has been read: \(data)")
		}
		return number
	}
	
	/// Чтение имени файла лога.
	private func readNameFileLogs(data: String, line: Int, column: Int) {
		self.infoServer.fileLogs = data
		Logs.writeLogsToFileLogs("Read name file logs: \(data)")
	}
	
	/// Чтение порта.
	private func readPort(data: String, line: Int, column: Int) {
		if let port = convertStringToInt(data: data, line: line, column: column) {
			self.infoServer.port = port
		}
	}
	
	/// Чтение файла конфигураций
	private func readProcessFileConfig(data: String, line: Int, column: Int) {
		self.infoServer.processFileConfig = data
		Logs.writeLogsToFileLogs("Read name file logs: \(data)")
	}
}

extension XMLDataManager: XMLParserDelegate {
	// Called when opening tag (`<elementName>`) is found
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		if self.infoProcesses == nil {
			self.infoProcesses = InfoProcess()
		}
		switch Element(rawValue: elementName) {
		case .name:
			self.fillData = readName
		case .command:
			self.fillData = readCommand
		case .arguments:
			self.fillData = readArguments
		case .numberprocces:
			self.fillData = readNumberProcess
		case .autostart:
			self.fillData = readAautoStart
		case .autorestart:
			self.fillData = readAutoRestart
		case .exitcodes:
			self.fillData = readExitCodes
		case .starttime:
			self.fillData = readStartTime
		case .startretries:
			self.fillData = readStartRetries
		case .stopsignal:
			self.fillData = readStopSignal
		case .stoptime:
			self.fillData = readStopTime
		case .stdout:
			self.fillData = readStdOut
		case .stderr:
			self.fillData = readStdErr
		case .environmenst:
			self.fillData = readEnvironmenst
		case .workingdir:
			self.fillData = readWorkingDir
		case .umask:
			self.fillData = readUMask
		
		// Поля конфигурации сервера.
		case .filelogs:
			self.fillData = readNameFileLogs
		case .port:
			self.fillData = readPort
		case .processconfig:
			self.fillData = readProcessFileConfig
		default:
			break
		}
	}
	
	// Called when closing tag (`</elementName>`) is found
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if elementName == "process" {
			guard let info = self.infoProcesses else { return }
			let dataProcess = DataProcess(process: nil, info: info)
			self.processes.append(dataProcess)
			self.infoProcesses = nil
		}
	}
	
	// Called when a character sequence is found
	// This may be called multiple times in a single element
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if data.isEmpty { return }
		guard let fillData = self.fillData else { return }
		fillData(data, parser.lineNumber, parser.columnNumber)
	}
	
	// Called when a CDATA block is found
	func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
		guard let string = String(data: CDATABlock, encoding: .utf8) else {
			print("CDATA contains non-textual data, ignored")
			return
		}
		print("CDATA block is found [\(string)]")
	}
	
	// For debugging
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		Logs.writeLogsToFileLogs(
			"on: \(parser.lineNumber), at: \(parser.columnNumber) \(parseError.localizedDescription)")
	}

}
