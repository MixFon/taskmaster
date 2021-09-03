//
//  Logs.swift
//  taskmaster
//
//  Created by Михаил Фокин on 29.08.2021.
//

import Foundation

class Logs {
	
	static var fileLogs: String = "taskmaster.log"
	
	static func writeLogsStdOut(massage: String) {
		print(massage)
	}
	
	/// Запись в файл логов. По умолчанию это файл "taskmaster.log"
	static func writeLogsToFileLogs(_ massage: String) {
		let currentDate = DateFormatter.getCurrentDate()
		let messageData = "\(currentDate) \(massage)\n";
		let manager = FileManager.default
		let currntDirURL = URL(fileURLWithPath: manager.currentDirectoryPath)
		let fileURL = currntDirURL.appendingPathComponent(self.fileLogs)
		do {
			if FileManager.default.fileExists(atPath: fileURL.path) {
				if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
					fileHandle.seekToEndOfFile()
					if let data = messageData.data(using: .utf8) {
						fileHandle.write(data)
					}
					fileHandle.closeFile()
				}
			} else {
				try messageData.write(to: fileURL, atomically: true, encoding: .utf8)
			}
		} catch {
			fputs("Error writing to the \(self.fileLogs) file.\n", stderr)
		}
	}
}

extension DateFormatter {
	static func getCurrentDate() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "[dd/MM/yyyy HH:mm:ss]"
		return dateFormatter.string(from: Date())
	}
}
