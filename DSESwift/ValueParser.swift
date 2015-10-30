//
//  ValueParser.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 30/10/15.
//
//

import Foundation

protocol BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject
}

class IntValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInInt()
    }
}

class DoubleValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInDouble()
    }
}

class BoolValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInBool()
    }
}

class StringValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInString()
    }
}

class DictionaryValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInDictionary()
    }
}