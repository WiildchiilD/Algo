//
//  Metadata.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 03/10/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation

final class MetadataManager {
    
    var territories = [MetadataTerritory]()
    var territoriesByCode = [UInt64: [MetadataTerritory]]()
    var mainTerritoryByCode = [UInt64: MetadataTerritory]()
    var territoriesByCountry = [String: MetadataTerritory]()
    
    // MARK: Lifecycle

    /**
     Private init populates metadata territories and the two hashed dictionaries for faster lookup.
     */
    public init () {
        territories = populateTerritories()
        for item in territories {
            var currentTerritories: [MetadataTerritory] = territoriesByCode[item.countryCode] ?? [MetadataTerritory]()
            currentTerritories.append(item)
            territoriesByCode[item.countryCode] = currentTerritories
            if mainTerritoryByCode[item.countryCode] == nil || item.mainCountryForCode == true {
                mainTerritoryByCode[item.countryCode] = item
            }
            territoriesByCountry[item.codeID] = item
        }
    }
    
    deinit {
        territories.removeAll()
        territoriesByCode.removeAll()
        territoriesByCountry.removeAll()
    }
    
    
    /// Populates the metadata from the included json file resource.
    ///
    /// - returns: array of MetadataTerritory objects
    fileprivate func populateTerritories() -> [MetadataTerritory] {
        var territoryArray = [MetadataTerritory]()
        do {
            let jsonPath = "/tmp/PhoneNumberMetadata.json"
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
            let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments)
            if let dictionary = dictionary as? [AnyHashable: Any] {
                let jsonObjects = NSDictionary(dictionary: dictionary)
                print("hier")
                if let metadataDict = jsonObjects["phoneNumberMetadata"] as? [AnyHashable: Any], let metadataTerritories = metadataDict["territories"] as? [AnyHashable: Any], let metadataTerritoryArray = metadataTerritories["territory"] as? [Any] {
                    print("hier 2")
                    let metadataTerritoryArray = NSArray(array: metadataTerritoryArray)
                    metadataTerritoryArray.forEach({
                        if let td = $0 as? [AnyHashable: Any] {
                            let territoryDict = NSDictionary(dictionary: td)
                            let parsedTerritory = MetadataTerritory(jsondDict: territoryDict)
                            territoryArray.append(parsedTerritory)
                        }
                    })
                }
            }
        }
        catch {}
        return territoryArray
    }
    
    // MARK: Filters
    
    /// Get an array of MetadataTerritory objects corresponding to a given country code.
    ///
    /// - parameter code:  international country code (e.g 44 for the UK).
    ///
    /// - returns: optional array of MetadataTerritory objects.
    internal func filterTerritories(byCode code: UInt64) -> [MetadataTerritory]? {
        return territoriesByCode[code]
    }
    
    /// Get the MetadataTerritory objects for an ISO 639 compliant region code.
    ///
    /// - parameter country: ISO 639 compliant region code (e.g "GB" for the UK).
    ///
    /// - returns: A MetadataTerritory object.
    internal func filterTerritories(byCountry country: String) -> MetadataTerritory? {
        return territoriesByCountry[country.uppercased()]
    }
    
    /// Get the main MetadataTerritory objects for a given country code.
    ///
    /// - parameter code: An international country code (e.g 1 for the US).
    ///
    /// - returns: A MetadataTerritory object.
    internal func mainTerritory(forCode code: UInt64) -> MetadataTerritory? {
        return mainTerritoryByCode[code]
    }
    
    
}