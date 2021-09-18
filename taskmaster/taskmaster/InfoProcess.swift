//
//  InfoProcess.swift
//  taskmaster
//
//  Created by Михаил Фокин on 14.09.2021.
//

import Foundation

struct InfoProcess: Encodable {
	var nameProcess: String?
	var command: String?
	var arguments: [String]?
	var numberProcess: Int? = 1
	var autoStart: Bool?
	var autoRestart: AutoRestart?
	var exitCodes: [Int32]?
	var startTime: UInt64?
	var stopTime: Double?
	var startRetries: Int?
	var stopSignal: Signals?
	var stdOut: String?
	var stdErr: String?
	var environmenst: [String: String]?
	var workingDir: String?
	var umask: Int?
	
	var countCopies: Int = 0
	var status: Status?
	var timeStartProcess: Date?
	var timeStopProcess: Date?
	var statusFinish: Finish?
	
	enum Status: String, Encodable {
		case no_start
		case running
		case finish
		case stoping
		case fatal
	}
	
	enum AutoRestart: String, Encodable {
		case always
		case never
		case unexpected
	}
	
	enum Finish: String, Encodable {
		case success
		case fail
	}
	
	enum Signals: Int32, CaseIterable, Encodable {
		case SIGHUP = 1		// terminate process    terminal line hangup
		case SIGINT = 2		// terminate process    interrupt program
		case SIGQUIT = 3	// create core image    quit program
		case SIGILL = 4		// create core image    illegal instruction
		case SIGTRAP = 5    // create core image    trace trap
		case SIGABRT = 6    // create core image    abort program (formerly SIGIOT)
		case SIGEMT = 7     // create core image    emulate instruction executed
		case SIGFPE = 8     // create core image    floating-point exception
		case SIGKILL = 9    // terminate process    kill program
		case SIGBUS = 10    // create core image    bus error
		case SIGSEGV = 11   // create core image    segmentation violation
		case SIGSYS = 12    // create core image    non-existent system call invoked
		case SIGPIPE = 13	// terminate process    write on a pipe with no reader
		case SIGALRM = 14	// terminate process    real-time timer expired
		case SIGTERM = 15	// terminate process    software termination signal
		case SIGURG = 16    // discard signal       urgent condition present on socket
		case SIGSTOP = 17	// stop process         stop (cannot be caught or ignored)
		case SIGTSTP = 18   // stop process         stop signal generated from keyboard
		case SIGCONT = 19   // discard signal       continue after stop
		case SIGCHLD = 20   // discard signal       child status has changed
		case SIGTTIN = 21   // stop process         background read attempted from control terminal
		case SIGTTOU = 22   // stop process         background write attempted to control terminal
		case SIGIO = 23     // discard signal       I/O is possible on a descriptor (see fcntl(2))
		case SIGXCPU = 24	// terminate process    cpu time limit exceeded (see setrlimit(2))
		case SIGXFSZ = 25   // terminate process    file size limit exceeded (see setrlimit(2))
		case SIGVTALRM = 26 // terminate process    virtual time alarm (see setitimer(2))
		case SIGPROF = 27   // terminate process    profiling timer alarm (see setitimer(2))
		case SIGWINCH = 28  // discard signal       Window size change
		case SIGINFO = 29   // discard signal       status request from keyboard
		case SIGUSR1 = 30   // terminate process    User defined signal 1
		case SIGUSR2 = 31   // terminate process    User defined signal 2
		
		init?(signal: String) {
			switch signal {
			case "SIGHUP": self = .SIGHUP
			case "SIGINT": self = .SIGINT
			case "SIGQUIT": self = .SIGQUIT
			case "SIGILL": self = .SIGILL
			case "SIGTRAP": self = .SIGTRAP
			case "SIGABRT": self = .SIGABRT
			case "SIGEMT": self = .SIGEMT
			case "SIGFPE": self = .SIGFPE
			case "SIGKILL": self = .SIGKILL
			case "SIGBUS": self = .SIGBUS
			case "SIGSEGV": self = .SIGSEGV
			case "SIGSYS": self = .SIGSYS
			case "SIGPIPE": self = .SIGPIPE
			case "SIGALRM": self = .SIGALRM
			case "SIGTERM": self = .SIGTERM
			case "SIGURG": self = .SIGURG
			case "SIGSTOP": self = .SIGSTOP
			case "SIGTSTP": self = .SIGTSTP
			case "SIGCONT": self = .SIGCONT
			case "SIGCHLD": self = .SIGCHLD
			case "SIGTTIN": self = .SIGTTIN
			case "SIGTTOU": self = .SIGTTOU
			case "SIGIO": self = .SIGIO
			case "SIGXCPU": self = .SIGXCPU
			case "SIGXFSZ": self = .SIGXFSZ
			case "SIGVTALRM": self = .SIGVTALRM
			case "SIGPROF": self = .SIGPROF
			case "SIGWINCH": self = .SIGWINCH
			case "SIGINFO": self = .SIGINFO
			case "SIGUSR1": self = .SIGUSR1
			case "SIGUSR2": self = .SIGUSR2
			default: return nil
			}
		}
	}
}
