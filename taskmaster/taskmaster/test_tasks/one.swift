import Foundation

print("Welcom to Taskmaster!")
func signalHandler(signal: Int32)->Void {
	print("Signal", signal)
	//Taskmaster.signalHandler(signal: signal)
}
signal(2, signalHandler)
while(true)
{
    print("one")
    sleep(2)
}
/*
let task = Taskmaster()
for sig in DataProcess.Signals.allCases {
	if sig == .SIGKILL || sig == .SIGSTOP || sig == .SIGABRT || sig == .SIGCHLD { continue }
	//print(sig)
	signal(sig.rawValue, signalHandler)
}
print("Hello")
task.runTaskmaster()
*/

