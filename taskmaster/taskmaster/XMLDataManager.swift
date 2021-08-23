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
	
	func getProcesses(xmlFile: String) -> [Process] {
		//let nameFile = "server_config.xml"
		let manager = FileManager.default
		let currentDirURL = URL(fileURLWithPath: manager.currentDirectoryPath)
		let fileURL = currentDirURL.appendingPathComponent(xmlFile)
		//guard let data = try? Data(contentsOf: fileURL) else { exit(-1) }
		//self.parser = XMLParser(data: data)
		guard let parser = XMLParser(contentsOf: fileURL) else {
			fatalError("Invalid opened \(xmlFile)")
		}
		self.parser = XMLParser(contentsOf: fileURL)
		//super.init()
		parser.delegate = self
		parser.parse()
		return self.pracesses
	}
}

extension XMLDataManager: XMLParserDelegate {
	// Called when opening tag (`<elementName>`) is found
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		print("1) opening tag {\(elementName)}")
		print("attributes {\(attributeDict)}")
		var process = Process()
		process.command = elementName
		self.pracesses.append(process)
	}
	
	// Called when closing tag (`</elementName>`) is found
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		print("2) closing tag {\(elementName)}")
		print("namespaceURI {\(namespaceURI ?? "" )}")
	}
	
	// Called when a character sequence is found
	// This may be called multiple times in a single element
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		if !data.isEmpty {
			print("3) character sequence is found [\(data)]")
		}
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
