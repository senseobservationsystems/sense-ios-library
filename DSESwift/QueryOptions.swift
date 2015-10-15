//
//  queryOptions.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/10/15.
//
//

import Foundation

public struct QueryOptions{
    
    public enum Interval {
        case Minute
        case Hour
        case Day
        case Week
    }

    var startDate : NSDate?  // null by default, if not null, change from default
    var endDate: NSDate? // null by default, if not null, change from default
    var existsInCS: Bool? // null by default, if not null, change from default
    var requiresDeletionInCS: Bool? // null by default, if not null, change from default
    var limit: Int?
    var sortOrder: SortOrder
    var interval:Interval?
    
    public init(startDate: NSDate?, endDate: NSDate?, existsInCS: Bool?, requiresDeletionInCS: Bool?, limit: Int?, sortOrder: SortOrder, interval: Interval?) {
        self.startDate = startDate
        self.endDate = endDate
        self.existsInCS = existsInCS
        self.requiresDeletionInCS = requiresDeletionInCS
        self.limit = limit
        self.sortOrder = sortOrder
        self.interval = interval
    }
    
    public init(){
        self.init(startDate: nil, endDate: nil, existsInCS: nil, requiresDeletionInCS: nil, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
    }
}