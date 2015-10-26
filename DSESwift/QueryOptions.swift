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

    var startTime : NSDate? = nil // null by default, if not null, change from default
    var endTime: NSDate? = nil// null by default, if not null, change from default
    var existsInRemote: Bool? = nil // null by default, if not null, change from default
    var limit: Int? = nil
    var sortOrder: SortOrder = SortOrder.Asc
    var interval:Interval? = nil
    
    
    public func toQueryParams() -> Dictionary<String, AnyObject>{
        var queryParams = Dictionary<String, AnyObject>()
        if (self.startTime != nil){ queryParams["start_time"] = JSONUtils.stringify(Int(self.startTime!.timeIntervalSince1970))}
        if (self.endTime != nil){ queryParams["end_time"] = JSONUtils.stringify(Int(self.endTime!.timeIntervalSince1970))}
        if (self.limit != nil){ queryParams["limit"] = JSONUtils.stringify(self.limit!)}
        if (self.interval != nil){ queryParams["interval"] = JSONUtils.stringify(self.interval!.description)}
        queryParams["sort"] = (self.sortOrder == SortOrder.Asc) ? JSONUtils.stringify("asc") : JSONUtils.stringify("desc")
        return queryParams
    }
}