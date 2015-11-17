//
//  DSEAsyncCallback.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/11/15.
//
//

import Foundation

protocol DSEAsyncCallback{

    /**
     * Callback method called on success
     **/
    func onSuccess()
    
    /**
     * Callback method called on failure
     * @param throwable If available a throwable is send with with failure response.
     **/
    func onFailure() throws
}