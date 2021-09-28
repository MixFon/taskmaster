//
//  main.swift
//  taskmaster
//
//  Created by Михаил Фокин on 21.08.2021.
//

import Foundation
import DataProcess

print("Welcom to Taskmaster!")
func signalHandler(signal: Int32)->Void {
	print("Signal", signal)
	Taskmaster.signalHandler(signal: signal)
}

for sig in Signals.allCases {
	if sig == .SIGKILL || sig == .SIGSTOP || sig == .SIGABRT || sig == .SIGCHLD { continue }
	signal(sig.rawValue, signalHandler)
}

guard let server = ServerTM() else {
	print("Error start server.")
	exit(-1)
}

server.run()
