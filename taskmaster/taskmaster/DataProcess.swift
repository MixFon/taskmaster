//
//  Process.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

struct DataProcess {
	var nameProcess: String?
	var command: String?
	var arguments: [String]?
	var numberProcess: Int? = 1 //????? Что будет при перезапуске 
	var autoStart: Bool?
	var autoRestart: AutoRestart?
	var exitCodes: [Int32]?
	var startTime: Int?
	var startRetries: Int?
	var stopSignal: String?
	var stopTime: Int?
	var stdOut: String?
	var stdErr: String?
	var environmenst: [String: String]?
	var workingDir: String?
	var umask: Int?
	
	var process: Process?
	var status: Status?
	var timeStartProcess: Date?
	var timeStopProcess: Date?
	var statusFinish: Finish?
	
	enum Status: String {
		case noStart
		case running
		case finish
		case errorStart
	}
	
	enum AutoRestart: String {
		case always
		case never
		case unexpected
	}
	
	enum Finish: String {
		case success
		case fail
	}
}

extension DataProcess: Hashable {
	static func == (lhs: DataProcess, rhs: DataProcess) -> Bool {
		return lhs.nameProcess == rhs.nameProcess
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.nameProcess)
	}
}
