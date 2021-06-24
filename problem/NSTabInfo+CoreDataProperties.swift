//
//  NSTabInfo+CoreDataProperties.swift
//  problem
//
//  Created by Yan Cheng Cheok on 24/06/2021.
//
//

import Foundation
import CoreData


extension NSTabInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NSTabInfo> {
        return NSFetchRequest<NSTabInfo>(entityName: "NSTabInfo")
    }

    @NSManaged public var name: String?
    @NSManaged public var order: Int64

}

extension NSTabInfo : Identifiable {

}
