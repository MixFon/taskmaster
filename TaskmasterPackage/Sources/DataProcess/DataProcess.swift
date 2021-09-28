//
//  Process.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

public struct DataProcess {
	public var process: Process?
	public var info: InfoProcess
	
	public init(process: Process?, info: InfoProcess) {
		self.process = process
		self.info = info
	}
}

extension DataProcess: Hashable {
	public static func == (lhs: DataProcess, rhs: DataProcess) -> Bool {
		return lhs.info.nameProcess == rhs.info.nameProcess
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.info.nameProcess)
	}
}

extension String: Error { }
