//
//  XMLDataManager.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

class XMLDataManager: NSObject  {
	var parser: XMLParser?
	var pracesses: [DataProcess] = []
	var process: DataProcess?
	var fillData: ((String, Int, Int) -> Void)?
	
	/// Считывает xml файл настроек и возвращает массив процессов
	/// - Parameters:
	///   - xmlFile: Относительный путь до файла.
	/// - Returns: Массив процессов, считанных из файла.
	func getProcesses(xmlFile: String) -> [DataProcess]? {
		let manager = FileManager.default
		let currentDirURL = URL(fileURLWithPath: manager.currentDirectoryPath)
		let fileURL = currentDirURL.appendingPathComponent(xmlFile)
		guard let parser = XMLParser(contentsOf: fileURL) else {
			fatalError("Invalid opened \(xmlFile)")
		}
		self.parser = XMLParser(contentsOf: fileURL)
		parser.delegate = self
		if !parser.parse() {
			return nil
		}
		return self.pracesses
	}
	
	/// Парсит путь до команды и возвращает имя запускаемой программы
	private func getProcessName(command: String?) -> String? {
		guard let command = command else { return nil }
		let elements = command.split() {$0 == "/"}.map( { String($0) } )
		guard let lastElem = elements.last else { return nil }
		return lastElem
	}
	
	/// Считывает путь до программы, которую. необходимо запустить. Так же заполняет имя процесса.
	private func readCommand(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.command = data
		self.process?.nameProcess = getProcessName(command: data)
		if self.process?.nameProcess == nil {
			self.process?.nameProcess = self.process?.command
		}
		Logs.writeLogsToFileLogs(massage: "The following program name was read: \(data)")
	}
	
	/// Считывает аргументы предаваемые в запускаемый процесс.
	private func readArguments(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.arguments = data.split() { $0 == " " }.map{ String($0) }
		Logs.writeLogsToFileLogs(massage: "The following program arguments were read: \(data)")
	}
	
	/// Считывает  количество процессов, которое нужно запустить и поддерживать работу
	private func readNumberProcess(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.numberProcess = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Считывает переменную bool для определения нужно ли запускать приложение при старте.
	private func readAautoStart(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.autoStart = Bool(data)
		if self.process?.autoStart == nil {
			Logs.writeLogsToFileLogs(massage:
				"Error reading a variable of type bool. \(data) line \(line), collumn \(column)")
		} else {
			Logs.writeLogsToFileLogs(massage: "A boolean variable has been read: \(data)")
		}
	}
	
	/// Считывает переменную never, always, или unexpected которая горит, слудует ли перезагружать программу.
	private func readAutoRestart(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		if data == "always" || data == "never" || data == "unexpected" {
			self.process?.autoRestart = data
			Logs.writeLogsToFileLogs(massage: "The reboot option has been read: \(data)")
		}
		else {
			Logs.writeLogsToFileLogs(massage:
				"Invalid reboot option (never, always, or unexpected). \(data) line \(line), collumn \(column)")
		}
	}
	
	/// Считывает ожидаемые коды возврата приложения.
	private func readExitCodes(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.exitCodes = data.split() { $0 == " " }.compactMap{ Int($0) }
		if self.process?.exitCodes == nil {
			Logs.writeLogsToFileLogs(massage:
				"Error reading the return codes. \(data) line \(line), collumn \(column)")
		} else {
			Logs.writeLogsToFileLogs(massage: "The return codes were read: \(data)")
		}
	}
	
	/// Считывает как долго должна быть запущена программа, чтобы считалсть успешно запущенной..
	private func readStartTime(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.startTime = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Считывает количество повторов перезапуска программы.
	private func readStartRetries(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.startRetries = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Считывает сигнал, используемый для остановки программы.
	private func readStopSignal(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.stopSignal = data
		Logs.writeLogsToFileLogs(massage: "Read stop signal: \(data)")
	}
	
	/// Считывает как долго ждать после остановки программы перед тем как убить процесс
	private func readStopTime(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.stopTime = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Считывает куда направлять выходной поток программы.
	private func readStdOut(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.stdOut = data
		Logs.writeLogsToFileLogs(massage: "The following stdout was read: \(data)")
	}
	
	/// Считывает куда направлять выходной поток программы.
	private func readStdErr(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.stdErr = data
		Logs.writeLogsToFileLogs(massage: "The following stderr was read: \(data)")
	}
	
	/// Считывает переменные окружения
	private func readEnvironmenst(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		let words = data.split(){ $0 == " " }.map( { String($0) } )
		for word in words {
			let env = word.split(){ $0 == "=" }.map( { String($0) } )
			if env.count == 2 {
				if self.process?.environmenst == nil {
					self.process?.environmenst = [String: String]()
				}
				self.process?.environmenst?[env[0]] = env[1]
				Logs.writeLogsToFileLogs(massage: "The following Environmenst was read: \(env[0]):\(env[1])")
			}
		}
	}
	
	/// Считывает рабочую директорию запускаемой программы.
	private func readWorkingDir(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.workingDir = data
		Logs.writeLogsToFileLogs(massage: "The following working dir was read: \(data)")
	}
	
	/// Считывает права доступа
	private func readUMask(data: String, line: Int, column: Int) {
		if self.process == nil { return }
		self.process?.umask = convertStringToInt(data: data, line: line, column: column)
	}
	
	/// Переводит строку в целочисленный тип
	private func convertStringToInt(data: String, line: Int, column: Int) -> Int? {
		guard let number = Int(data) else {
			Logs.writeLogsToFileLogs(massage:
				"Error reading a variable of type int. \(data) line \(line), collumn \(column)")
			return nil
		}
		if number < 0 {
			Logs.writeLogsToFileLogs(massage: "Negative integer: \(number) line \(line), collumn \(column)")
			return nil
		} else {
			Logs.writeLogsToFileLogs(massage: "A integer variable has been read: \(data)")
		}
		return number
	}
}

extension XMLDataManager: XMLParserDelegate {
	// Called when opening tag (`<elementName>`) is found
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		if self.process == nil {
			self.process = DataProcess()
		}
		switch elementName {
		case "command":
			self.fillData = readCommand
		case "arguments":
			self.fillData = readArguments
		case "numberprocces":
			self.fillData = readNumberProcess
		case "autostart":
			self.fillData = readAautoStart
		case "autorestart":
			self.fillData = readAutoRestart
		case "exitcodes":
			self.fillData = readExitCodes
		case "starttime":
			self.fillData = readStartTime
		case "startretries":
			self.fillData = readStartRetries
		case "stopsignal":
			self.fillData = readStopSignal
		case "stoptime":
			self.fillData = readStopTime
		case "stdout":
			self.fillData = readStdOut
		case "stderr":
			self.fillData = readStdErr
		case "environmenst":
			self.fillData = readEnvironmenst
		case "workingdir":
			self.fillData = readWorkingDir
		case "umask":
			self.fillData = readUMask
		default:
			break
		}
	}
	
	// Called when closing tag (`</elementName>`) is found
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

		if elementName == "process" {
			guard let process = self.process else { return }
			self.pracesses.append(process)
			self.process = nil
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
		Logs.writeLogsToFileLogs(massage:
			"on: \(parser.lineNumber), at: \(parser.columnNumber) \(parseError.localizedDescription)")
	}

}
