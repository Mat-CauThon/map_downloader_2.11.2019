//
//  Data.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 29.10.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import Foundation
import UIKit

//нужно для того, что бы сделать первую букву региона заглавной
extension StringProtocol {
    var firstUppercased: String {
        return prefix(1).uppercased() + dropFirst()
    }
    var firstCapitalized: String {
        return String(prefix(1)).capitalized + dropFirst()
    }
}

//что бы не парится с переводом через вебсайт, тут используется расширение UIColor, что бы прямо в коде писать хэш цвета
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}


//нужно для создания макси на изображения (для обновления статуса региона на зеленый (скачанный))
extension UIImage {

    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)

        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }

}

//класс региона
class Region : CustomStringConvertible, Identifiable, ObservableObject  {
   
    
    
    var description: String {
        return "name: \(name) subregion: \(subRegions)"
    }
    
    var id: Int = 0
    var subRegions: [Region] = []
    var name: String = ""
    var level: Int = 0
    var parentRegion: String = ""
    var data: Data = Data()
    var url: String = ""
    var onDevice: Bool = false
    
}


//для загрузки из xml файла
class Parser: NSObject {
    var xmlParser: XMLParser?
    var regions: [Region] = []
    var xmlText = ""
    var currentRegion: Region?
    var level: Int = 0 //тип региона
    var id = 0 //счетчик для номера региона
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
        
//          добавил в структуру региона уникальный id, в последствии можно как-то использовать (например при сохранении)
            currentRegion = Region()
            currentRegion?.id += id
            id += 1
            
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
               
//  Понятия не имею как у вас реализована ссылка для скачивания под региона, под региона (я представил что вот так, но судя по тому, что оно не подгружало, думаю нет)
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



