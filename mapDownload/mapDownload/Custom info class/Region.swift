//
//  Data.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 29.10.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import Foundation
import UIKit



//класс региона
class Region : CustomStringConvertible, Identifiable, ObservableObject  {
   
    
    
    var description: String {
        return "name: \(name) subregion: \(subRegions)"
    }
    
    var subRegions: [Region] = []
    var name: String = ""
    var level: Int = 0
    var parentRegion: String = ""
    var data: Data = Data()
    var url: String = ""
    var onDevice: Bool = false
    
}

//регионы, с файла
class RegionsData: ObservableObject {
    @Published var regions: [Region] = []
    
    init() {
        var inRegions: [Region] = []
        do{
            if let xmlUrl = Bundle.main.url(forResource: "regions", withExtension: "xml") {
                let xml = try String(contentsOf: xmlUrl)
                let regionParser = Parser(withXML: xml)
                let regions = regionParser.parse()
                inRegions = stackRegion(regions: regions, gLevel: 0, start: 0, parent: Region()).reg
                            
            }
        } catch {
            print(error)
        }
        self.regions = inRegions
    }
}



