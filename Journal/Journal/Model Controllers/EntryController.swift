//
//  EntryController.swift
//  Journal
//
//  Created by Alex Shillingford on 8/22/19.
//  Copyright © 2019 Alex Shillingford. All rights reserved.
//

import Foundation
import CoreData

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

class EntryController {
    //MARK: - Properties
    //    var entries: [Entry] {
    //        let entries = loadFromPersistentStore()
    //        return entries
    //    }
    
    let baseURL = URL(string: "https://journal-coredata-6f50e.firebaseio.com/")!
    
    //    let df = DateFormatter()
    //MARK: - Persistence
    func saveToPersistentStore() {
        let moc = CoreDataStack.shared.mainContext
        
        do {
            try moc.save()
        } catch {
            NSLog("Error saving moc: \(error)")
            moc.reset()
        }
    }
    
    //    func loadFromPersistentStore() -> [Entry] {
    //        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
    //        let moc = CoreDataStack.shared.mainContext
    //
    //        do {
    //            let entries = try moc.fetch(fetchRequest)
    //            return entries
    //        } catch {
    //            NSLog("Error loading entries: \(error)")
    //            return []
    //        }
    //    }
    
    //MARK: - CRUD Methods
    func createEntry(title: String, bodyText: String, mood: Moods) {
        let entry = Entry(title: title, bodyText: bodyText, mood: mood.rawValue)
        saveToPersistentStore()
        put(entry: entry)
    }
    
    func updateEntry(entry: Entry, title: String, bodyText: String, timestamp: Date, mood: Moods) {
        entry.title = title
        entry.bodyText = bodyText
        entry.timestamp = timestamp
        entry.mood = mood.rawValue
        
        saveToPersistentStore()
        put(entry: entry)
    }
    
    func deleteEntry(entry: Entry) {
        let moc = CoreDataStack.shared.mainContext
        moc.delete(entry)
        saveToPersistentStore()
        deleteEntryFromServer(entry: entry)
    }
    
}

extension EntryController {
    
    func put(entry: Entry, completion: @escaping ()-> Void = {}) {
        let identifier = entry.identifier ?? UUID()
        
        let requestURL = (baseURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json"))
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.put.rawValue
        
        do {
            let entryData = try JSONEncoder().encode(entry.entryRepresentation)
            request.httpBody = entryData
        } catch {
            NSLog("Error encoding entry data in 'put' method in EntryController: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("Error in the URLSession.shared.dataTask in put method: \(error)")
            }
            
            completion()
            }.resume()
    }
    
    func deleteEntryFromServer(entry: Entry, completion: @escaping ()-> Void = { }) {
        guard let identifier = entry.identifier else {
            completion()
            return
        }
        
        var requestURL = baseURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.delete.rawValue
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("Error deleting entry in 'deleteEntryFromServer' method in EntryController: \(error)")
            }
            
            completion()
            }.resume()
    }
    
}
