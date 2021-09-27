//
//  InfoProcess.swift
//  taskmaster
//
//  Created by Михаил Фокин on 14.09.2021.
//

import Foundation

public struct InfoProcess: Codable {
	public var nameProcess: String?
	public var idProcess: Int?
	public var command: String?
	public var arguments: [String]?
	public var numberProcess: Int? = 1
	public var autoStart: Bool?
	public var autoRestart: AutoRestart?
	public var exitCodes: [Int32]?
	public var startTime: UInt64?
	public var stopTime: Double?
	public var startRetries: Int?
	public var stopSignal: Signals?
	public var stdOut: String?
	public var stdErr: String?
	public var environmenst: [String: String]?
	public var workingDir: String?
	public var umask: Int?
	
	public var countCopies: Int = 0
	public var status: Status?
	public var timeStartProcess: Date?
	public var timeStopProcess: Date?
	public var statusFinish: Finish?
	
	public init() {
		return
	}

}
