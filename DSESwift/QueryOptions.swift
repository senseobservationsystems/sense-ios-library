//
//  queryOptions.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/10/15.
//
//

import Foundation

public struct QueryOptions{

    var startDate : NSDate?  // null by default, if not null, change from default
    var endDate: NSDate? // null by default, if not null, change from default
    var existsInCS: Bool? // null by default, if not null, change from default
    var requiresDeletionInCS: Bool? // null by default, if not null, change from default
    var limit: Int?
    var sortOrder: SortOrder
    
    public init(startDate: NSDate?, endDate: NSDate?, existsInCS: Bool?, requiresDeletionInCS: Bool?, limit: Int?, sortOrder: SortOrder) {
        self.startDate = startDate
        self.endDate = endDate
        self.existsInCS = existsInCS
        self.requiresDeletionInCS = requiresDeletionInCS
        self.limit = limit
        self.sortOrder = sortOrder
    }
    
    public init(){
        self.init(startDate: nil, endDate: nil, existsInCS: nil, requiresDeletionInCS: nil, limit: nil, sortOrder: SortOrder.Asc)
    }
    
    public func toQueryParams() -> Dictionary<String, AnyObject>{
        var queryParams = Dictionary<String, AnyObject>()
        if (self.startDate != nil){ queryParams["start_date"] = JSONUtils.stringify(Int(self.startDate!.timeIntervalSince1970))}
        if (self.endDate != nil){ queryParams["end_date"] = JSONUtils.stringify(Int(self.endDate!.timeIntervalSince1970))}
        if (self.limit != nil){ queryParams["limit"] = JSONUtils.stringify(self.limit!)}
        //queryParams["sort"] = (self.sortOrder == SortOrder.Asc) ? JSONUtils.stringify("asc") : JSONUtils.stringify("desc")
        return queryParams
    }
}