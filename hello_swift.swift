#!/usr/bin/swift

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

print("\(Colour.blue)\(Colour.bold) Hello, \(Colour.red) Swift! \(Colour.reset)")
