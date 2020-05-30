//
//  File.swift
//  algo
//
//  Created by 360medlink Tunisia on 5/28/20.
//  Copyright © 2020 360medlink Tunisia. All rights reserved.
//

import Foundation


class NamedEntity {
    var value : String = ""
    var type : EntityType = .none
    var score = 0
    
    var validatedPhones : [PhoneNumber] = []
    var inValidatedPhones : [PhoneNumber] = []
    
    init(value : String) {
        self.value = value
    }
    
    init(value : String, type : EntityType) {
        self.value = value
        self.type = type
    }
    
    func computeWebsite(namedEntityHolder : [ NamedEntity ] , prefixes : [PrefixHolder] ) -> [NamedEntity] {
        
        var holder : [NamedEntity] = []
        
        var matches = value.matchingStrings(regex: RecognitionTools.websiteRegex)
        matches.forEach { (item) in
            item.forEach { (subItem) in
                holder.append(NamedEntity(value: subItem, type: .website) )
            }
        }
        
        return holder
    }
    
    // is array because one line can contain multiple emails
    func computeEmails(namedEntityHolder : [ NamedEntity ] , prefixes : [PrefixHolder] ) -> [NamedEntity] {
        
        var holder : [NamedEntity] = []
        
        
        var matches = value.matchingStrings(regex: RecognitionTools.emailRegex)
        matches.forEach { (item) in
            item.forEach { (subItem) in
                if subItem.isValidEmail() {
                    holder.append(NamedEntity(value: subItem, type: .email) )
                }
            }
        }
        
        return holder
    }
    
    func computeFullName( namedEntityHolder : [ NamedEntity ] ) -> NamedEntity {
        //resultHolder[value] = score
        
        // extract email and website
        let emails = namedEntityHolder.filter { (namedEntity) -> Bool in
            namedEntity.type == .email
        }
        
        let websites = namedEntityHolder.filter { (namedEntity) -> Bool in
            namedEntity.type == .website
        }
        
        var tokensValue = value.components(separatedBy: " ")
        
        
        // remove white space so it detects correctly
        if  value.replacingOccurrences(of: " ", with: "").description.isAllNumber {
            return self
        }
        
        if !value.lengthBetween(l1: 3, l2: 25) {
            return self
        }
        
        
        
        if value.existInArray(array: namedEntityHolder.map({$0.value})) {
            return self
            /*
             Replaces :
             let result = namedEntityHolder.filter { (dkey, dvalue) in
             dvalue.value.existIn(container: self.value, caseSensitive: false, level: 1)
             }
             // already found in array, so we close and return
             if result.count > 0 {
             return self
             }
             */
        }
        
        // this needs prefix to be removed
        if 2...5 ~= tokensValue.count{
            //print("2...3 ~= tokensValue.count")
            //score += 10
        } else {
            return self
        }
        
        // todo : check if email , is valid ...
        if value.isValidEmail() {
            return self
        }
        
        if value.containsNumbers() {
            score -= 30
        }
        
        // TODO : DONE need to check for DR. PROF. and remove them from string
        if RecognitionTools.lowerCaseNamesPrefixes.contains(tokensValue.first?.trimmedAndLowercased ?? ""){
            tokensValue.removeFirst()
            value = tokensValue.joined(separator: " ")
            score += 30
        }
        
        
        
        for (index,element) in tokensValue.enumerated() {
            if element.containsNumbers() {
                score -= 10
            }
            if index < 1 {
                // first element
                if element.beginsWithUpperCase(){
                    score += 10
                }else{
                    score -= 20
                }
            }else {
                // rest of element
                if element.isAllUpperCase(){
                    score += 5
                } else if element.beginsWithUpperCase(){
                    score += 2
                } else {
                    score -= 5
                }
            }
            
            if element.trimmedAndLowercased.existInArray(array: RecognitionTools.lowerCasejobTitles, level: 0.7)  {
                //score -= 20
            }
        }
        
        print("Value : \(value.replacingOccurrences(of: " ", with: "")) Existis in \(emails.map({$0.value})) ? : \(value.replacingOccurrences(of: " ", with: "").existInArray(array: emails.map({$0.value}),preprocess: true , level: 0.8))")
        
        
        // if it exists in first part only THAN BIGGER SCORE FOR FULL NAME else BIGGER SCORE FOR COMPANY
        
        if value.existInArray(array: emails.map({$0.value.components(separatedBy: "@")[0] }), preprocess: true , level: 0.8) {
            score += 30
        }
        
        if value.existInArray(array: emails.map({$0.value.components(separatedBy: "@")[1] }), preprocess: true , level: 0.8) {
            score -= 10
        }
        
        if value.existInArray(array: websites.map({$0.value}), preprocess: true , level: 0.7){
            score -= 20
        }
        
        
        
        value.forEach { (char) in
            if RecognitionTools.removableNamesSpecial.contains(char.description){
                score -= 20
            }
        }
        
        
        
        return self
        
    }
    
    func computeCompany(namedEntityHolder : [ NamedEntity ] ) -> NamedEntity {
        
         
        // extract email and website
        let email = namedEntityHolder.filter { (namedEntity) -> Bool in
            namedEntity.type == .email
            }.first?.value ?? ""
        
        let website = namedEntityHolder.filter { (namedEntity) -> Bool in
        namedEntity.type == .website
        }.first?.value ?? ""
        
        let tokensValue = value.components(separatedBy: " ")
        
        if value.count < 2 {
            return self
        }
        
        // remove white space so it detects correctly
        if  value.replacingOccurrences(of: " ", with: "").description.isAllNumber {
            return self
        }
        
        
        tokensValue.forEach({ (item) in
            if item.existIn(container: website, level: 0.8) {
                score += 40
                return // todo : this does not break the loop
            }
        })
        
        tokensValue.forEach({ (item) in
            if item.existIn(container: email, level: 0.7) {
                score += 40
                return
            }
        })
        
        
        if value.isAllUpperCase(){
            score += 20
        }else if value.beginsWithUpperCase() {
            score += 10
        }else {
            score -= 30
        }
        
        
        if tokensValue.count == 1 {
            score += 20
        } else if 2...4 ~= tokensValue.count{
            score += 10
        }else{
            score -= 10
        }
        
        // TODO : EXIST IN PREMADE DATA
        
        return self
    }
    
    func computeTitle( namedEntityHolder : [ NamedEntity ])-> NamedEntity{
        
        let tokensValue = value.components(separatedBy: " ")
        
        if value.count < 2 {
            return self
        }
        
        // remove white space so it detects correctly
        if  value.replacingOccurrences(of: " ", with: "").description.isAllNumber {
            return self
        }
        
        if value.existInArray(array: namedEntityHolder.map({$0.value})) {
            return self
        }
        
        // todo : check if email , is valid ...
        if value.isValidEmail() {
            return self
        }
        
        switch tokensValue.count {
        case let val where val > 3 : score -= 5
        case 2: score += 15
        case 1 : score += 10
        default:
            break
        }
        
        if value.containsNumbers() {
            score -= 30
        }
        
        for (index,element) in tokensValue.enumerated() {
            if index < 1 {
                // first element
                if element.beginsWithUpperCase(){
                    score += 10
                }else{
                    score -= 20
                }
            }else {
                // rest of element
                if element.isAllUpperCase(){
                    score += 5
                } else if element.beginsWithUpperCase(){
                    score += 2
                }
                // second part can be lower case
            }
            
            if RecognitionTools.lowerCasejobTitles.contains(element.trimmedAndLowercased)  {
                score += 40
            }
        }
        
        
        
        return self
    }
    
    /// AT THIS Stage : Title, Company , FullName, Email, Website, should have been removed from RAW and not process again
    func computePhoneNumber(namedEntityHolder : [ NamedEntity] , prefixes : [PrefixHolder] , phoneNumberKit : PhoneNumberKit) -> [NamedEntity] {
        
        //        var validatedPhones : [PhoneNumber] = []
        //        var invalidatedPotentialPhones : [PhoneNumber] = []
        
        var resultHolder : [NamedEntity] = []
        
        
        if value.count < 4 {
            self.score = -100
            return [self]
        }
        
        if !value.containsNumbers() {
            self.score = -100
            return [self]
        }
        
        
        // FROM https://zapier.com/blog/extract-links-email-phone-regex/
        
        // more robust extraction between special chars : (?:(?:\+?([1-9]|[0-9][0-9]|[0-9][0-9][0-9])\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([0-9][1-9]|[0-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?
        var matches = value.matchingStrings(regex: RecognitionTools.numberPhoneRegexFromString)
        matches.forEach { (arrayOfString) in
            print("Validating \(arrayOfString)")
            if arrayOfString[0].count > 2 {
                do {
                    let phoneNumber = try phoneNumberKit.parse(arrayOfString[0])
                    validatedPhones.append(phoneNumber)
                } catch {
                    inValidatedPhones.append(PhoneNumber(numberString: arrayOfString[0], countryCode: 0, leadingZero: false, nationalNumber: 0, numberExtension: nil, type: .notParsed, regionID: nil))
                }
            }
        }
        
        
        matches = value.matchingStrings(regex: RecognitionTools.numberPhoneRegexFromStringComplex)
        
        matches.forEach { (arrayOfString) in
            arrayOfString.forEach { (item) in
                if !validatedPhones.contains(where: { (phoneNumber) -> Bool in
                    phoneNumber.numberString == item
                }) {
                    print("Second Validating \(item)")
                    if item.count > 2 {
                        do {
                            let phoneNumber = try phoneNumberKit.parse(item)
                            validatedPhones.append(phoneNumber)
                        } catch {
                            inValidatedPhones.append(PhoneNumber(numberString: item, countryCode: 0, leadingZero: false, nationalNumber: 0, numberExtension: nil, type: .notParsed, regionID: nil))
                        }
                    }
                }
            }
        }
        
        // NOW THAT I GOT SOME GOOD and MAYBE BAD NUMBERS .. Process phone to get their types
        
        validatedPhones.forEach { (phoneNumber) in
            
            var phoneEntity : NamedEntity = NamedEntity(value: phoneNumber.numberString)
            
            
            if let foundInPrefix = prefixes.first(where: { (prefixHolder) -> Bool in
                phoneNumber.numberString.existIn(container: prefixHolder.value)
            }) {
                // lets guess the phone type with our enum entity type
                
                //                let entityTypeStrings = EntityType.allCases.map($0.)
                //
                //                foundInPrefix.key.existInArray(array: )
                
                if foundInPrefix.key.existInArray(array: RecognitionTools.directPrefixes) {
                    phoneEntity.type = .direct
                }else if foundInPrefix.key.existInArray(array: RecognitionTools.phonePrefixes) {
                    phoneEntity.type = .phone
                }else if foundInPrefix.key.existInArray(array: RecognitionTools.faxPrefixes) {
                    phoneEntity.type = .fax
                }else if foundInPrefix.key.existInArray(array: RecognitionTools.mobilePrefixes) {
                    phoneEntity.type = .mobile
                }else {
                    phoneEntity.type = .mobile
                }
                
                
            }else{
                // lets juste pick wat phoneKit suggests us
                
                switch phoneNumber.type {
                case .fixedLine:
                    phoneEntity.type = .fax
                case .mobile:
                    phoneEntity.type = .mobile
                case .fixedOrMobile :
                    phoneEntity.type = .phone
                default:
                    phoneEntity.type = .direct
                }
                
            }
            
            resultHolder.append(phoneEntity)
        }
        
        inValidatedPhones.forEach { (invalidatedPhone) in
            var phoneEntity : NamedEntity = NamedEntity(value: invalidatedPhone.numberString)
            if let foundInPrefix = prefixes.first(where: { (prefixHolder) -> Bool in
                invalidatedPhone.numberString.existIn(container: prefixHolder.value, level: 0.6) // found this malformed phone in extracted prefixes
            }) {
                if foundInPrefix.key.existInArray(array: RecognitionTools.directPrefixes) {
                    phoneEntity.type = .direct
                }else if foundInPrefix.key.existInArray(array: RecognitionTools.phonePrefixes) {
                    phoneEntity.type = .phone
                }else if foundInPrefix.key.existInArray(array: RecognitionTools.faxPrefixes) {
                    phoneEntity.type = .fax
                }else if foundInPrefix.key.existInArray(array: RecognitionTools.mobilePrefixes) {
                    phoneEntity.type = .mobile
                }else {
                    phoneEntity.type = .unknown
                }
            }else{
                phoneEntity.type = .mobile
            }
        }
        
        // One row can contain multiple , so we may need to return ARRAY of [NamedEntity]
        
        // Potential phones not validated by phoneKit
        
        // lets keep tryin extracting missing numbers.. MAYBE
        
        return resultHolder
    }
    
}


extension String {
    
    func existInArray (array : [String] , preprocess : Bool = false , level : Double = 0.9) -> Bool {
        
        var preprocessed = self
        
        
        if preprocess {
            preprocessed = preprocessed.trimmedAndLowercased
            preprocessed = preprocessed.replacingOccurrences(of: " ", with: "")
            preprocessed = preprocessed.replacingOccurrences(of: preprocessed.filter({RecognitionTools.removeableChars.contains($0)}), with: "")
        }
        
        
        return array.first { (element) -> Bool in
            
            
            element
                .trimmedAndLowercased
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: preprocessed.filter({RecognitionTools.removeableChars.contains($0)}), with: "")
                .distanceJaroWinkler(between: preprocessed) > level
            }?.count ?? 0 > 0
    }
    
    func existInDictionnary(dictionnary : [EntityType : NamedEntity ], level : Double = 0.9) -> Bool {
        let result = dictionnary.filter { (dkey, dvalue) in
            dvalue.value.existIn(container: self, level: level)
        }
        // already found in array, so we close and return
        if result.count > 0 {
            return true
        }else{
            return false
        }
    }
    
    var isCNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var isAllNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    func lengthBetween(l1 : Int , l2: Int) -> Bool {
        if self.count >= l1 && self.count <= l2 {
            return true
        }else{
            return false
        }
    }
    
    func isUppercased(at: Index) -> Bool {
        let range = at..<self.index(after: at)
        return self.rangeOfCharacter(from: .uppercaseLetters, options: [], range: range) != nil
    }
    
    func isLowercased(at: Index) -> Bool {
        let range = at..<self.index(after: at)
        return self.rangeOfCharacter(from: .lowercaseLetters, options: [], range: range) != nil
    }
    
    func containsNumbers() -> Bool {
        let decimalCharacters = CharacterSet.decimalDigits
        let decimalRange = self.rangeOfCharacter(from: decimalCharacters)
        
        if decimalRange != nil {
            return true
        }else{
            return false
        }
    }
    
    func beginsWithUpperCase() -> Bool {
        if isUppercased(at: self.startIndex){
            return true
        }else{
            return false
        }
    }
    
    func isAllUpperCase() -> Bool {
        let lowercases = self.filter({ $0.isLowercase })
        
        if lowercases.count > 0 {
            return false
        }else{
            return true
        }
    }
    
    func existIn(container: String, level: Double = 0) -> Bool {
        if self.lowercased() .distanceJaroWinkler(between: container.lowercased()) > level {
            return true
        }else{
            return false
        }
    }
    
    func countWords(separtedBy : String = " ") -> Int {
        return self.components(separatedBy: separtedBy).count
    }
    
}


extension Character {
    var isUppercase: Bool {
        let str = String(self)
        return str.isUppercased(at: str.startIndex)
    }
}
