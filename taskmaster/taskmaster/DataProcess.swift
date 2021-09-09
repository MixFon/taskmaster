//
//  Process.swift
//  taskmaster
//
//  Created by Михаил Фокин on 23.08.2021.
//

import Foundation

struct DataProcess {
	var nameProcess: String?
	var command: String?
	var arguments: [String]?
	var numberProcess: Int? = 1 //????? Что будет при перезапуске 
	var autoStart: Bool?
	var autoRestart: AutoRestart?
	var exitCodes: [Int32]?
	var startTime: Int?
	var startRetries: Int?
	var stopSignal: Signals?
	var stopTime: Int?
	var stdOut: String?
	var stdErr: String?
	var environmenst: [String: String]?
	var workingDir: String?
	var umask: Int?
	
	var process: Process?
	var status: Status?
	var timeStartProcess: Date?
	var timeStopProcess: Date?
	var statusFinish: Finish?
	
	enum Status: String {
		case noStart
		case running
		case finish
		case errorStart
	}
	
	enum AutoRestart: String {
		case always
		case never
		case unexpected
	}
	
	enum Finish: String {
		case success
		case fail
	}
	
	enum Signals: Int32, CaseIterable {
		case SIGABRT = 6	// Завершение с дампом памяти | Сигнал посылаемый функцией abort() | Управление
		case SIGALRM = 14	// Завершение | Сигнал истечения времени, заданного alarm() | Уведомление
		case SIGBUS	= 10	// Завершение с дампом памяти	Неправильное обращение в физическую память | Исключение
		case SIGCHLD = 18	// Игнорируется | Дочерний процесс завершен или остановлен | Уведомление
		case SIGCONT = 25	// Продолжить выполнение | Продолжить выполнение процесса | Управление
		case SIGFPE = 8		// Завершение с дампом памяти | Ошибочная арифметическая операция | Исключение
		case SIGHUP = 1		// Завершение | Закрытие терминала | Уведомление
		case SIGILL = 4		// Завершение с дампом памяти	Недопустимая инструкция процессора | Исключение
		case SIGINT = 2		// Завершение | Сигнал прерывания (Ctrl-C) с терминала | Управление
		case SIGKILL = 9	// Завершение | Безусловное завершение | Управление
		case SIGPIPE = 13	// Завершение | Запись в разорванное соединение (пайп, сокет) | Уведомление
		case SIGQUIT = 3	// Завершение с дампом памяти | Сигнал «Quit» с терминала (Ctrl-\) | Управление
		case SIGSEGV = 11	// Завершение с дампом памяти | Нарушение при обращении в память | Исключение
		case SIGSTOP = 23	// Остановка процесса	Остановка выполнения процесса | Управление
		case SIGTERM = 15	// Завершение | Сигнал завершения (сигнал по умолчанию для утилиты kill) | Управление
		case SIGTSTP = 20	// Остановка процесса | Сигнал остановки с терминала (Ctrl-Z).	Управление
		case SIGTTIN = 26	// Остановка процесса | Попытка чтения с терминала фоновым процессом | Управление
		case SIGTTOU = 27	// Остановка процесса | Попытка записи на терминал фоновым процессом | Управление
		case SIGUSR1 = 16	// Завершение | Пользовательский сигнал № 1	Пользовательский
		case SIGUSR2 = 17	// Завершение | Пользовательский сигнал № 2	Пользовательский
		case SIGPOLL = 22	// Завершение | Событие, отслеживаемое poll() | Уведомление
		case SIGPROF = 29	// Завершение | Истечение таймера профилирования | Отладка
		case SIGSYS = 12	// Завершение с дампом памяти | Неправильный системный вызов | Исключение
		case SIGTRAP = 5	// Завершение с дампом памятиvЛовушка трассировки или брейкпоинт | Отладка
		case SIGURG = 21	// Игнорируется	На сокете получены срочные данные | Уведомление
		case SIGVTALRM = 28	// Завершение | Истечение «виртуального таймера» | Уведомление
		case SIGXCPU = 30	// Завершение с дампом памяти | Процесс превысил лимит проц-го времени | Исключение
		case SIGXFSZ = 31	// Завершение с дампом памяти | Процесс превысил допустимый размер файла	Исключение
		
		//static let allSignals: [Signals] = [SIGABRT, SIGALRM, SIGBUS]
	}
}

extension DataProcess: Hashable {
	static func == (lhs: DataProcess, rhs: DataProcess) -> Bool {
		return lhs.nameProcess == rhs.nameProcess
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.nameProcess)
	}
}
