//
//  File.swift
//  
//
//  Created by Михаил Фокин on 27.09.2021.
//

import Foundation

print("Welcom to Client Taskmaster!")

let argumets = CommandLine.arguments
if argumets.count != 3 {
	print("Usege:")
	print("./client host port")
	exit(0)
}
let client = Client(host: argumets[1], port: argumets[2])
client.run()
