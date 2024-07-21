//
//  ContentView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//  

import SwiftUI

struct ContentView: View {
        
    @State var isPresented: Bool = false
    @State private var isScanning: Bool = true
    @State private var modelName: String = "toy_biplane_idle"

    var body: some View {
        ZStack {
            VStack {
                Image("biplane")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))
                    .padding(24)

                Button {
                    isPresented.toggle()
                } label: {
                    Label("View in AR", systemImage: "arkit")
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding(24)
            }
            .padding()
            
            .fullScreenCover(isPresented: $isPresented, content: {
                SheetView(isPresented: $isPresented)
            })
        }
    }
}


