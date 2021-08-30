//
//  main.swift
//  taskmaster
//
//  Created by Михаил Фокин on 21.08.2021.
//

import Foundation

print("Welcom to Taskmaster!")
while let str = readLine() {
	print(str)
	let task = Taskmaster()
	task.run()
}


