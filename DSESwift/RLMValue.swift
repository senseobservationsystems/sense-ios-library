//
//  RLMIntValue.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 03/10/15.
//
//

import Foundation
import RealmSwift

class RLMIntValue : BaseValue{
    dynamic var value = Int()
}

class RLMDoubleValue : BaseValue{
    dynamic var value = Double()
}

class RLMBoolValue : BaseValue{
    dynamic var value = Bool()
}

class RLMStringValue : BaseValue{
    dynamic var value = String()
}

/*
class RLMDictionaryValue : BaseValue{
    dynamic var value = String()
}
*/