//
//  RegionRow.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 02.11.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import SwiftUI


//описывает ячейку региона
struct RegionRow: View {
    
    
    var region: Region
    @State private var downloadCheck: Bool = false
    @State private var value: CGFloat = 0
    @State private var inProcess: Bool = false
    
    @State private var observation: NSKeyValueObservation?
    
    func getRegion(url: URL, _ completion:@escaping (Data?)->()) {
        let task = URLSession.shared.dataTask(with: url) { data, response, err in
            
            guard let data = data, err == nil else {
                completion(nil)
                return
            }
            completion(data)
        }
        
        self.observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            self.value = CGFloat(progress.fractionCompleted)
        }
        task.resume()
    }
    
    var body: some View {
        
        VStack {
            if region.subRegions.count > 0 {
                //var check =
                NavigationLink(destination: CountryRegion(regions: self.region.subRegions)) {
                    HStack {
                        
                        HStack {
//                          тут возникла проблема, хз почему не работает обновление статуса, хотя по логике должно, при скачивание всех под регионов, не обновляется статус региона
                            if region.subRegions.count == region.subRegions.filter({ (reg) -> Bool in
                                return reg.onDevice
                            }).count {
                                Image(uiImage: (UIImage(named: "ic_custom_map")?.maskWithColor(color: UIColor.systemGreen))!)
                            } else {
                                Image("ic_custom_map")
                            }
                            
                        }
                        Text(region.name)
                        Spacer()
                        
                    }
                }
            } else {
                HStack {
                    //Image()
                    if region.onDevice {
                        
                        Image(uiImage: (UIImage(named: "ic_custom_map")?.maskWithColor(color: UIColor.systemGreen))!)
                        
                    } else {
                        Image("ic_custom_map")
                    }
                    Text(region.name)
                    Spacer()
                    Button(action: {
                        
                       
                        
                        if !self.region.onDevice && !self.inProcess {
                            self.inProcess = true
                            self.downloadCheck = true
                            
                                
                                
                            let url = URL(string: self.region.url)!
                            
                            self.getRegion(url: url) { (region) in
                                DispatchQueue.main.async {
                                    self.region.data = region ?? Data()
                                    self.downloadCheck = false
                                    self.region.onDevice = true
                                    self.observation?.invalidate()
                                    
                                    
                                }
                            }
                            

                           
                            
                        }
                    }) {
                        
                        Image("ic_custom_dowload")
                        .foregroundColor(Color(UIColor(hexString: "#FF8800")))
                    }
                
                    
                }
            }
            if downloadCheck {
                ThinProgressBar(progress: $value)
                Spacer()
            }
            
        }
        
        
    }
}
