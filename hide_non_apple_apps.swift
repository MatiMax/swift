#!/usr/bin/swift
/*
 Programme: hide_non_apple_apps.swift
   Purpose: A Swift shell script to hide all applications from Finder's view which are not originated from Apple and not included in the standard installation of macOS.
   Version: 2.0 (12-06-2020)
    Author: Mattias M. Schneider
 Copyright: IDC (I don't care)
 */
import Foundation

/*
 Some nice formatting while printing to the console. We use ANSI TTY escape sequences and colour codes here. `CustomStringConvertible` makes the handling of the struct much easier.
 */
enum Colour: String, CustomStringConvertible {
	var description: String {
		self.rawValue
	}

	case reset = "\u{1b}[0m"
	case colourReset = "\u{1b}[39;49m"
	case bold = "\u{1b}[1m"
	case red = "\u{1b}[37;41m"
	case green = "\u{1b}[37;42m"
	case blue = "\u{1b}[37;44m"
}

/*
 These immutable variables are used throughout the script.
 - appsPath: Location of the installed applications on macOS.
 - excluded: Files, directories, and applications to be ignored during the process.
 - outputFileName: File name to be used for piping everything going to the standard output.
 */
let appsPath = "/Applications"
let exluded = Set([
	".DS_Store",
	".localized",
	"Apps",
	"Utilities",
	"GarageBand.app",
	"Keynote.app",
	"Numbers.app",
	"Pages.app",
	"Safari.app",
	"Xcode.app",
	"iBooks Author.app",
	"iMovie.app",
	"Playgrounds.app"
])
let outputFileName = "output.out"

// … Yes, we need to run this script with the `sudo` command, otherwise the `chflags` command will not operate on most of the files due to access restrictions.
print("\(Colour.blue)\(Colour.bold) Remember to run this command as superuser. \(Colour.reset)")

// Read the contents of the Applications directory, create a `Set` of it and remove the `excluded` items.
let files = try! FileManager.default.contentsOfDirectory(atPath: appsPath)
var hiddenFiles = Set(files)
hiddenFiles.subtract(exluded)

// Some header information.
print("\(Colour.blue) \(hiddenFiles.count) files to be hidden: \(Colour.colourReset)")

// Create a file for piping all output from `stdin` into it.
let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFileName)
guard FileManager.default.createFile(atPath: fileURL.path, contents: nil) == true else {
    fatalError("Couldn't create file \"\(fileURL.path)\"")
}
let outputFile = try! FileHandle(forWritingTo: fileURL)

/*:
 Now, let's set up the variables needed for running a `Process` command. We need the path to the actual command and an array of `Strings` for the arguments. `SetFile` needs three of them, `-a` for modifying the attributes, `V` for *setting* the invisibility flag, and the full path to the file.

 Instead of using the deprecated `SetFile` command we make use of the `chflags` command which also supplies a means of hiding files and directories from Finder's view. The follwing code lines will therefore be rewritten:

 	let path = URL(fileURLWithPath: "/usr/bin/SetFile")
	var arguments = [/* 0 */ "-a", /* 1 */ "V", /* 2 */ ""]
	arguments[2] = "\(appsPath)/\(hiddenFile)" // Insert file name into the array positionally
 */
let path = URL(fileURLWithPath: "/usr/bin/chflags")
var arguments = [/* 0 */ "hidden", /* 1 */ ""]

for hiddenFile in hiddenFiles.sorted() {
	arguments[1] = "\(appsPath)/\(hiddenFile)" // Insert file name into the array positionally
	print("\tHiding \(Colour.bold)\(hiddenFile)\(Colour.reset) … ", terminator: "")

    // Create a new `Process`, fill in the needed attributes, run it and wait for its execution.
	let task = Process()
	task.executableURL = path
	task.arguments = arguments
	task.standardOutput = outputFile
	try! task.run()
	task.waitUntilExit()

	if task.terminationStatus == 0 {
		print("\(Colour.green) OK \(Colour.reset)")
	} else {
		print("\(Colour.red) NOK \(Colour.reset)")
	}
}

// Synchronise the file's state and close it.
try! outputFile.synchronize()
try! outputFile.close()

// If the file's size is not zero then we have some output and report it to the user for further inspection. Otherwise we can safely remove it.
if try! FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as! Int != 0 {
    print("\n\(Colour.red)\(Colour.bold) See \(fileURL.path) for report. \n Did you run the command as superuser? \(Colour.reset)")
} else {
    try! FileManager.default.removeItem(at: fileURL)
}
