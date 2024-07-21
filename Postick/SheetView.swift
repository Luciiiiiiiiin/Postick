//
//  SheetView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//  This file is responsible for displaying the camera view of the app

import SwiftUI

struct SheetView: View {
    @Binding var isPresented: Bool
    @State var modelName: String = "toy_biplane_idle"
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ARViewContainer(modelName: $modelName)
                .ignoresSafeArea(edges: .all)

            Button {
                isPresented.toggle()
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
