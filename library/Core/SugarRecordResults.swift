//
//  SugarRecordResults.swift
//  project
//
//  Created by Pedro Piñera Buendía on 25/12/14.
//  Copyright (c) 2014 SugarRecord. All rights reserved.
//

import Foundation
import CoreData
import Realm

public class SugarRecordResults<T>: SequenceType
{
    //MARK: - Attributes
    
    /// Array with the results of CoreData
    public var coredataResults: [NSManagedObject]?
    
    /// Array with the results of Realm
    private var realmResults: RLMResults?
    
    /// Finder element with information about predicates, sortdescriptors,...
    private var finder: SugarRecordFinder<T>
    
    /// Database Engine: CoreData, Realm, ...
    internal var engine: SugarRecordEngine {
        if (coredataResults != nil) {
            return SugarRecordEngine.SugarRecordEngineCoreData
        }
        else {
            return SugarRecordEngine.SugarRecordEngineRealm
        }
    }

    //MARK: - Constructors
    
    /**
    Initializes SugarRecordResults using CoreDataResults
    
    - parameter coredataResults: Array with NSManagedObjects
    - parameter finder:          Finder used to query those elements
    
    - returns: Initialized SugarRecordResults
    */
    internal init(coredataResults: [NSManagedObject], finder: SugarRecordFinder<T>)
    {
        self.coredataResults = coredataResults
        self.finder = finder
    }
    
    /**
    Initializes SugarRecordResults using Realm results
    
    - parameter realmResults: RLMResults with the Realm results
    - parameter finder:       Finder used to query those elements
    
    - returns: Initialized SugarRecordResults
    */
    internal init(realmResults: RLMResults, finder: SugarRecordFinder<T>) {
        self.realmResults = realmResults
        self.finder = finder
    }
    
    
    //MARK: - Public methods
    
    /// Returns the count of elements
    public var count:Int {
        get {
            if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
                return coredataResults!.count
            }
            else {
                let (firstIndex, lastIndex) = indexes()
                if (lastIndex == 0 && firstIndex == 0) { return Int(realmResults!.count) }
                return lastIndex - firstIndex + 1
            }
        }
    }
    
    /**
    Returns the object at a given index
    
    - parameter index: Index of the object to be returned
    
    - returns: Object at index position
    */
    func objectAtIndex(index: UInt) -> T!
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            return coredataResults![Int(index)] as! T
        }
        else {
            let (firstIndex, _) = indexes()
            return realmResults!.objectAtIndex(UInt(firstIndex) + index) as? T
        }
    }
    
    /**
    Returns the first object of the results
    
    - returns: Object at position 0
    */
    func firstObject() -> T!
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            return coredataResults!.first! as! T
        }
        else {
            let (firstIndex, _) = indexes()
            return realmResults!.objectAtIndex(UInt(firstIndex)) as! T
        }
    }
    
    /**
    Returns the last object of the list
    
    - returns: Object at last position
    */
    func lastObject() -> T!
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            return coredataResults!.last! as! T
        }
        else {
            let (_, lastIndex) = indexes()
            return realmResults!.objectAtIndex(UInt(lastIndex)) as! T
        }
    }
    
    /**
    Returns the index of a given object
    
    - parameter object: Object whose index'll be returned
    
    - returns: index of the given object
    */
    func indexOfObject(object: T) -> Int
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            
            if let i = coredataResults?.indexOf(object as! NSManagedObject) {
                return i
            }
            else {
                return NSNotFound
            }
        }
        else {
            let (firstIndex, _) = indexes()
            return Int(realmResults!.indexOfObject(object as! RLMObject)) - firstIndex
        }
    }
    
    /**
    Index of a given object passed a predicate
    
    - parameter predicate: NSPredicate to filter results
    
    - returns: Int with the index on the filtered results
    */
    func indexOfObjectWithPredicate(predicate: NSPredicate!) -> Int
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            let filteredArray: SugarRecordResults<T>! = objectsWithPredicate(predicate)
            let first: T! = filteredArray.firstObject()
            if first != nil {
                return indexOfObject(first)
            }
            else {
                return NSNotFound
            }
        }
        else {
            let (firstIndex, _) = indexes()
            return Int(realmResults!.indexOfObjectWithPredicate(predicate)) - firstIndex
        }
    }
    
    
    /**
    Returns objects filtered with the given predicate
    
    - parameter predicate: NSPredicate for filtering
    
    - returns: Filtered SugarRecordResults
    */
    func objectsWithPredicate(predicate: NSPredicate!) -> SugarRecordResults<T>!
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            let array: NSArray = NSArray(array: coredataResults!)
            return SugarRecordResults(coredataResults: array.filteredArrayUsingPredicate(predicate) as! [NSManagedObject], finder: finder)
        }
        else {
            return SugarRecordResults(realmResults: realmResults!.objectsWithPredicate(predicate), finder: SugarRecordFinder<T>())

        }
    }
    
    /**
    Returns objects sortered with the given sort descriptor
    
    - parameter property:  Sort descriptor key as String
    - parameter ascending: Sort descriptor ascending value as Bool
    
    - returns: Sortered SugarRecordResults
    */
    func sortedResultsUsingProperty(property: String!, ascending: Bool) -> SugarRecordResults<T>!
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            let array: NSArray = NSArray(array: coredataResults!)
            return SugarRecordResults(coredataResults: (array.sortedArrayUsingDescriptors([NSSortDescriptor(key: property, ascending: ascending)]) as! [NSManagedObject]), finder: finder)
        }
        else {
            return SugarRecordResults(realmResults: realmResults!.sortedResultsUsingProperty(property, ascending: ascending), finder: SugarRecordFinder<T>())
        }
    }
    
    /**
    Returns the REALM database engine collection.
    - CoreData: Array with NSManagedObjects
    - Realm: RLMResults object
    
    - returns: original collection that depends on the database engine
    */
    func realCollection() -> AnyObject
    {
        if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
            return coredataResults!
        }
        else {
            return realmResults!
        }
    }
    
    /**
    *  Access to the element at a given index
    */
    subscript (index: Int) -> T! {
        get {
            if (engine == SugarRecordEngine.SugarRecordEngineCoreData) {
                return coredataResults![index] as! T
            }
            else {
                let (firstIndex, _) = indexes()
                return realmResults![UInt(index+firstIndex)] as! T
            }
        }
    }
    
    
    //MARK: - Helpers
    
    /**
    Returns the first and the last element taking into account the SugarRecordFinder options
    
    - returns: Tuple with the first and last index
    */
    func indexes() -> (Int, Int)
    {
        var firstIndex: Int = 0
        var lastIndex: Int = Int(realmResults!.count) - 1
        
        switch(finder.elements) {
        case .first:
            firstIndex = 0
            lastIndex = 0
        case .last:
            lastIndex = Int(realmResults!.count) - 1
            firstIndex = Int(realmResults!.count) - 1
        case .firsts(let number):
            firstIndex = 0
            lastIndex = firstIndex + number - 1
            if (lastIndex > Int(realmResults!.count) - 1) { lastIndex = Int(realmResults!.count) - 1 }
        case .lasts(let number):
            lastIndex = Int(realmResults!.count) - 1
            firstIndex = firstIndex - (number - 1)
            if (firstIndex < 0) { firstIndex = 0 }
        default:
            break
        }
        return (firstIndex, lastIndex)
    }
    
    
    //MARK: SequenceType Protocol
    
    public func generate() -> SugarRecordResultsGenerator<T>
    {
        return SugarRecordResultsGenerator(results: self)
    }
}


//MARK: Generator

public class SugarRecordResultsGenerator<T>: GeneratorType {
    private var results: SugarRecordResults<T>
    private var nextIndex: Int
    
    init(results: SugarRecordResults<T>) {
        self.results = results
        nextIndex = 0
    }
    
    public func next() -> T? {
        if (nextIndex < 0) {
            return nil
        }
        return self.results[nextIndex--]
    }
}