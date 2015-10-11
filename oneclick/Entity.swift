//
//  Entity.swift
//  oneclick
//
//  Created by twodayslate on 8/20/15.
//  Copyright (c) 2015 twodayslate. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Entity)
class Entity : NSManagedObject {
    
    @NSManaged var date: NSDate
    @NSManaged var score: NSNumber
    @NSManaged var background: NSData
    
}
