//
//  ValueParser.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 30/10/15.
//
//

import Foundation

internal protocol BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject
}

internal class IntValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInInt()
    }
}

internal class DoubleValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInDouble()
    }
}

internal class BoolValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInBool()
    }
}

internal class StringValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInString()
    }
}

internal class DictionaryValueParser: BaseValueParser {
    func getValueInOriginalFormat(dataPoint: DataPoint) -> AnyObject {
        return dataPoint.getValueInDictionary()
    }
}