//
//  ContentView.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 29.10.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import SwiftUI




//сама вьюха
struct ContentView: View {
    
    
//    тут идет уточнение для UINavigationBar, что бы задать ему цвета (можно сделать в другом месте, решил сделать тут, тк показалось более логичным)
    init() {
        
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = UIColor(hexString: "#FF8800")
       //coloredAppearance.tintColor = UIColor.white
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
               
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        
        UINavigationBar.appearance().tintColor = UIColor.white
        
        
    }

    @EnvironmentObject var worldRegions: RegionsData
        
    //    состояние progressBar
    @State var progressBarValue:CGFloat = CGFloat(DiskStatus.usedDiskSpaceInBytes)/CGFloat(DiskStatus.freeDiskSpaceInBytes + DiskStatus.usedDiskSpaceInBytes)
    
    var body: some View {
        NavigationView {
            
            VStack {
                VStack {
                    HStack {
                        
                        Text("Device memory")
                        Spacer()
                        Text("Free \(DiskStatus.freeDiskSpace)")
                    }
                    ProgressBar(progress: $progressBarValue)
                } .padding(UIScreen.main.bounds.width*0.05)

                
                List {
                    ForEach(worldRegions.regions) { section in
                        Section(header: Text(section.name)) {
                            ForEach(section.subRegions) { region in
                                RegionRow(region: region)
                            }
                        }
                    }
                }
            .listStyle(GroupedListStyle())
            }
            
            .navigationBarTitle("Download map")

        }

        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
