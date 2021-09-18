//
//  Process.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

struct DataProcess {
	var process: Process?
	var info: InfoProcess
}

extension DataProcess: Hashable {
	static func == (lhs: DataProcess, rhs: DataProcess) -> Bool {
		return lhs.info.nameProcess == rhs.info.nameProcess
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.info.nameProcess)
	}
}

extension String: Error { }
