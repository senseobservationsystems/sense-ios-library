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

    var startDate : NSDate? = nil  // null by default, if not null, change from default
    var endDate: NSDate? = nil// null by default, if not null, change from default
    var existsInCS: Bool? = nil// null by default, if not null, change from default
    var limit: Int? = nil
    var sortOrder: SortOrder = SortOrder.Asc
    var interval:Interval? = nil
    
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