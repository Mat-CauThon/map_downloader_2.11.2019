//
//  ProgressBar.swift
//  mapDownload
//
//  Created by Roman Mishchenko on 31.10.2019.
//  Copyright © 2019 Roman Mishchenko. All rights reserved.
//

import SwiftUI


//почему-то в SwiftUI не завезли ProgressBar, поэтому вот своя реализация через 2 прямоугольника с разым расположением по Z
//проблема в ширине, ее четко нужно задавать в зависимости от расположения элемента в глобальной вьюхе, кроме того, если progress будет больше 1, то ProgressBar вылезет за отведенный для нее фрейм (тогда вся вьюха сдвинеться)
struct ProgressBar: View {
 
    @State var isShowing = false
    @Binding var progress: CGFloat
    @State var height = UIScreen.main.bounds.height*0.02
    @State var width = UIScreen.main.bounds.width*0.9
    //@Binding var height: CGFloat
    
    
    var body: some View {
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray)
                    .opacity(0.3)
                    .frame(width: width, height: height)
                Rectangle()
                    .foregroundColor(Color(UIColor(hexString: "#FF8800")))
                    .frame(width: self.isShowing ? width * (self.progress) : 0.0, height: height)
                    .animation(.linear(duration: 0.6))
            }
            .onAppear {
                self.isShowing = true
            }
            .cornerRadius(8.0)
    }
}

struct ThinProgressBar: View {
    
    @State var isShowing = false
    @Binding var progress: CGFloat
    @State var height = UIScreen.main.bounds.height*0.01
    @State var width = UIScreen.main.bounds.width*0.9
    
    
    
    var body: some View {
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray)
                    .opacity(0.3)
                    .frame(width: width, height: height)
                Rectangle()
                    .foregroundColor(Color(UIColor(hexString: "#FF8800")))
                    .frame(width: self.isShowing ? width * (self.progress) : 0.0, height: height)
                    .animation(.linear(duration: 0.6))
            }
            .onAppear {
                self.isShowing = true
            }
            .cornerRadius(8.0)
    }
    
}
