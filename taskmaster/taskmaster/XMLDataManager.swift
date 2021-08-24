//
//  XMLDataManager.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

class XMLDataManager: NSObject  {
	var parser: XMLParser?
	var pracesses: [Process] = []
	var process: Process?
	var fillData: ((String) -> Void)?
	
	/// Считывает xml файл настроек и возвращает массив процессов
	/// - Parameters:
	///   - xmlFile: Относительный путь до файла.
	/// - Returns: Массив процессов, считанных из файла.
	func getProcesses(xmlFile: String) -> [Process] {
		let manager = FileManager.default
		let currentDirURL = URL(fileURLWithPath: manager.currentDirectoryPath)
		let fileURL = currentDirURL.appendingPathComponent(xmlFile)
		guard let parser = XMLParser(contentsOf: fileURL) else {
			fatalError("Invalid opened \(xmlFile)")
		}
		self.parser = XMLParser(contentsOf: fileURL)
		parser.delegate = self
		parser.parse()
		return self.pracesses
	}
	
	/// Считывает программу, котору. необходимо запустить.
	private func readCommand(data: String) {
		if self.process == nil { return }
		self.process?.command = data
	}
	
	/// Считывает аргументы предаваемые в запускаемый процесс.
	private func readArguments(data: String) {
		if self.process == nil { return }
		self.process?.arguments = data.split() { $0 == " " }.map{ String($0) }
	}
	
	/// Считывает  количество процессов, которое нужно запустить и поддерживать работу
	private func readNumberProcess(data: String) {
		if self.process == nil { return }
		self.process?.numberProcess = Int(data)
	}
	
	/// Считывает переменную bool для определения нужно ли запускать приложение при старте.
	private func readAautoStart(data: String) {
		if self.process == nil { return }
		self.process?.autoStart = Bool(data)
	}
	
	/// Считывает переменную never, always, or unexpected которая горит, слудует ли перезагружать программу.
	private func readAutoRestart(data: String) {
		if self.process == nil { return }
		if data == "always" || data == "never" || data == "unexpected" {
			self.process?.autoRestart = data
		}
		else {
			print("Error \(data)")
			//!!!!!!!!!!!!!!!!!
		}
	}
	
	/// Считывает ожидаемые коды возврата приложения.
	private func readExitCodes(data: String) {
		if self.process == nil { return }
		self.process?.exitCodes = data.split() { $0 == " " }.compactMap{ Int($0) }
	}
	
	/// Считывает как долго должна быть запущена программа, чтобы считалсть успешно запущенной..
	private func readStartTime(data: String) {
		if self.process == nil { return }
		self.process?.startTime = Int(data)
		guard let time = self.process?.startTime else { return }
		if time < 0 {
			print("Error time \(time)")
		}
	}
	
	/// Считывает количество повторов перезапуска программы.
	private func readStartRetries(data: String) {
		if self.process == nil { return }
		self.process?.startRetries = Int(data)
		guard let retries = self.process?.startRetries else { return }
		if retries < 0 {
			print("Error retries \(retries)")
		}
	}
	
	/// Считывает сигнал, используемый для остановки программы.
	private func readStopSignal(data: String) {
		if self.process == nil { return }
		self.process?.stopSignal = data
	}
	
	/// Считывает как долго ждать после остановки программы перед тем как убить процесс
	private func readStopTime(data: String) {
		if self.process == nil { return }
		self.process?.stopTime = Int(data)
		guard let stopTime = self.process?.stopTime else { return }
		if stopTime < 0 {
			print("Error stop time \(stopTime)")
		}
	}
	
	/// Считывает куда направлять выходной поток программы.
	private func readStdOut(data: String) {
		if self.process == nil { return }
		self.process?.stdOut = data
	}
	
	/// Считывает куда направлять выходной поток программы.
	private func readStdErr(data: String) {
		if self.process == nil { return }
		self.process?.stdErr = data
	}
	
	/// Считывает переменные окружения
	private func readEnvironmenst(data: String) {
		if self.process == nil { return }
		let words = data.split(){ $0 == " " }.map( { String($0) } )
		for word in words {
			let env = word.split(){ $0 == "=" }.map( { String($0) } )
			if env.count == 2 {
				if self.process?.environmenst == nil {
					self.process?.environmenst = [String: String]()
				}
				self.process?.environmenst?[env[0]] = env[1]
			}
		}
	}
	
	/// Считывает рабочую директорию запускаемой программы.
	private func readWorkingDir(data: String) {
		if self.process == nil { return }
		self.process?.workingDir = data
	}
	
	/// Считывает права доступа
	private func readUMask(data: String) {
		if self.process == nil { return }
		self.process?.umask = Int(data)
		guard let umask = self.process?.umask else { return }
		if umask < 0 {
			print("Error stop time \(umask)")
		}
	}
}

extension XMLDataManager: XMLParserDelegate {
	// Called when opening tag (`<elementName>`) is found
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		if self.process == nil {
			self.process = Process()
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
//		print("<\(elementName)>")
//		//print("attributes {\(attributeDict)}")
//		//var process = Process()
//		//process.command = elementName
//		//self.pracesses.append(process)
	}
	
	// Called when closing tag (`</elementName>`) is found
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

		if elementName == "process" {
			guard let process = self.process else { return }
			self.pracesses.append(process)
			self.process = nil
			//self.parser = nil
		}
	}
	
	// Called when a character sequence is found
	// This may be called multiple times in a single element
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if data.isEmpty { return }
		guard let fillData = self.fillData else { return }
		fillData(data)
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
		print("debugging \(parseError)")
		print("on:", parser.lineNumber, "at:", parser.columnNumber)
	}

}
