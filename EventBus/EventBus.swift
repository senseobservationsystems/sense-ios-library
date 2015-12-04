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
    
    private override init() {}
    
    
    /**
    * Register an event handler for an event identified by the combination of the topic and the listner class. It removes the previously registerred handler if the same combination already exists.
    * @param topic: String for topic.
    * @param listener: AnyObject for the listener. eg) self
    * @param block: Closure that should be called on the event.
    **/
    public func on(topic:String, listener:AnyObject, block: (NSNotification)->Void){
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(topic, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: block)
        let observerId = getObserverId(topic, listener: listener)
        if let old_observer = observers[observerId]{
            NSNotificationCenter.defaultCenter().removeObserver(old_observer)
        }
        observers[observerId] = observer
    }
    
    /**
     * Remove the event identified by the combination of the topic and the listner class.
     * @param topic: String for topic.
     * @param listener: AnyObject for the listener. eg) self
     **/
    public func remove(topic:String, listener:AnyObject){
        if let observer = observers[self.getObserverId(topic, listener: listener)]{
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
    /**
     * Triggers the event.
     * @param topic: String for topic.
     * @param args: Dictionary for passing some arguments.
     **/
    public func post(topic:String, args: [NSObject: AnyObject]?){
        NSNotificationCenter.defaultCenter().postNotificationName(topic, object: nil, userInfo: args)
    }
    
    //MARK: heleper class
    
    private func getObserverId(topic: String, listener: AnyObject) -> String{
        return "\(topic):\(listener)"
    }
}