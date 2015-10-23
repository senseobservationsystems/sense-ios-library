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
        
        var description : String {
            switch self {
                // Use Internationalization, as appropriate.
                case .Minute: return "minute";
                case .Hour: return "hour";
                case .Day: return "day";
                case .Week: return "week";
            }
        }
    }

    var startDate : NSDate?  // null by default, if not null, change from default
    var endDate: NSDate? // null by default, if not null, change from default
    var existsInCS: Bool? // null by default, if not null, change from default
    var limit: Int?
    var sortOrder: SortOrder
    var interval:Interval?
    
    public init(startDate: NSDate?, endDate: NSDate? = nil, existsInCS: Bool? = nil, limit: Int? = nil, sortOrder: SortOrder? = SortOrder.Asc, interval: Interval? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.existsInCS = existsInCS
        self.limit = limit
        self.sortOrder = sortOrder!
        self.interval = interval
    }
    
    public init(){
        self.init(startDate: nil, endDate: nil, existsInCS: nil, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
    }
    
    public func toQueryParams() throws -> Dictionary<String, AnyObject>{
        var queryParams = Dictionary<String, AnyObject>()
        if (self.startDate != nil){ queryParams["start_time"] = Int(self.startDate!.timeIntervalSince1970*1000)}
        if (self.endDate != nil){ queryParams["end_time"] = Int(self.endDate!.timeIntervalSince1970*1000)}
        if (self.limit != nil){ queryParams["limit"] = self.limit!}
        if (self.interval != nil){ queryParams["interval"] = self.interval!.description}
        queryParams["sort"] = (self.sortOrder == SortOrder.Asc) ? "asc" : "desc"
        return queryParams
    }
}