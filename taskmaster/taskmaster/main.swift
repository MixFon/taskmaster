//
//  main.swift
//  taskmaster
//
//  Created by Михаил Фокин on 21.08.2021.
//

import Foundation

print("Welcom to Taskmaster!")

func signalHandler(signal: Int32)->Void {
	Taskmaster.signalHandler(signal: signal)
}

let task = Taskmaster()
for sig in DataProcess.Signals.allCases {
	print(sig)
	signal(sig.rawValue, signalHandler)
}
task.runTaskmaster()



