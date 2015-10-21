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
                case .Minute: return "Minute";
                case .Hour: return "Hour";
                case .Day: return "Day";
                case .Week: return "Week";
            }
        }
    }

    var startDate : NSDate?  // null by default, if not null, change from default
    var endDate: NSDate? // null by default, if not null, change from default
    var existsInCS: Bool? // null by default, if not null, change from default
    var limit: Int?
    var sortOrder: SortOrder
    var interval:Interval?
    
    public init(startDate: NSDate?, endDate: NSDate?, existsInCS: Bool?, limit: Int?, sortOrder: SortOrder, interval: Interval?) {
        self.startDate = startDate
        self.endDate = endDate
        self.existsInCS = existsInCS
        self.limit = limit
        self.sortOrder = sortOrder
        self.interval = interval
    }
    
    public init(){
        self.init(startDate: nil, endDate: nil, existsInCS: nil, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
    }
    
    public func toQueryParams() -> Dictionary<String, AnyObject>{
        var queryParams = Dictionary<String, AnyObject>()
        if (self.startDate != nil){ queryParams["start_date"] = JSONUtils.stringify(Int(self.startDate!.timeIntervalSince1970))}
        if (self.endDate != nil){ queryParams["end_date"] = JSONUtils.stringify(Int(self.endDate!.timeIntervalSince1970))}
        if (self.limit != nil){ queryParams["limit"] = JSONUtils.stringify(self.limit!)}
        if (self.interval != nil){ queryParams["interval"] = JSONUtils.stringify(self.interval!.description)}
        queryParams["sort"] = (self.sortOrder == SortOrder.Asc) ? JSONUtils.stringify("asc") : JSONUtils.stringify("desc")
        return queryParams
    }
}