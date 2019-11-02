//
//  CountryRegion.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 01.11.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import SwiftUI

struct CountryRegion: View {
    var regions: [Region]
    var body: some View {
        
        VStack {
                        List {
                            
                            Section(header: Text("Regions")) {
                                ForEach(regions) { region in
                                    RegionRow(region: region)
                                }
                            }
                            
                        }
                    .listStyle(GroupedListStyle())
        }
        
    }
}

//struct CountryRegion_Previews: PreviewProvider {
//    static var previews: some View {
//        CountryRegion(regions: worldState.regions)
//    }
//}
