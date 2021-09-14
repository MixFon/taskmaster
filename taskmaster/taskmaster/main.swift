//
//  main.swift
//  taskmaster
//
//  Created by Михаил Фокин on 21.08.2021.
//

import Foundation

print("Welcom to Taskmaster!")
//let server = ServerTM()
//server.run()
func signalHandler(signal: Int32)->Void {
	print("Signal", signal)
	Taskmaster.signalHandler(signal: signal)
}

let task = Taskmaster()
for sig in DataProcess.Signals.allCases {
	if sig == .SIGKILL || sig == .SIGSTOP || sig == .SIGABRT || sig == .SIGCHLD { continue }
	//print(sig)
	signal(sig.rawValue, signalHandler)
}
print("Hello")
task.runTaskmaster()
