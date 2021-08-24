//
//  Process.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

struct Process {
	var command: String?
	var arguments: [String]?
	var numberProcess: Int?
	var autoStart: Bool?
	var autoRestart: String?
	var exitCodes: [Int]?
	var startTime: Int?
	var startRetries: Int?
	var stopSignal: String?
	var stopTime: Int?
	var stdOut: String?
	var stdErr: String?
	var environmenst: [String: String]?
	var workingDir: String?
	var umask: Int?
}
