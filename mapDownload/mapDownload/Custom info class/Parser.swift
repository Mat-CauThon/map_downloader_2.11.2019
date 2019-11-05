//
//  Parser.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 05.11.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import Foundation


class Parser: NSObject {
    var xmlParser: XMLParser?
    var regions: [Region] = []
    var xmlText = ""
    var currentRegion: Region?
    var level: Int = 0 //тип региона
    var checker: String = "" //проверка для перехода с уровня на уровень
    init(withXML xml: String) {
        if let data = xml.data(using: String.Encoding.utf8) {
            xmlParser = XMLParser(data: data)
        }
    }
    func parse() -> [Region] {
        xmlParser?.delegate = self
        xmlParser?.parse()
        return regions
    }
}



extension Parser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        xmlText = ""
        if elementName == "region" {
        
            currentRegion = Region()
            
            
            currentRegion?.name = attributeDict["name"]!.firstUppercased
            
            let regionSubType = attributeDict["inner_download_prefix"] ?? ""
            let regionGlobalType = attributeDict["inner_download_suffix"] ?? ""
            
            
            if regionSubType != "" { //нужно для глобальных регионов с префиксами
                level += 1
                if let region = currentRegion {
                    region.level = level-1
                   // print(region.name)
                    regions.append(region)
                  
                }
            } else if regionGlobalType != "" { //нужно для глобальных регионов с суффиксами
                level += 1
                if let region = currentRegion {
                    region.level = level-1
                    regions.append(region)
                  
                }
            } else {
                if let region = currentRegion {
                    region.level = level
                    regions.append(region)
                  
                }
            }
            
        }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "region" {

// тут можно понять вышли ли мы из под региона (тк в currentRegion находится под регион, то при закрытии этого региона, в checker будет имя этого региона, но тогда при закрытии супер региона currentRegion не изменится, то можно сменить уровень регионов на котором мы работаем
            if checker != currentRegion?.name {
                checker = currentRegion!.name
            } else {
                level -= 1
            }
            
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        xmlText += string
    }
}


//тут я распихиваю все регионы в подрегионы. Получается в обьекте класса регион есть коллекция с его под-регионами
//на вход у меня подается список всех регионов с их уровнем (Европа - 0, Страна - 1, Регион - 2, область -3 итд)
//все регионы, что находяться между регионами с одинаковым индексом (например Черниговская область с индексом 2 находится между региона Украина и Беларусь с индексами 1) относятся к "верхнему региону" (Черниговская область относится к Украине)
//
// Список регинов из примера:
// Украина
// Черниговская область
// Беларусь
func stackRegion(regions: [Region], gLevel: Int, start: Int, parent: Region) -> (reg: [Region], cont: Int) {
    var level = gLevel
    var reg: [Region] = []
    var k = 0
    var i = start
    //for i in start...regions.count-1
    while i < regions.count-1 {
        
        if regions[i].level > level {
            
            level += 1
            let stack = stackRegion(regions: regions, gLevel: level, start: i, parent: regions[i-1])
            reg.last!.subRegions = stack.reg.sorted(by: { (a, b) -> Bool in
                return a.name < b.name
            })
            i = stack.cont
            k+=1
            level -= 1
            
        } else if regions[i].level == level {
            
            reg.append(regions[i])
            let parentURL = parent.url.lowercased()
            
            if level == 0 {
                reg.last?.url = "http://download.osmand.net/download.php?standard=yes&file=" + (reg.last?.name.firstUppercased)! + "_2.obf.zip"
            }
            else if level == 1 {
                let parentUrlParam = parentURL.split(separator: "=")
                reg.last?.url = "http://download.osmand.net/download.php?standard=yes&file=" + (reg.last?.name.firstUppercased)! + "_" + parentUrlParam[2]
                
            } else {
                
                let parentUrlParam = parentURL.split(separator: "_")
                var url: String = ""
                for i in 0...parentUrlParam.count-2 {
                    url = parentUrlParam[parentUrlParam.count-i-1] + "_" + url
                }
                url = (reg.last?.name.lowercased())!  + "_" + url
                var linkParam = parentUrlParam[0].split(separator: "=")
                linkParam[2] = "" + linkParam[2].firstUppercased + "_"
                url = linkParam[2] + url
                url = linkParam[1] + "=" + url
                url = linkParam[0] + "=" + url
                //url = parentUrlParam[0] + "_" + url
                url.removeLast()
                reg.last?.url = url
                
              //  print(reg.last?.url)
            }
            reg.last?.parentRegion = parent.name
            //print("appended \(regions[i].name)")
        } else if regions[i].level < level {
            return (reg: reg, cont: i-1)
        }
        //print("checked \(regions[i].name)")
        i += 1
        
    }
    return (reg: reg, cont: i)
}
