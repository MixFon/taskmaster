//
//  main.swift
//  taskmaster
//
//  Created by Михаил Фокин on 21.08.2021.
//

import Foundation

print("Welcom to Taskmaster!")


//func readFile(fileName: String) throws -> String {
//		let manager = FileManager.default
//		let currentDirURL = URL(fileURLWithPath: manager.currentDirectoryPath)
//		let fileURL = currentDirURL.appendingPathComponent(fileName)
//		return try String(contentsOf: fileURL)
//}
//
//let str = try? readFile(fileName: "server_config.xml")
//if str != nil {
//	print(str!)
//} else {
//	print("Xui")
//}

//let parser = try? XMLDocument(xmlString: str!, options: .documentTidyXML)
//
//let manager = FileManager.default
//let currentDirURL = URL(fileURLWithPath: manager.currentDirectoryPath)
//let fileURL = currentDirURL.appendingPathComponent("server_config.xml")
//let xmlDoc = try? XMLDocument(contentsOf: fileURL, options: .documentTidyXML)

//let parser = XMLParser(contentsOf: fileURL)
//print(xmlDoc?.rootElement()?.xmlString(options: .documentTidyXML) ?? "Xui2")
//let parser = Process(contentsOf: fileURL)
//let content = try String(contentsOf: fileURL)
//let parser = Process(data: Data(content.utf8))
//if parser.parse() {
//	print(parser.attributeKeys)
//} else {
//	print(parser.parserError ?? "Xui?")
//}
//
//guard let data = try? Data(contentsOf: fileURL) else { exit(-1) }
//print(data.last!)
//let parser = Process(data: data)
//parser.delegate = self as? XMLParserDelegate
//parser.parse()
//let process = Process()
let manager = XMLDataManager()
let processes = manager.getProcesses(xmlFile: "server_config.xml")
for process in processes {
	print(process.command!)
}
