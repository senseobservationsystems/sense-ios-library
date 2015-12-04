//
//  EventBus.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 04/12/15.
//
//

import Foundation

@objc public class EventBus: NSObject{
    
    static let sharedInstance = EventBus()
    var observers = Dictionary<String, NSObjectProtocol>()
    
    private override init() {
    }
    
    public func on(topic:String, listener:AnyObject, block: (NSNotification)->Void){
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(topic, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: block)
        let observerId = getObserverId(topic, listener: listener)
        if let old_observer = observers[observerId]{
            NSNotificationCenter.defaultCenter().removeObserver(old_observer)
        }
        
        observers[observerId] = observer
    }
    
    public func remove(topic:String, listener:AnyObject){
        if let observer = observers[self.getObserverId(topic, listener: listener)]{
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    public func getObserverId(topic: String, listener: AnyObject) -> String{
        return "\(topic):\(listener)"
    }
    
    public func post(topic:String, args: [NSObject: AnyObject]?){
        NSNotificationCenter.defaultCenter().postNotificationName(topic, object: nil, userInfo: args)
    }
}