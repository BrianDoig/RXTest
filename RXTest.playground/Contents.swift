//: Playground - noun: a place where people can play

import UIKit
import Foundation

func combine(withPaddingToMaxLength: Int) -> ([String]) -> String {
	return { (array: [String]) -> String in
		if (array.count > 1) {
			var result: String = array[0]
			
			let length = array.reduce(0, { (current, value) -> Int in
				return current + value.characters.count
			})
			let remainingLength = withPaddingToMaxLength - length
			let blankSpaceCount: Int = array.count - 1
			
			let baseLength = (remainingLength / blankSpaceCount) == 0 ? 1 : (remainingLength / blankSpaceCount)
			let baseMod = remainingLength % blankSpaceCount
			
			for i in 1...(blankSpaceCount) {
				var s = String(repeating: " ", count: baseLength)
				if i <= baseMod {
					s += " "
				}
				result += s + array[i]
			}
			return result
		} else {
			return array[0]
		}
	}
}



extension Array where Element == String  {
	func partition(withMaxLength maxLength: Int) -> ([[String]]) {
		//print (self)
		var count = 0
		var result: [[String]] = []
		var subResult: [String] = []
		var current = ArraySlice(self)
		var firstPass: Bool = true
		
		while let element = current.first {
			count += element.characters.count
			if (firstPass == true) {
				firstPass = false
			} else {
				count += 1
			}
			
			if count <= maxLength {
				subResult.append(element)
				if (current.count > 0) {
					
					current = current.dropFirst()
				} else {
					current = ArraySlice<String>([])
				}
			} else {
				result.append(subResult)
				firstPass = true
				count = 0
				subResult = []
				if current.count == 1 {
					result.append(Array(current))
				}
			}
		}
		
		return result
	}
	
}




extension String {
	func wrappedAndJustified(lineLength: Int) -> String {
		return self.components(separatedBy: " ")
			.partition(withMaxLength: lineLength)
			.map(combine(withPaddingToMaxLength: lineLength))
			.joined(separator: "\n")
	}
}

let tester = "The quick brown fox jumps over the lazy dog, hurray!"
let justified = tester.wrappedAndJustified(lineLength:15)

print(justified)

/*
The quick brown
fox jumps  over
the  lazy  dog,
hurray!
*/