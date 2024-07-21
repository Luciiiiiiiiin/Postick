//
//  ContentView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//  

import SwiftUI

struct ContentView: View {
    @State private var modelName: String = "toy_biplane_idle"

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ARViewContainer(modelName: $modelName)
                .ignoresSafeArea(edges: .all)

            Button {
                // Exit or close logic here, if needed
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(24)
        }
    }
}


