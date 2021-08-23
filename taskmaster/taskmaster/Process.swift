//
//  Process.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

struct Process {
	var command: String?
	var numberProcess: Int?
	var autoStart: Bool?
	var restartProgramm: String?
	var exitCodes: [Int]?
	var startTime: Timer?
	var startRetries: Int?
	var stopSignal: String?
	var stopTime: Timer?
	var stdOut: String?
	var strErr: String?
	var environmenst: [String]?
	var workingDir: String?
	var umask: Int?
}
