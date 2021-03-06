//
//  RecognitionTools.swift
//  algo
//
//  Created by 360 medlink on 6/29/20.
//  Copyright © 2020 360medlink Tunisia. All rights reserved.
//

import Foundation

enum PremadeEntities : String, CaseIterable {
    case titles = "titles"
    case cities = "cities"
    case states = "states"
}

class RecognitionTools {
    
    static var languageSession : SupportedLangage = .eng
    
    static func removePrefixOccurence( bcDataArray : inout [String] ){
        var array : [String] = []
        for (_,line) in bcDataArray.enumerated() {
            
            var newLine = line
            RecognitionTools.businessCardPrefixes.flatMap({$0}).forEach { (prefix) in
                if line.preprocess == prefix {
                    newLine = (line.replacingOccurrences(of: prefix, with: "",options: .caseInsensitive))
                }
            }
            
            array.append(newLine)
        }
        
        bcDataArray = array.filter({!$0.isEmpty && $0.count > 2})
    }
    
    static func postProcessResult (bcDataArray : inout [String] , namedEntityHolder: inout [NamedEntity]){
        var resultEntityHolder : [ NamedEntity] = []
        // remove duplicate
        
        namedEntityHolder.forEach { (resultEntity) in
            if resultEntity.score > -10 && !resultEntityHolder.contains(where: {
                $0.value == resultEntity.value &&
                $0.type == resultEntity.type
            }){
                
                
//                resultEntity.value = resultEntity.value.trimmingCharacters(in: .punctuationCharacters)
                resultEntity.value = resultEntity.value.trimmed
                
                
                resultEntityHolder.append(resultEntity)
            }
        }
        
        namedEntityHolder = resultEntityHolder
        
        // entity with score < - 10 should be removed
        
    }
    
    
    
    static func loadStatesWithPrefix(prefix : String, completion : @escaping (_ : Bool) -> ()) {
        let url = URL(string: "http://api.abracardabra.pre-360.net/states/\(prefix)/\(RecognitionTools.languageSession)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let _ = error {
                completion(false)
            }else if let response = response as? HTTPURLResponse {
                
                // todo : make it check for status code or data before continiuing
                if response.statusCode == 200 {
                    do {
                        let decoder = JSONDecoder()
                        let citiesResponse = try decoder.decode(StatesWithPrefixSuccess.self, from: data!)
                        
                        statesWithPrefix.append(contentsOf: citiesResponse.success.data.map({$0.name.trimmedAndLowercased}))
                            completion(true)
                        
                        
                    } catch _ {
                          completion(false)
                       
                    }
                }else{
                     completion(false)
                }
                
            }
        }.resume()
    }
    
    static func loadCitiesWithPrefix(prefix : String, completion : @escaping (_ : Bool) -> ()) {
        let url = URL(string: "http://api.abracardabra.pre-360.net/cities/\(prefix)/\(RecognitionTools.languageSession)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let _ = error {
                 completion(false)
            }else if let response = response as? HTTPURLResponse {
                print("WA DA HECK")
                // todo : make it check for status code or data before continiuing
                if response.statusCode == 200 {
                    do {
                        let decoder = JSONDecoder()
                        let citiesResponse = try decoder.decode(CitiesWithPrefixSuccess.self, from: data!)
                        
                        citiesWithPrefix.append(contentsOf: citiesResponse.success.data.map({$0.name.trimmedAndLowercased}))
                        
                       
                            completion(true)
                       
                        
                    } catch _ {
                             completion(false)
                        
                    }
                }else{
                     completion(false)
                }
            }
        }.resume()
    }
    
    
    
    static func loadArrayContentIntoFile<T>(array : [T], completion : @escaping (Bool, Int) -> ()){
        
    }
    
    static func loadArrayContentOfTypeFromFile<T : Codable>(type : T, language : SupportedLangage, completion : @escaping (Bool, Int) -> ()){
        
        let contentNameFile = "\(String(describing: type.self))_\(language.rawValue)"
        
        if let path = Bundle.main.path(forResource: contentNameFile, ofType: "json") {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                // Getting data from JSON file using the file URL
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                
                let jsonDecoder = JSONDecoder()
                let response = try? jsonDecoder.decode( Response<[T]>.self , from: data)
                
            } catch {
                // Handle error here
                completion(false,-1)
            }
        }
        completion(true, self.titles?.count ?? 0)
    }
    
    
    static func loadTitles(completion : @escaping (_ : Bool) -> ()) {
        
        
        let url = URL(string: "http://api.abracardabra.pre-360.net/titles/\(RecognitionTools.languageSession)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let _ = error {
                completion(false)
            }else if let response = response as? HTTPURLResponse {
                
                // todo : make it check for status code or data before continiuing
                if response.statusCode == 200 {
                    do {
                        let decoder = JSONDecoder()
                        let citiesResponse = try decoder.decode(titlesPMSuccess.self, from: data!)
                        
                        lowerCasejobTitles.append(contentsOf: citiesResponse.success.data.map({$0.title_name.trimmedAndLowercased}))
                        DispatchQueue.main.async() {
                            completion( true)
                        }
                        
                    } catch _ {
                        DispatchQueue.main.async() {
                            completion(false)
                        }
                    }
                }else{
                     completion(false)
                }
                
            }
        }.resume()
    }
    
    static func preProcessRemoveExtractedWithPosition(bcDataArray : inout [String] , namedEntityHolder: [ NamedEntity], forceRemove : Bool = false ) -> Void {
        var bcDataArrayCopy : [String] = []
        
        

        var unique = namedEntityHolder
        .enumerated()
        .filter{ namedEntityHolder.firstIndex(of: $0.1) == $0.0 }
        .map{ $0.1 }
        
        unique = namedEntityHolder.filter({!$0.removed})
        
        bcDataArray.enumerated().forEach { (indexElement) in
            if unique.filter({$0.position == indexElement.offset && !$0.removed }).first == nil {
                bcDataArrayCopy.append(indexElement.element)
            }
        }
        
        namedEntityHolder.forEach({$0.removed = true})
        
        bcDataArray = bcDataArrayCopy
    }
    
    static func preProcessRemoveExtracted(bcDataArray : inout [String] , namedEntityHolder: [ NamedEntity], forceRemove : Bool = false ) -> Void {
        // use namedEntityHolder remove from bcDataArra
        var array : [String] = []
        
        
        
        
        for (index,line) in bcDataArray.enumerated() {
            
            var newLine = line
            namedEntityHolder.forEach { (namedEntity) in
                if line.preprocess.contains(namedEntity.value.preprocess) {
                    newLine = (line.replacingOccurrences(of: namedEntity.value.preprocess, with: "",options: .caseInsensitive))
                }
            }
            
            array.append(newLine)
            //            if namedEntityHolder.contains(where: {$0.value == line}) {
//            if line.existInArray(array: namedEntityHolder.map({$0.value}), preprocess: true, level : 0.9) || line.trimmedAndLowercased.count < 2 {
//
//                array.append("")
//
//
//                //            }
//                //
//                //
//                //            if (line.description.existInArray(array: namedEntityHolder.map({
//                //                $0.value
//                //            }))){
//                // need to remove
//                //print("Removing INDEX \(index)")
//                //bcDataArray.remove(at: index)
//            }else if forceRemove{
//
//                // advanced remove
//
//                //print("Removing WITH ITs POSITION : \()  FROM \(line)")
//
//                namedEntityHolder.forEach { (namedEntity) in
//                    if line.contains(namedEntity.value) {
//                        array.append(line.replacingOccurrences(of: namedEntity.value, with: "",options: .caseInsensitive))
//                    }
//                }
//
//                //namedEntityHolder.forEach({array.append(line.replacingOccurrences(of: $0.value, with: "",options: .caseInsensitive))})
//
////                if (namedEntityHolder.filter({$0.position == index}).first != nil) {
////
////
////                    if let foundInString = namedEntityHolder.filter({$0.value.stringEqualityDistance(container: line, preprocess: true, ratio: 0.6)}).first {
////                        array.append(
////                            line
////                                .replacingOccurrences(of: " ", with: "")
////                                .replacingOccurrences(of: "-", with: "")
////                                .replacingOccurrences(of: "+", with: "")
////                                .replacingOccurrences(of: foundInString.value
////                                    .replacingOccurrences(of: " ", with: "")
////                                    .replacingOccurrences(of: "-", with: "")
////                                    .replacingOccurrences(of: "+", with: "")
////                                    , with: "", options: .caseInsensitive))
////
////                        print("Force removing \(foundInString.value)  FROM \(line)  ---- RESULT : \(line.preprocess.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: foundInString.value.preprocess.replacingOccurrences(of: "+", with: ""), with: ""))")
////
////                        let cleaned = foundInString.value
////
////                    }else {
////                        array.append(line)
////                    }
////                }
////                else {
////                    array.append(line)
////                }
//            }else{
//                array.append(line)
//            }
        }
        
        bcDataArray = array.filter({!$0.isEmpty})
    }
    
    
    static func preProcessRaw(raw : inout String , prefixedEntities : inout [PrefixHolder] , bcDataArray : inout [String], remove : Bool = false) -> Void {
        
        prefixedEntities = preProcessPrefixes(raw: raw, bcDataArray: &bcDataArray)
        
        testPrint(tag: "Prerpcess ", title: "Extracted prefixedEntities", content: prefixedEntities)
        
    }
    
    ///This preprocess function only care about KEY : VALUE , where content of key value doesnt matter
    private static func preProcessPrefixes(raw : String , bcDataArray : inout [String] ) -> [PrefixHolder] {
        var prefixesEntities : [PrefixHolder] = []
        for (index,line) in bcDataArray.enumerated() {
            // lets do the separation stuff BASED ON " : " Prefix
            
            
            // TODO : DONE  ANOTHER CASE HERE : -->>  M : +216 22 126 466 (/ , | , separtor) +216 36 126 466
            // DOOOOO NOT SEPARATE WITH PHONE SEPARATORS  : - , () , ..
            
            
            // if prefix KEY found with empty VALUE , supress Take the next line as VALUE
            let separatorOccurenceByPoint = line.components(separatedBy:":")
            //testPrint(tag: "Prefix ", title: "separation BY 2POINT", content: separatorOccurenceByPoint)
            switch separatorOccurenceByPoint.count {
            case 2 : do {
                // this is our best bet Key : Val
                if separatorOccurenceByPoint[1].count == 0 {
                    // we got empty VALUE so we grab it eye closes from next line
                    prefixesEntities.append(PrefixHolder(key: separatorOccurenceByPoint.first?.trimmed ?? "", value: String(bcDataArray[index+1]) , type: .unknown))
                    //bcDataArray[index] = line.replacingOccurrences(of: bcDataArray[index], with: "")
                }else{
                    
                    // here its not the end , we need to processs string , if it contains , some special phone separtors like : "/" , " | "  "," maybe
                    
                    var separatorPosition = -1
                    
                    
                    RecognitionTools.bcPhoneSeparators.forEach { (separator) in
                        if line.contains(separator){
                            // its important to get the last index , and not first index ( prefix can contain / )
                            separatorPosition = line.lastIndexInt(of: Character(separator)) ?? -1
                        }
                    }
                    
                    if separatorPosition > -1 {
                        // we found some content with separtor
                        // lets loop and add them one by one
                        // suppose line can contain ONLY ONE VALUE / SEPARATOR
                        
                        let prefixedSeparatedByPoints = line.prefix(separatorPosition).components(separatedBy: ":")
                        // PREFIX , CONTAIN FOR SUUUUURE THE SEPARTOR ":"
                        
                        prefixesEntities.append(PrefixHolder(key: prefixedSeparatedByPoints.first?.trimmed ?? "", value: prefixedSeparatedByPoints[1].trimmed , type: .unknown))
                        
                        // suffix , begin counting from end of the string
                        // PREFIX , CONTAIN FOR SUUUUURE THE SEPARTOR ":"
                        
                        prefixesEntities.append(PrefixHolder(key: prefixedSeparatedByPoints.first?.trimmed ?? "", value: String(line.suffix(line.count - separatorPosition - 1)).trimmed , type: .unknown))
                        
                        
                        
                    }else {
                        
                        prefixesEntities.append(PrefixHolder(key: separatorOccurenceByPoint.first?.trimmed ?? "", value: separatorOccurenceByPoint[1] , type: .unknown))
                    }
                }
                
//                bcDataArray[index] = line.replacingOccurrences(of: separatorOccurenceByPoint[0], with: " ")
                
                break
                }
                
            case let val where val > 2 : do {
                // this is strange case , contains more than 2 separtor
                
                // exemple : TEL : 2323232 ABC : 232323232 or T : 2323233X: 232322
                
                // remove prefix from string , try to obtain separator from the long string
                
                // lets look for another separation between THE ORGINAL STRING which can be : (PREFIX : ), / , \ , | , ....
                // we got more than 1 prefixes ..
                
                // separator " : " , means theres a string prefix , so , lets separate them by space , and look for it's position
                
                // lets grabs the : position , and back off until we found the prefix
                
                let position : Int = line.lastIndexInt(of: ":") ?? 0 // this should not create index out of range
                var prefixeBuilder = ""
                
                for index in stride(from: position, through: 0, by: -1)  {
                    
                    if !line[index].isNumber {
                        // build the prefix until not a number
                        prefixeBuilder.append(line[index])
                    }else {
                        // maybe stop the looping , no neeeed to continue alll the way back
                        break
                    }
                    
                }
                // once stopped , ( we found a new prefix
                
                prefixeBuilder = String(prefixeBuilder.reversed())
                
                // separate the original by founded prefix
                if prefixeBuilder.count > 0 {
                    
                    
                    // FOR PREFIX
                    var newSeparation = line.prefix(position - prefixeBuilder.count + 1)
                    // todo : THIS DOES CRASH CARD
                    // reprocess using ":" Code duplication Warning
                    
                    var separatorOccurenceByPoint = newSeparation.components(separatedBy:":")
                    //testPrint(tag: "Prefix ", title: "separation BY 2POINT", content: separatorOccurenceByPoint)
                    if separatorOccurenceByPoint.count == 2 { // this time we should have only TWO
                        // this is our best bet Key : Val
                        if separatorOccurenceByPoint[1].trimmed.count == 0 {
                            // we got empty VALUE so we grab it eye closes from next line
                            prefixesEntities.append(PrefixHolder(key: separatorOccurenceByPoint.first?.trimmed ?? "", value: String(bcDataArray[index+1]) , type: .unknown))
                            //bcDataArray[index] = line.replacingOccurrences(of: bcDataArray[index], with: "")
                            
                            //bcDataArray[index] = ""
                            //bcDataArray.append(String(bcDataArray[index+1]))
                            
                        }else{
                            prefixesEntities.append(PrefixHolder(key: separatorOccurenceByPoint.first?.trimmed ?? "", value: separatorOccurenceByPoint[1] , type: .unknown))
                            
                            //bcDataArray[index] = ""
                            //bcDataArray.append(separatorOccurenceByPoint[1])
                            
                        }
                        
                    }
                    
                    
//                    // FOR SUFFIX
//                    if (position > prefixeBuilder.count - 1) {
//                        newSeparation = line.suffix(position - prefixeBuilder.count - 1)
//                    }else{
//                        newSeparation = line.suffix(prefixeBuilder.count - position)
//                    }
                    
                    // juste remove occurence of NEW SEPARTION of first key : val compoenntnt
                    
                    let newLine = line.replacingOccurrences(of: newSeparation, with: "",options: .caseInsensitive)
                    
                    separatorOccurenceByPoint = newLine.components(separatedBy:":")
                    //testPrint(tag: "Prefix ", title: "separation BY 2POINT", content: separatorOccurenceByPoint)
                    if separatorOccurenceByPoint.count == 2 { // this time we should have only TWO
                        // this is our best bet Key : Val
                        if separatorOccurenceByPoint[1].count == 0 {
                            // we got empty VALUE so we grab it eye closes from next line
                            
                            let phone = bcDataArray[index+1]
                            let testPhone = phone.count > 6 && phone.isPhoneNumber
                            
                            prefixesEntities.append(PrefixHolder(key: separatorOccurenceByPoint.first?.trimmed ?? "", value: String(bcDataArray[index+1]) , type: testPhone ? .phone : .unknownPhone))
                            
                            //bcDataArray[index] = ""
                            //bcDataArray.append(String(bcDataArray[index+1]))
                            
                        }else{
                            
                            let phone = separatorOccurenceByPoint[1]
                            let testPhone = phone.count > 6 && phone.isPhoneNumber
                            
                            prefixesEntities.append(PrefixHolder(key: separatorOccurenceByPoint.first?.trimmed ?? "", value: separatorOccurenceByPoint[1] , type: testPhone ? .phone : .unknownPhone))
                            
                            //bcDataArray[index] = ""
                            //bcDataArray.append(separatorOccurenceByPoint[1])
                        }
                        
                        //    mutableLine = mutableLine.replacingOccurrences(of: prefixeBuilder, with: "/n")
                        
                    }else{
                        // strange case , not processing anymore
                    }
                    
                    
                    
                }// else sorry i tried every think
                
                }
                
                
            default:
                // just ignore those because they dont contain any separtor
                break
            }
            
            // AT THIS STAGE : We extracted lines with ":"
            
            // PROCESS STUFF BASED ON Word espace Content of known type
            // TODOO : Process those who begins with PREFIX ( in the known prefix tbale ) / espace / CONTENT OF TYPE : NUMBER
            
            //lets do more with char
            
            // if prefix KEY found with empty VALUE , supress Take the next line as VALUE
            let separatorOccurenceBySpace = line.components(separatedBy:" ")
            //testPrint(tag: "Prefix ", title: "separation BY SPACE", content: separatorOccurenceBySpace)
            
            if separatorOccurenceBySpace.count > 1 {
                
                if let firstElement = separatorOccurenceBySpace.first {
                    let removedFirst = separatorOccurenceBySpace.dropFirst()
                    
                    if firstElement.lengthBetween(l1: 1, l2: 8)
                        && !firstElement.existInArray(array: prefixesEntities.map({$0.key}))
                    {
                        
                        if RecognitionTools.bcPhonesPrefixes.flatMap({$0}).contains(where: {$0.stringEqualityDistance(container: firstElement, preprocess: true, ratio: 0.2)}) {
                            
                            if let foundAnotherPrefix = removedFirst.filter({ (element) -> Bool in
                                element.existInArray(array: RecognitionTools.bcPhonesPrefixes.flatMap({$0}))
                            }).first {
                             
                                // split by that prefix
                                let secondSeparation = removedFirst.joined(separator: " ").components(separatedBy: foundAnotherPrefix)
                                let testPhone = secondSeparation[0].count > 6 && secondSeparation[0].isPhoneNumber && !firstElement.containsNumbers()
                                
                                prefixesEntities.append(PrefixHolder(key: firstElement, value: secondSeparation[0] , type: testPhone ? .phone : .unknownPhone))
                                prefixesEntities.append(PrefixHolder(key: foundAnotherPrefix, value: secondSeparation[1] , type: .phone))
                                
                            } else {
                                // i think we are good to put the value as it is
                                let phone = removedFirst.joined(separator: " ")
                                let testPhone = phone.count > 6 && phone.isPhoneNumber
                                prefixesEntities.append(PrefixHolder(key: firstElement, value: removedFirst.joined(separator: " ") , type: testPhone ? .phone : .unknownPhone))
                                //bcDataArray[index] = bcDataArray[index].replacingFirstOccurrenceOf(target: firstElement, withString: "")
                            }
                            
                        }else if RecognitionTools.bcPhonesPrefixes.flatMap({$0}).contains(where: {$0.stringEqualityDistance(container: firstElement, preprocess: true, ratio: 0.2)}) {
                            
                            if let foundAnotherPrefix = removedFirst.filter({ (element) -> Bool in
                                element.existInArray(array: RecognitionTools.bcPhonesPrefixes.flatMap({$0}))
                            }).first {
                             
                                // split by that prefix
                                let secondSeparation = removedFirst.joined(separator: " ").components(separatedBy: foundAnotherPrefix)
                                
                                prefixesEntities.append(PrefixHolder(key: firstElement, value: secondSeparation[0] , type: .unknown))
                                prefixesEntities.append(PrefixHolder(key: foundAnotherPrefix, value: secondSeparation[1] , type: .unknown))
                                
                            }else {
                                // i guess wee found some prefix so lets pretend
                                prefixesEntities.append(PrefixHolder(key: firstElement, value: removedFirst.joined(separator: " ") , type: .unknown))
                                //bcDataArray[index] = bcDataArray[index].replacingFirstOccurrenceOf(target: firstElement, withString: "")
                            }
                            
                            
                        }
                    }
                    // else ignore
                }
            }
            
        }
        
        
        prefixesEntities.enumerated().forEach { (index,prefixHolder) in
            if RecognitionTools.bcPhonesPrefixes.flatMap({$0}).contains(where: {$0.stringEqualityDistance(container: prefixHolder.key, preprocess: true, ratio: 0.7)}) {
                prefixesEntities[index].type = .phone
            }else{
                prefixesEntities[index].type = .unknown
            }
        }
        
        
        return prefixesEntities.map { (prefixEntity) -> PrefixHolder in
            return PrefixHolder(key: prefixEntity.key.trimmedAndLowercased, value: prefixEntity.value.trimmedAndLowercased, type: prefixEntity.type)
        }
        
    }
    
    static var organisationSuffix = [
        //https://en.wikipedia.org/wiki/List_of_legal_entity_types_by_country
        "inc.",
        "co.",
        "corp.",
        "ltd.",
        "B-corp",
        
    ]
    
    static var removeableChars : [Character] = [
        "!", "#", "$", "%", "&" , "*" , "/" , "<", ">" , "?" , "|" , "_" , ":" , "-" , "."
    ]
    
    static var webSitePrefixes = [
        "www.",
        "http://",
        "https://",
    ]
    
    static var webSiteSuffixes = [
        ".com",
        ".de",
        ".da",
        "."
        
    ]
    
    static var secondAdress = [
        "po",
        "box",
    "pobox",
    "cedex",
    ]
    
    static var emailsDomains = [
        /* Default domains included */
        "aol", "att", "comcast", "facebook", "gmail", "gmx", "googlemail",
        "google", "hotmail", "mac", "me", "mail", "msn",
        "live", "sbcglobal", "verizon", "yahoo",
        
        /* Other global domains */
        "email", "fastmail", "games" /* AOL */,  "hush", "hushmail", "icloud",
        "iname", "inbox", "lavabit", "love" /* AOL */, "pobox", "protonmail", "protonmail", "tutanota", "tutamail", "tuta",
        "keemail", "rocketmail" /* Yahoo */, "safe-mail", "wow" /* AOL */, "ygm" /* AOL */,
        "ymail" /* Yahoo */, "zoho", "yandex",
        
        /* United States ISP domains */
        "bellsouth", "charter", "cox", "earthlink", "juno",
        
        /* British ISP domains */
        "btinternet", "virginmedia", "blueyonder", "freeserve", "live",
        "ntlworld", "o2", "orange", "sky", "talktalk", "tiscali",
        "virgin", "wanadoo", "bt",
        
        /* Domains used in Asia */
        "sina", "sina", "qq", "naver", "hanmail", "daum", "nate", "yahoo", "163", "yeah", "126", "21cn", "aliyun", "foxmail",
        
        /* French ISP domains */
        "live", "laposte", "wanadoo", "orange", "gmx", "sfr", "neuf", "free",
        
        /* German ISP domains */
        "gmx", "hotmail", "live", "online", "t-online" /* T-Mobile */, "web",
        
        /* Italian ISP domains */
        "libero", "virgilio", "hotmail" , "tiscali", "alice", "live", "email", "tin", "poste", "teletu",
        
        /* Russian ISP domains */
        "mail", "rambler", "yandex", "ya", "list",
        
        /* Belgian ISP domains */
        "hotmail", "live", "skynet", "voo", "tvcablenet", "telenet",
        
        /* Argentinian ISP domains */
        "hotmail", "live", "fibertel", "speedy", "arnet",
        
        /* Domains used in Mexico */
        "live", "hotmail", "hotmail", "prodigy",
        
        /* Domains used in Canada */
        "bell", "shaw", "sympatico", "rogers",
        
        /* Domains used in Brazil */
        "yahoo", "hotmail", "outlook", "uol", "bol", "terra", "ig", "itelefonica", "r7", "zipmail", "globo", "globomail", "oi"
    ]
    
    static var bcPhoneSeparators = [
        "/",
        "\\",
        "|"
    ]
    
    
    static var bcPhonesPrefixes = [
        directPrefixes,
        phonePrefixes,
        mobilePrefixes,
        faxPrefixes
    ]
    
//    static var bcEntityPrefixes = [
//        emailPrefixes
//    ]
    
    static var directPrefixes = [
        "d",
        "dir.",
        "ld",
        "direct",
        "line",
        "line.",
        
        "tel (direct)",
        "tél (direct)",
        "direct line",
        "ligne directe",
        "linea dedicada",
        "didww",
        "did",
        "ddi",
        "pstn",
        "dd",
        "direction",
        
    ]
    
    static var phonePrefixes = [
        "p",
        "phone",
        "phone.",
        "p",
        "p.",
        "tel",
        "tél",
        "téléphone",
        "té",
        "télép",
        "telefon",
        "stand.",
        "standard",
        
        "tel.",
        "tél.",
        "t.",
        "t",
        "ph",
        "tél.",
        "tel. - fax.",
        "tél. - fax.",
        
        "office",
        "bureau",
        "tf",
    ]
    
    static var mobilePrefixes = [
        "m",
        "m.",
        "gsm",
        "mobile",
        "mobile.",
        "portable",
        "portable.",
        "port",
        "c",
        "c.",
        "cell",
        "cell.",
        "cellular",
        "mob",
    ]
    
    static var faxPrefixes = [
        "f",
        "f.",
        "fax",
        "fax.",
        "téléc.",
        "télécopie",
        "tel. - fax.",
        "tél. - fax.",
    ]
    
    
    
    static var websiteRegex = "\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
    //IS MORE HARDCORE EXTRACTING EVERY THINK WITH X.Y"(?:(?:https?|ftp):\\/\\/)?[\\w/\\-?=%.]+\\.[\\w/\\-?=%.]+"
    
    static var emailRegex = "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
    
    static var numberPhoneRegexFromString = "(?<=[ ])[\\d \\-+()]+$|(?<=[ ])[\\d \\-+()]+(?=[ ]\\w)"
    
    static var numberPhoneRegexFromStringComplex = "(?:(?:\\+?([1-9]|[0-9][0-9]|[0-9][0-9][0-9])\\s*(?:[.-]\\s*)?)?(?:\\(\\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\\s*\\)|([0-9][1-9]|[0-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\\s*(?:[.-]\\s*)?)?([0-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\\s*(?:[.-]\\s*)?([0-9]{4})(?:\\s*(?:#|x\\.?|ext\\.?|extension)\\s*(\\d+))?"
    
    
    static var numberSinglePhoneRegexWithNoSpecial = "^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\\s\\./0-9]*$"
    
    static var businessCardPrefixes = [
        bcEmailPrefixes,
        faxPrefixes,
        mobilePrefixes,
        phonePrefixes,
        directPrefixes
    ]
    
    static var bcEmailPrefixes = [
        "e",
        "email",
        "e-mail",
        "mail",
        "e:",
        "m:",
        "contact"
    ]
    
    static var removableNamesSpecial = [",","@","&"]
    
    static var lowerCasejobTitles = ["diplom","it"]
    
    static var lowerCaseNamesPrefixes = [
        "docteur",
        "doc.",
        "mr.",
        "mrs.",
        "ms.",
        "miss",
        "dr.",
        "dr",
        "a.v.m",
        "adm.",
        "amb",
        "amn",
        "archbishop",
        "baron",
        "baroness",
        "bishop",
        "brig. gen.",
        "bigadier",
        "bro.",
        "cantor",
        "capt.",
        "cardinal",
        "chaplain",
        "cmdr.",
        "cmsgt",
        "col.",
        "consul",
        "count",
        "countess",
        "cpl.",
        "cpo",
        "cwo",
        "dean",
        "duchess",
        "duke",
        "earl",
        "ens.",
        "eur eng",
        "father",
        "fr.",
        "gen.",
        "gov.",
        "h. e.",
        "herr",
        "hon",
        "hrh",
        "lady",
        "lord",
        "lt.",
        "lt. cmdr.",
        "lt. col.",
        "lt. gen.",
        "m.",
        "maj.",
        "maj. gen",
        "master",
        "mile.",
        "mme.",
        "mother",
        "msgt",
        "pastor",
        "pfc",
        "pres.",
        "prince",
        "princess",
        "prof.",
        "rabbi",
        "radm",
        "rev.",
        "rt. hon.",
        "senator",
        "sgt.",
        "sgt. maj.",
        "sir",
        "sister",
        "smsgt",
        "speaker",
        "squad. ldr.",
        "sr.",
        "sra",
        "sra",
        "srta",
        "ssgt",
        "swami",
        "stsgt"
    ]
    
    
    static var emailPrefixSeparator = [
        ".",
        "-",
        "_"
    ]
    static var addressNamesSuffix = [
        "floor",
        "CENTRE",
        "ALLEE",
        "ALLEY",
        "ALLY",
        "ALY",
        "ANEX",
        "ANNEX",
        "ANNX",
        "ANX",
        "ARC",
        "ARCADE",
        "AV.",
        "AV,",
        "AV",
        "AVE,",
        "AVE",
        "AVEN",
        "AVENU",
        "AVENUE",
        "AVENUE,",
        "AVN",
        "AVNUE",
        "BAYOO",
        "BAYOU",
        "BCH",
        "BEACH",
        "BEND",
        "BND",
        "BLDG.",
        "BLF",
        "BLUF",
        "BLUFF",
        "BLUFFS",
        "BOT",
        "BTM",
        "BOTTM",
        "BOTTOM",
        "BLVD",
        "BOUL",
        "BOULEVARD",
        "BOULV",
        "BR",
        "BRNCH",
        "BRANCH",
        "BRDGE",
        "BRG",
        "BRIDGE",
        "BRK",
        "BROOK",
        "BROOKS",
        "BURG",
        "BURGS",
        "BYP",
        "BYPA",
        "BYPAS",
        "BYPASS",
        "BYPS",
        "CAMP",
        "CEDEX",
        "CP",
        "CMP",
        "CANYN",
        "CANYON",
        "CNYN",
        "CAPE",
        "CPE",
        "CAUSEWAY",
        "CAUSWA",
        "CSWY",
        "CEN",
        "CENT",
        "CENTER",
        "CENTR",
        "CENTRE",
        "CNTER",
        "CNTR",
        "CTR",
        "CENTERS",
        "CIR",
        "CIRC",
        "CIRCL",
        "CIRCLE",
        "CRCL",
        "CRCLE",
        "CIRCLES",
        "CLF",
        "CLIFF",
        "CLFS",
        "CLIFFS",
        "CLB",
        "COMMON",
        "COMMONS",
        "COR",
        "CORNER",
        "CORNERS",
        "CORS",
        "COURSE",
        "CRSE",
        "COURT",
        "CT",
        "COURTS",
        "CTS",
        "COVE",
        "CV",
        "COVES",
        "CREEK",
        "CRK",
        "CRESCENT",
        "CRES",
        "CRSENT",
        "CRSNT",
        "CREST",
        "CROSSING",
        "CRSSNG",
        "XING",
        "CROSSROAD",
        "CROSSROADS",
        "CURVE",
        "DALE",
        "DL",
        "DAM",
        "DM",
        "DIV",
        "DIVIDE",
        "DV",
        "DVD",
        "DR",
        "DRIV",
        "DRIVE",
        "DRV",
        "DRIVES",
        "EST",
        "ESTATE",
        "ESTATES",
        "ESTS",
        "EXP",
        "EXPR",
        "EXPRESS",
        "EXPRESSWAY",
        "EXPW",
        "EXPY",
        "EXT",
        "EXTENSION",
        "EXTN",
        "EXTNSN",
        "EXTS",
        "FALL",
        "FALLS",
        "FLS",
        "FERRY",
        "FRRY",
        "FRY",
        "FIELD",
        "FLD",
        "FIELDS",
        "FLDS",
        "FLAT",
        "FLT",
        "FLATS",
        "FLTS",
        "FORD",
        "FRD",
        "FORDS",
        "FOREST",
        "FORESTS",
        "FRST",
        "FORG",
        "FORGE",
        "FRG",
        "FORGES",
        "FORK",
        "FRK",
        "FORKS",
        "FRKS",
        "FORT",
        "FRT",
        "FT",
        "FREEWAY",
        "FREEWY",
        "FRWAY",
        "FRWY",
        "FWY",
        "GARDEN",
        "GARDN",
        "GRDEN",
        "GRDN",
        "GARDENS",
        "GDNS",
        "GRDNS",
        "GATEWAY",
        "GATEWY",
        "GATWAY",
        "GTWAY",
        "GTWY",
        "GLEN",
        "GLN",
        "GLENS",
        "GREEN",
        "GRN",
        "GREENS",
        "GROV",
        "GROVE",
        "GRV",
        "GROVES",
        "HARB",
        "HARBOR",
        "HARBR",
        "HBR",
        "HRBOR",
        "HARBORS",
        "HAVEN",
        "HVN",
        "HT",
        "HTS",
        "HIGHWAY",
        "HIGHWY",
        "HIWAY",
        "HIWY",
        "HWAY",
        "HWY",
        "HILL",
        "HL",
        "HILLS",
        "HLS",
        "HLLW",
        "HOLLOW",
        "HOLLOWS",
        "HOLW",
        "HOLWS",
        "IMM",
        "IMM.",
        "IMMEUBLE",
        "INLT",
        "IS",
        "ISLAND",
        "ISLND",
        "ISLANDS",
        "ISLNDS",
        "ISS",
        "ISLE",
        "ISLES",
        "JCT",
        "JCTION",
        "JCTN",
        "JUNCTION",
        "JUNCTN",
        "JUNCTON",
        "JCTNS",
        "JCTS",
        "JUNCTIONS",
        "KEY",
        "KY",
        "KEYS",
        "KYS",
        "KM",
        "KNL",
        "KNOL",
        "KNOLL",
        "KNLS",
        "KNOLLS",
        "LK",
        "LAKE",
        "LKS",
        "LAKES",
        "LAND",
        "LANDING",
        "LNDG",
        "LNDNG",
        "LANE",
        "LN",
        "LGT",
        "LIGHT",
        "LIGHTS",
        "LF",
        "LOAF",
        "LCK",
        "LOCK",
        "LCKS",
        "LOCKS",
        "LDG",
        "LDGE",
        "LODG",
        "LODGE",
        "LOOP",
        "LOOPS",
        "MALL",
        "MNR",
        "MANOR",
        "MANORS",
        "MNRS",
        "MEADOW",
        "MDW",
        "MDWS",
        "MEADOWS",
        "MEDOWS",
        "MEWS",
        "MILL",
        "MILLS",
        "MISSN",
        "MSSN",
        "MOTORWAY",
        "MNT",
        "MT",
        "MOUNT",
        "MNTAIN",
        "MNTN",
        "MOUNTAIN",
        "MOUNTIN",
        "MTIN",
        "MTN",
        "MNTNS",
        "MOUNTAINS",
        "NCK",
        "NECK",
        "ORCH",
        "ORCHARD",
        "ORCHRD",
        "OVAL",
        "OVL",
        "OVERPASS",
        "PARK",
        "PRK",
        "PARKS",
        "PARKWAY",
        "PARKWY",
        "PKWAY",
        "PKWY",
        "PKY",
        "PARKWAYS",
        "PKWYS",
        "PASS",
        "PASSAGE",
        "PATH",
        "PATHS",
        "PIKE",
        "PIKES",
        "PINE",
        "PINES",
        "PNES",
        "PL",
        "PLACE",
        "PLAIN",
        "PLN",
        "PLAINS",
        "PLNS",
        "PLAZA",
        "PLZ",
        "PLZA",
        "POINT",
        "PT",
        "POINTS",
        "PTS",
        "PORT",
        "PRT",
        "PORTS",
        "PRTS",
        "PR",
        "PRAIRIE",
        "PRR",
        "RAD",
        "RADIAL",
        "RADIEL",
        "RADL",
        "RAMP",
        "RANCH",
        "RANCHES",
        "RNCH",
        "RNCHS",
        "RAPID",
        "RPD",
        "RAPIDS",
        "RPDS",
        "REST",
        "RST",
        "RDG",
        "RDGE",
        "RIDGE",
        "RDGS",
        "RIDGES",
        "RIV",
        "RIVER",
        "RVR",
        "RIVR",
        "RD",
        "ROAD",
        "ROADS",
        "RDS",
        "ROUTE",
        "ROW",
        "RUE",
        "RUN",
        "SHL",
        "SHOAL",
        "SHLS",
        "SHOALS",
        "SHOAR",
        "SHORE",
        "SHR",
        "SHOARS",
        "SHORES",
        "SHRS",
        "SKYWAY",
        "SPG",
        "SPNG",
        "SPRING",
        "SPRNG",
        "SPGS",
        "SPNGS",
        "SPRINGS",
        "SPRNGS",
        "SPUR",
        "SPURS",
        "SQ",
        "SQR",
        "SQRE",
        "SQU",
        "SQUARE",
        "SQRS",
        "SQUARES",
        "STA",
        "STATION",
        "STATN",
        "STN",
        "STRA",
        "STRAV",
        "STRAVEN",
        "STRAVENUE",
        "STRAVN",
        "STRVN",
        "STRVNUE",
        "STREAM",
        "STREME",
        "STRM",
        "STREET",
        "STRT",
        "ST",
        "STR",
        "STREETS",
        "SMT",
        "SUMIT",
        "SUMITT",
        "SUMMIT",
        "TER",
        "TERR",
        "TERRACE",
        "THROUGHWAY",
        "TRACE",
        "TRACES",
        "TRCE",
        "TRACK",
        "TRACKS",
        "TRAK",
        "TRK",
        "TRKS",
        "TRAFFICWAY",
        "TRAIL",
        "TRAILS",
        "TRL",
        "TRLS",
        "TRAILER",
        "TRLR",
        "TRLRS",
        "TUNEL",
        "TUNL",
        "TUNLS",
        "TUNNEL",
        "TUNNELS",
        "TUNNL",
        "TRNPK",
        "TURNPIKE",
        "TURNPK",
        "UNDERPASS",
        "UN",
        "UNION",
        "UNIONS",
        "VALLEY",
        "VALLY",
        "VLLY",
        "VLY",
        "VALLEYS",
        "VLYS",
        "VDCT",
        "VIA",
        "VIADCT",
        "VIADUCT",
        "VIEW",
        "VW",
        "VIEWS",
        "VWS",
        "VILL",
        "VILLAG",
        "VILLAGE",
        "VILLG",
        "VILLIAGE",
        "VLG",
        "VILLAGES",
        "VLGS",
        "VILLE",
        "VL",
        "VIS",
        "VIST",
        "VISTA",
        "VST",
        "VSTA",
        "WALK",
        "WALKS",
        "WALL",
        "WY",
        "WAY",
        "WAYS",
        "WELL",
        "WELLS",
        "WLS",
    ]
    
    static var emailPrefixes = [
        "sales",
        "info",
        "enquiries",
        "admin",
        "mail",
        "office",
        "head",
        "headteacher",
        "reception",
        "enquiry",
        "marketing",
        "post",
        "contact",
        "email",
        "accounts",
        "london",
        "general",
        "postmaster",
        "enquires",
        "design",
        "support",
        "mailbox",
        "law",
        "service",
        "reservations",
        "information",
        "schooladmin",
        "secretary",
        "pr",
        "enq",
        "advice",
        "webmaster",
        "studio",
        "bristol",
        "headoffice",
        "bookings",
        "help",
        "jobs",
        "manager",
        "property",
        "helpdesk",
        "clerks",
        "bursar",
        "recruit",
        "manchester",
        "enquries",
        "postbox",
        "contactus",
        "administrator",
        "editor",
        "enquire",
        "all",
        "recruitment",
        "insurance",
        "md",
        "hq",
        "schooloffice",
        "services",
        "customerservice",
        "birmingham",
        "print",
        "hire",
        "headmaster",
        "architects",
        "admissions",
        "events",
        "it",
        "solicitors",
        "lawyers",
        "uk",
        "training",
        "lettings",
        "info.uk",
        "Director",
        "adminoffice",
        "production",
        "business",
        "contracts",
        "finance",
        "orders",
        "news",
        "solutions",
        "customerservices",
        "partners",
        "hello",
        "cardiff",
        "leeds",
        "school",
        "team",
        "ask",
        "accountants",
        "consult",
        "operations",
        "holidays",
        "inquiries",
        "hotel",
        "edinburgh",
        "editorial",
        "commercial",
        "nottingham",
        "action",
        "group",
        "swindon",
        "customer.services",
        "hr",
        "insure",
        "norwich",
        "care",
        "shop",
        "travel",
        "feedback",
        "uksales",
        "legal",
        "PRINCIPAL",
        "engineers",
        "traffic",
        "mailroom",
        "registrar",
        "parts",
        "ops",
        "stay",
        "advertising",
        "sales.uk",
        "glasgow",
        "administration",
        "conferences",
        "clerk",
        "central",
        "personnel",
        "aberdeen",
        "hostmaster",
        "liverpool",
        "exeter",
        "careers",
        "properties",
        "ukinfo",
        "purchasing",
        "agency",
        "architect",
        "bradford",
        "conference",
        "projects",
        "salesuk",
        "sale",
        "main",
        "oxford",
        "systems",
        "management",
        "leicester",
        "art",
        "ideas",
        "me",
        "welcome",
        "furniture",
        "postroom",
        "enqs",
        "press",
        "chambers",
        "quality",
        "export",
        "connect",
        "inquires",
        "hull",
        "dundee",
        "inbox",
        "plymouth",
        "people",
        "croydon",
        "europe",
        "online",
        "midlands",
        "staff",
        "books",
        "coventry",
        "construction",
        "e-mail",
        "info-uk",
        "graphics",
        "theteam",
        "library",
        "invest",
        "newcastle",
        "technical",
        "NOEMAIL",
        "NOMAIL",
        "noemailadress",
        "leisure",
        "surveys",
        "tech",
        "edit",
        "tourism",
        "office.admin",
        "rental",
        "arts",
        "details",
        "trust",
        "townhall",
        "customercare",
        "sales-uk",
        "delivery",
        "NOEMAIL",
        "NOMAIL",
        "noemailadress",
        "leisure",
        "surveys",
        "tech",
        "edit",
        "tourism",
        "office.admin",
        "rental",
        "arts",
        "details",
        "trust",
        "townhall",
        "customercare",
        "sales-uk",
        "delivery",
        "townclerk",
        "kontakt",
        "bicester",
        "abingdon",
        "commerciale",
        "amministrazione",
        "comercial",
        "auctions",
        "auction",
        "web",
        "technik",
        "trade",
        "trading",
        "infos",
        "occasion",
        "helpline",
        "chairman",
        "surveying",
        "planning",
        "corporate",
        "home",
        "informatique",
        "master",
        "root",
        "club",
        "shipping",
        "used",
        "treasurer",
        "security",
        "sport",
        "architecture",
        "reservation",
        "media",
        "development",
        "president",
        "hiredesk",
        "repairs",
        "franchise",
        "boss",
        "technique",
        "freight",
        "Equipment",
        "membership",
        "estate",
        "hospitality",
        "infodesk",
        "general.enquiries",
        "server",
        "member",
        "uk-info",
        "bury",
        "institute",
        "analysis",
        "INFORMATICA",
        "vets",
        "users",
        "generalenquiries",
        "schoolmail",
        "admin.office",
        "learning",
        "producer",
        "farmer",
        "officeadmin",
        "education",
        "supervisor",
        "schoolinfo",
        "contact.us",
        "school.office",
        "webadmin",
        "mainoffice",
        "academy",
        "frontdesk",
        "euroinfo",
        "procurement",
        "salesinfo",
        "academic.administrator",
        "assistant",
        "theoffice",
        "genoffice",
        "webmail",
        "main.office",
        "gen.enquiries",
        "ceo",
        "cto"
    ]
    static var namesPrefixes = [
        "Mr.",
        "Mrs.",
        "Ms.",
        "Miss",
        "Dr.",
        "Dr",
        "A.V.M",
        "Adm.",
        "Amb",
        "AMN",
        "Archbishop",
        "Baron",
        "Baroness",
        "Bishop",
        "Brig. Gen.",
        "Bigadier",
        "Bro.",
        "Cantor",
        "Capt.",
        "Cardinal",
        "Chaplain",
        "Cmdr.",
        "CMSGT",
        "Col.",
        "Consul",
        "Count",
        "Countess",
        "Cpl.",
        "CPO",
        "CWO",
        "Dean",
        "Duchess",
        "Duke",
        "Earl",
        "Ens.",
        "Eur Eng",
        "Father",
        "Fr.",
        "Gen.",
        "Gov.",
        "H. E.",
        "Herr",
        "Hon",
        "HRH",
        "Lady",
        "Lord",
        "Lt.",
        "Lt. Cmdr.",
        "Lt. Col.",
        "Lt. Gen.",
        "M.",
        "Maj.",
        "Maj. Gen",
        "Master",
        "Mile.",
        "Mme.",
        "Mother",
        "MSGT",
        "Pastor",
        "PFC",
        "Pres.",
        "Prince",
        "Princess",
        "Prof.",
        "Rabbi",
        "Radm",
        "Rev.",
        "Rt. Hon.",
        "Senator",
        "Sgt.",
        "Sgt. Maj.",
        "Sir",
        "Sister",
        "SMSGT",
        "Speaker",
        "Squad. Ldr.",
        "Sr.",
        "SrA",
        "Sra",
        "Srta",
        "SSGT",
        "Swami",
        "STSGT"
    ]
    /// Country Phone prefix helper
    static var countryPhonePrefix = [
        
        CountryPhonePrefix(countryPrefix:"AF", phonePrefix: "93", countryName: "Afghanistan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AL", phonePrefix: "355", countryName: "Albania",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"DZ", phonePrefix: "213", countryName: "Algeria",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AS", phonePrefix: "1684", countryName: "American Samoa",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AD", phonePrefix: "376", countryName: "Andorra",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AO", phonePrefix: "244", countryName: "Angola",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AI", phonePrefix: "1264", countryName: "Anguilla",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AQ", phonePrefix: "672", countryName: "Antarctica",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AG", phonePrefix: "1268", countryName: "Antigua and Barbuda",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AR", phonePrefix: "54", countryName: "Argentina",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AM", phonePrefix: "374", countryName: "Armenia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AW", phonePrefix: "297", countryName: "Aruba",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AU", phonePrefix: "61", countryName: "Australian",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AT", phonePrefix: "43", countryName: "Austria",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AZ", phonePrefix: "994", countryName: "Azerbaijan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BS", phonePrefix: "1242", countryName: "Bahamas",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BH", phonePrefix: "973", countryName: "Bahrain",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BD", phonePrefix: "880", countryName: "Bangladesh",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BB", phonePrefix: "246", countryName: "Barbados",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BY", phonePrefix: "375", countryName: "Belarus",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BE", phonePrefix: "32", countryName: "Belgium",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BZ", phonePrefix: "501", countryName: "Belize",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BJ", phonePrefix: "229", countryName: "Benin",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BM", phonePrefix: "1441", countryName: "Bermuda",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BT", phonePrefix: "975", countryName: "Bhutan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BA", phonePrefix: "387", countryName: "Bosnia and Herzegovina",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BW", phonePrefix: "267", countryName: "Botswana",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BR", phonePrefix: "55", countryName: "Brazil",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BG", phonePrefix: "359", countryName: "Bulgaria",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BF", phonePrefix: "226", countryName: "Burkina Faso",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BI", phonePrefix: "257", countryName: "Burundi",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KH", phonePrefix: "855", countryName: "Cambodia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CM", phonePrefix: "237", countryName: "Cameroon",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CA", phonePrefix: "1", countryName: "Canada",zipREX: "[ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJ-NPRSTV-Z][ ]?\\d[ABCEGHJ-NPRSTV-Z]\\d"),
        CountryPhonePrefix(countryPrefix:"CV", phonePrefix: "238", countryName: "Cape Verde",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KY", phonePrefix: "345", countryName: "Cayman Islands",zipREX: "KY[1-3, Ii][\\s\\S]\\d{4}"),
        CountryPhonePrefix(countryPrefix:"CF", phonePrefix: "236", countryName: "Central African Republic",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TD", phonePrefix: "235", countryName: "Chad",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CL", phonePrefix: "56", countryName: "Chile",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CN", phonePrefix: "86", countryName: "China",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CX", phonePrefix: "61", countryName: "Christmas Island",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CO", phonePrefix: "57", countryName: "Colombia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KM", phonePrefix: "269", countryName: "Comoros",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CG", phonePrefix: "242", countryName: "Republic of the Congo",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CK", phonePrefix: "682", countryName: "Cook Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CR", phonePrefix: "506", countryName: "Costa Rica",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"HR", phonePrefix: "385", countryName: "Croatia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CU", phonePrefix: "53", countryName: "Cuba",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CY", phonePrefix: "537", countryName: "Cyprus",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CZ", phonePrefix: "420", countryName: "Czech Republic",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"DK", phonePrefix: "45", countryName: "Denmark",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"DJ", phonePrefix: "253", countryName: "Djibouti",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"DM", phonePrefix: "1767", countryName: "Dominica",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"DO", phonePrefix: "1", countryName: "Dominican Republic",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"EC", phonePrefix: "593", countryName: "Ecuador",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"EG", phonePrefix: "20", countryName: "Egypt",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SV", phonePrefix: "503", countryName: "El Salvador",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GQ", phonePrefix: "240", countryName: "Equatorial Guinea",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ER", phonePrefix: "291", countryName: "Eritrea",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"EE", phonePrefix: "372", countryName: "Estonia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ET", phonePrefix: "251", countryName: "Ethiopia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"FO", phonePrefix: "298", countryName: "The Faroe Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"FJ", phonePrefix: "679", countryName: "Fiji",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"FI", phonePrefix: "358", countryName: "Finland",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"FR", phonePrefix: "33", countryName: "France",zipREX: "\\d{2}[ ]?\\d{3}"),
        CountryPhonePrefix(countryPrefix:"GF", phonePrefix: "594", countryName: "French Guiana",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PF", phonePrefix: "689", countryName: "French Polynesia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GA", phonePrefix: "241", countryName: "Gabon",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GM", phonePrefix: "220", countryName: "Gambia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GE", phonePrefix: "995", countryName: "Georgia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"DE", phonePrefix: "49", countryName: "Germany",zipREX: "\\d{5}"),
        CountryPhonePrefix(countryPrefix:"GH", phonePrefix: "233", countryName: "Ghana",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GI", phonePrefix: "350", countryName: "Gibraltar",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GR", phonePrefix: "30", countryName: "Greece",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GL", phonePrefix: "299", countryName: "Greenland",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GD", phonePrefix: "1473", countryName: "Grenada",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GP", phonePrefix: "590", countryName: "Saint Barthelemy",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GU", phonePrefix: "1671", countryName: "Guam",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GT", phonePrefix: "502", countryName: "Guatemala",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GN", phonePrefix: "224", countryName: "Guinea",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GW", phonePrefix: "245", countryName: "Guinea-Bissau",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GY", phonePrefix: "595", countryName: "Paraguay",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"HT", phonePrefix: "509", countryName: "Haiti",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"HN", phonePrefix: "504", countryName: "Honduras",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"HU", phonePrefix: "36", countryName: "Hungary",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IS", phonePrefix: "354", countryName: "Iceland",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IN", phonePrefix: "91", countryName: "India",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ID", phonePrefix: "62", countryName: "Indonesia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IQ", phonePrefix: "964", countryName: "Iraq",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IE", phonePrefix: "353", countryName: "Ireland",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IL", phonePrefix: "972", countryName: "Israel",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IT", phonePrefix: "39", countryName: "Italy",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"JM", phonePrefix: "1876", countryName: "Jamaica",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"JP", phonePrefix: "81", countryName: "Japan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"JO", phonePrefix: "962", countryName: "Jordan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KZ", phonePrefix: "77", countryName: "Kazakhstan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KE", phonePrefix: "254", countryName: "Kenya",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KI", phonePrefix: "686", countryName: "Kiribati",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KW", phonePrefix: "965", countryName: "Kuwait",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KG", phonePrefix: "996", countryName: "Kyrgyzstan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LV", phonePrefix: "371", countryName: "Latvia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LB", phonePrefix: "961", countryName: "Lebanon",zipREX: "(\\d{4}([ ]?\\d{4})?)?"),
        CountryPhonePrefix(countryPrefix:"LS", phonePrefix: "266", countryName: "Lesotho",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LR", phonePrefix: "231", countryName: "Liberia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LI", phonePrefix: "423", countryName: "Liechtenstein",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LT", phonePrefix: "370", countryName: "Lithuania",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LU", phonePrefix: "352", countryName: "Luxembourg",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MG", phonePrefix: "261", countryName: "Madagascar",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MW", phonePrefix: "265", countryName: "Malawi",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MY", phonePrefix: "60", countryName: "Malaysia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MV", phonePrefix: "960", countryName: "Maldives",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ML", phonePrefix: "223", countryName: "Mali",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MT", phonePrefix: "356", countryName: "Malta",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MH", phonePrefix: "692", countryName: "Marshall Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MQ", phonePrefix: "596", countryName: "Martinique",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MR", phonePrefix: "222", countryName: "Mauritania",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MU", phonePrefix: "230", countryName: "Mauritius",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MX", phonePrefix: "52", countryName: "Mexico",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MC", phonePrefix: "377", countryName: "Monaco",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MN", phonePrefix: "976", countryName: "Mongolia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ME", phonePrefix: "382", countryName: "Montenegro",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MS", phonePrefix: "1664", countryName: "Montserrat",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MA", phonePrefix: "212", countryName: "Morocco",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MM", phonePrefix: "95", countryName: "Myanmar",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NA", phonePrefix: "264", countryName: "Namibia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NR", phonePrefix: "674", countryName: "Nauru",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NP", phonePrefix: "977", countryName: "Nepal",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NL", phonePrefix: "31", countryName: "Netherlands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AN", phonePrefix: "599", countryName: "Netherlands Antilles",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NC", phonePrefix: "687", countryName: "New Caledonia",zipREX: "988\\d{2}"),
        CountryPhonePrefix(countryPrefix:"NZ", phonePrefix: "64", countryName: "New Zealand",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NI", phonePrefix: "505", countryName: "Nicaragua",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NE", phonePrefix: "227", countryName: "Niger",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NG", phonePrefix: "234", countryName: "Nigeria",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NU", phonePrefix: "683", countryName: "Niue",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NF", phonePrefix: "672", countryName: "Norfolk Island",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MP", phonePrefix: "1670", countryName: "Northern Mariana Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"NO", phonePrefix: "47", countryName: "Norway",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"OM", phonePrefix: "968", countryName: "Oman",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PK", phonePrefix: "92", countryName: "Pakistan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PW", phonePrefix: "680", countryName: "Palau",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PA", phonePrefix: "507", countryName: "Panama",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PG", phonePrefix: "675", countryName: "Papua New Guinea",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PY", phonePrefix: "595", countryName: "Paraguay",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PE", phonePrefix: "51", countryName: "Peru",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PH", phonePrefix: "63", countryName: "Philippines",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PL", phonePrefix: "48", countryName: "Poland",zipREX: "\\d{2}-\\d{3}"),
        CountryPhonePrefix(countryPrefix:"PT", phonePrefix: "351", countryName: "Portugal",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PR", phonePrefix: "1787", countryName: "Puerto Rico",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"QA", phonePrefix: "974", countryName: "Qatar",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"RO", phonePrefix: "40", countryName: "Romania",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"RW", phonePrefix: "250", countryName: "Rwanda",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"WS", phonePrefix: "685", countryName: "Samoa",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SM", phonePrefix: "378", countryName: "San Marino",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SA", phonePrefix: "966", countryName: "Saudi Arabia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SN", phonePrefix: "221", countryName: "Senegal",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"RS", phonePrefix: "381", countryName: "Serbia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SC", phonePrefix: "248", countryName: "Seychelles",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SL", phonePrefix: "232", countryName: "Sierra Leone",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SG", phonePrefix: "65", countryName: "Singapore",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SK", phonePrefix: "421", countryName: "Slovakia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SI", phonePrefix: "386", countryName: "Slovenia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SB", phonePrefix: "677", countryName: "Solomon Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ZA", phonePrefix: "27", countryName: "South Africa",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"GS", phonePrefix: "500", countryName: "Falkland Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ES", phonePrefix: "34", countryName: "Spain",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LK", phonePrefix: "94", countryName: "Sri Lanka",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SD", phonePrefix: "249", countryName: "Sudan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SR", phonePrefix: "597", countryName: "Suriname",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SZ", phonePrefix: "268", countryName: "Swaziland",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SE", phonePrefix: "46", countryName: "Sweden",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CH", phonePrefix: "41", countryName: "Switzerland",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TJ", phonePrefix: "992", countryName: "Tajikistan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TH", phonePrefix: "66", countryName: "Thailand",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TG", phonePrefix: "228", countryName: "Togo",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TK", phonePrefix: "690", countryName: "Tokelau",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TO", phonePrefix: "676", countryName: "Tonga",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TT", phonePrefix: "1", countryName: "Trinidad and Tobago",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TN", phonePrefix: "216", countryName: "Tunisia",zipREX: "\\d{4}"),
        CountryPhonePrefix(countryPrefix:"TR", phonePrefix: "90", countryName: "Turkey",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TM", phonePrefix: "993", countryName: "Turkmenistan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TC", phonePrefix: "1649", countryName: "Turks and Caicos Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TV", phonePrefix: "688", countryName: "Tuvalu",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"UG", phonePrefix: "256", countryName: "Uganda",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"UA", phonePrefix: "380", countryName: "Ukraine",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"AE", phonePrefix: "971", countryName: "United Arab Emirates",zipREX: "\\d{5}"),
        CountryPhonePrefix(countryPrefix:"GB", phonePrefix: "44", countryName: "United Kingdom",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"US", phonePrefix: "1", countryName: "United States",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"UY", phonePrefix: "598", countryName: "Uruguay",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"UZ", phonePrefix: "998", countryName: "Uzbekistan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"VU", phonePrefix: "678", countryName: "Vanuatu",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"WF", phonePrefix: "681", countryName: "Wallis and Futuna",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"YE", phonePrefix: "967", countryName: "Yemen",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ZM", phonePrefix: "260", countryName: "Zambia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ZW", phonePrefix: "263", countryName: "Zimbabwe",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BO", phonePrefix: "591", countryName: "Bolivia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BN", phonePrefix: "673", countryName: "Brunei",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CD", phonePrefix: "243", countryName: "Democratic Republic of the Congo",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"CI", phonePrefix: "225", countryName: "Ivory Coast",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"VA", phonePrefix: "379", countryName: "Vatican",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"HK", phonePrefix: "852", countryName: "Hong Kong",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"IR", phonePrefix: "98", countryName: "Iran",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KP", phonePrefix: "850", countryName: "North Korea",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"KR", phonePrefix: "82", countryName: "South Korea",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LA", phonePrefix: "856", countryName: "Laos",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"LY", phonePrefix: "218", countryName: "Libya",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MO", phonePrefix: "853", countryName: "Macau",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MK", phonePrefix: "389", countryName: "Macedonia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"FM", phonePrefix: "691", countryName: "Micronesia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MD", phonePrefix: "373", countryName: "Moldova",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"MZ", phonePrefix: "258", countryName: "Mozambique",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PS", phonePrefix: "970", countryName: "Palestine",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PN", phonePrefix: "872", countryName: "Pitcairn Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"RE", phonePrefix: "262", countryName: "Reunion",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"RU", phonePrefix: "7", countryName: "Russia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"BL", phonePrefix: "590", countryName: "Saint Barthelemy",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SH", phonePrefix: "290", countryName: "Saint Helena",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"PM", phonePrefix: "508", countryName: "Saint Pierre and Miquelon",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"ST", phonePrefix: "239", countryName: "Sao Tome and Principe",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SO", phonePrefix: "252", countryName: "Somalia",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SJ", phonePrefix: "47", countryName: "Norway",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"SY", phonePrefix: "963", countryName: "Syria",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TW", phonePrefix: "886", countryName: "Taiwan",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TZ", phonePrefix: "255", countryName: "Tanzania",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"TL", phonePrefix: "670", countryName: "Northern Mariana Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"VE", phonePrefix: "58", countryName: "Venezuela",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"VN", phonePrefix: "84", countryName: "Vietnam",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"VG", phonePrefix: "284", countryName: "British Virgin Islands",zipREX: ""),
        CountryPhonePrefix(countryPrefix:"VI", phonePrefix: "340", countryName: "U.S. Virgin Islands",zipREX: ""),
        
    ]
    
    ///Zip Code REX helper
    static var pmZipCode = [
        CountryZip(countryPrefix: "GB", zipREX: "GIR[ ]?0AA|((AB|AL|B|BA|BB|BD|BH|BL|BN|BR|BS|BT|CA|CB|CF|CH|CM|CO|CR|CT|CV|CW|DA|DD|DE|DG|DH|DL|DN|DT|DY|E|EC|EH|EN|EX|FK|FY|G|GL|GY|GU|HA|HD|HG|HP|HR|HS|HU|HX|IG|IM|IP|IV|JE|KA|KT|KW|KY|L|LA|LD|LE|LL|LN|LS|LU|M|ME|MK|ML|N|NE|NG|NN|NP|NR|NW|OL|OX|PA|PE|PH|PL|PO|PR|RG|RH|RM|S|SA|SE|SG|SK|SL|SM|SN|SO|SP|SR|SS|ST|SW|SY|TA|TD|TF|TN|TQ|TR|TS|TW|UB|W|WA|WC|WD|WF|WN|WR|WS|WV|YO|ZE)(\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}))|BFPO[ ]?\\d{1),4}"),
        CountryZip(countryPrefix: "JE", zipREX: "JE\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}"),
        CountryZip(countryPrefix: "GG", zipREX: "GY\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}"),
        CountryZip(countryPrefix: "IM", zipREX: "IM\\d[\\dA-Z]?[ ]?\\d[ABD-HJLN-UW-Z]{2}"),
        CountryZip(countryPrefix: "US", zipREX: "\\d{5}([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "CA", zipREX: "[ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJ-NPRSTV-Z][ ]?\\d[ABCEGHJ-NPRSTV-Z]\\d"),
        CountryZip(countryPrefix: "DE", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "JP", zipREX: "\\d{3}-\\d{4}"),
        CountryZip(countryPrefix: "FR", zipREX: "\\d{2}[ ]?\\d{3}"),
        CountryZip(countryPrefix: "AU", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "IT", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "CH", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "AT", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "ES", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "NL", zipREX: "\\d{4}[ ]?[A-Z]{2}"),
        CountryZip(countryPrefix: "BE", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "DK", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "SE", zipREX: "\\d{3}[ ]?\\d{2}"),
        CountryZip(countryPrefix: "NO", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "BR", zipREX: "\\d{5}[\\-]?\\d{3}"),
        CountryZip(countryPrefix: "PT", zipREX: "\\d{4}([\\-]\\d{3})?"),
        CountryZip(countryPrefix: "FI", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "AX", zipREX: "22\\d{3}"),
        CountryZip(countryPrefix: "KR", zipREX: "\\d{3}[\\-]\\d{3}"),
        CountryZip(countryPrefix: "KY", zipREX: "KY[1-3]-\\d{4}"),
        CountryZip(countryPrefix: "CN", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "TW", zipREX: "\\d{3}(\\d{2})?"),
        CountryZip(countryPrefix: "SG", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "DZ", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "AD", zipREX: "AD\\d{3}"),
        CountryZip(countryPrefix: "AR", zipREX: "([A-HJ-NP-Z])?\\d{4}([A-Z]{3})?"),
        CountryZip(countryPrefix: "AM", zipREX: "(37)?\\d{4}"),
        CountryZip(countryPrefix: "AZ", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "BH", zipREX: "((1[0-2]|[2-9])\\d{2})?"),
        CountryZip(countryPrefix: "BD", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "BB", zipREX: "(BB\\d{5})?"),
        CountryZip(countryPrefix: "BY", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "BM", zipREX: "[A-Z]{2}[ ]?[A-Z0-9]{2}"),
        CountryZip(countryPrefix: "BA", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "IO", zipREX: "BBND 1ZZ"),
        CountryZip(countryPrefix: "BN", zipREX: "[A-Z]{2}[ ]?\\d{4}"),
        CountryZip(countryPrefix: "BG", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "KH", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "CV", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "CL", zipREX: "\\d{7}"),
        CountryZip(countryPrefix: "CR", zipREX: "\\d{4),5}|\\d{3}-\\d{4}"),
        CountryZip(countryPrefix: "HR", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "CY", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "CZ", zipREX: "\\d{3}[ ]?\\d{2}"),
        CountryZip(countryPrefix: "DO", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "EC", zipREX: "([A-Z]\\d{4}[A-Z]|(?:[A-Z]{2})?\\d{6})?"),
        CountryZip(countryPrefix: "EG", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "EE", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "FO", zipREX: "\\d{3}"),
        CountryZip(countryPrefix: "GE", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "GR", zipREX: "\\d{3}[ ]?\\d{2}"),
        CountryZip(countryPrefix: "GL", zipREX: "39\\d{2}"),
        CountryZip(countryPrefix: "GT", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "HT", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "HN", zipREX: "(?:\\d{5})?"),
        CountryZip(countryPrefix: "HU", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "IS", zipREX: "\\d{3}"),
        CountryZip(countryPrefix: "IN", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "ID", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "AE", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "IL", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "JO", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "KZ", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "KE", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "KW", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "LA", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "LV", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "LB", zipREX: "(\\d{4}([ ]?\\d{4})?)?"),
        CountryZip(countryPrefix: "LI", zipREX: "(948[5-9])|(949[0-7])"),
        CountryZip(countryPrefix: "LT", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "LU", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "MK", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "MY", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "MV", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "MT", zipREX: "[A-Z]{3}[ ]?\\d{2),4}"),
        CountryZip(countryPrefix: "MU", zipREX: "(\\d{3}[A-Z]{2}\\d{3})?"),
        CountryZip(countryPrefix: "MX", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "MD", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "MC", zipREX: "980\\d{2}"),
        CountryZip(countryPrefix: "MA", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "NP", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "NZ", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "NI", zipREX: "((\\d{4}-)?\\d{3}-\\d{3}(-\\d{1})?)?"),
        CountryZip(countryPrefix: "NG", zipREX: "(\\d{6})?"),
        CountryZip(countryPrefix: "OM", zipREX: "(PC )?\\d{3}"),
        CountryZip(countryPrefix: "PK", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "PY", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "PH", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "PL", zipREX: "\\d{2}-\\d{3}"),
        CountryZip(countryPrefix: "PR", zipREX: "00[679]\\d{2}([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "RO", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "RU", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "SM", zipREX: "4789\\d"),
        CountryZip(countryPrefix: "SA", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "SN", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "SK", zipREX: "\\d{3}[ ]?\\d{2}"),
        CountryZip(countryPrefix: "SI", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "ZA", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "LK", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "TJ", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "TH", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "TN", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "TR", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "TM", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "UA", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "UY", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "UZ", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "VA", zipREX: "00120"),
        CountryZip(countryPrefix: "VE", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "ZM", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "AS", zipREX: "96799"),
        CountryZip(countryPrefix: "CC", zipREX: "6799"),
        CountryZip(countryPrefix: "CK", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "RS", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "ME", zipREX: "8\\d{4}"),
        CountryZip(countryPrefix: "CS", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "YU", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "CX", zipREX: "6798"),
        CountryZip(countryPrefix: "ET", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "FK", zipREX: "FIQQ 1ZZ"),
        CountryZip(countryPrefix: "NF", zipREX: "2899"),
        CountryZip(countryPrefix: "FM", zipREX: "(9694[1-4])([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "GF", zipREX: "9[78]3\\d{2}"),
        CountryZip(countryPrefix: "GN", zipREX: "\\d{3}"),
        CountryZip(countryPrefix: "GP", zipREX: "9[78][01]\\d{2}"),
        CountryZip(countryPrefix: "GS", zipREX: "SIQQ 1ZZ"),
        CountryZip(countryPrefix: "GU", zipREX: "969[123]\\d([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "GW", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "HM", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "IQ", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "KG", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "LR", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "LS", zipREX: "\\d{3}"),
        CountryZip(countryPrefix: "MG", zipREX: "\\d{3}"),
        CountryZip(countryPrefix: "MH", zipREX: "969[67]\\d([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "MN", zipREX: "\\d{6}"),
        CountryZip(countryPrefix: "MP", zipREX: "9695[012]([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "MQ", zipREX: "9[78]2\\d{2}"),
        CountryZip(countryPrefix: "NC", zipREX: "988\\d{2}"),
        CountryZip(countryPrefix: "NE", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "VI", zipREX: "008(([0-4]\\d)|(5[01]))([ \\-]\\d{4})?"),
        CountryZip(countryPrefix: "PF", zipREX: "987\\d{2}"),
        CountryZip(countryPrefix: "PG", zipREX: "\\d{3}"),
        CountryZip(countryPrefix: "PM", zipREX: "9[78]5\\d{2}"),
        CountryZip(countryPrefix: "PN", zipREX: "PCRN 1ZZ"),
        CountryZip(countryPrefix: "PW", zipREX: "96940"),
        CountryZip(countryPrefix: "RE", zipREX: "9[78]4\\d{2}"),
        CountryZip(countryPrefix: "SH", zipREX: "(ASCN|STHL) 1ZZ"),
        CountryZip(countryPrefix: "SJ", zipREX: "\\d{4}"),
        CountryZip(countryPrefix: "SO", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "SZ", zipREX: "[HLMS]\\d{3}"),
        CountryZip(countryPrefix: "TC", zipREX: "TKCA 1ZZ"),
        CountryZip(countryPrefix: "WF", zipREX: "986\\d{2}"),
        CountryZip(countryPrefix: "XK", zipREX: "\\d{5}"),
        CountryZip(countryPrefix: "YT", zipREX: "976\\d{2}"),
    ]
    
    
    
    static var statesWithPrefix : [String] = []
    static var citiesWithPrefix : [String] = []
    
    static var countriesWithCities : [CountriesWithCities] = []
    static var countriesWithStates : [CountriesWithCities] = []
    static var phonePrefixs : [PhonePrefixes]?
    static var countries : [Countries]?
    static var titles : [titlesPM]?
    static let websiteHeaders = [
        "http:",
        "www.",
        "http://",
        "https://"
    ]
    
    
}


struct Response<V: Codable>: Codable {
    let success: NestedResponse<V>
}

struct NestedResponse<T: Codable>: Codable {
    let statusCode: Int?
    let message, code: String?
    let data: T?
    
}
