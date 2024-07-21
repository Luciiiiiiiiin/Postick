//
//  ContentView.swift
//  Postick
//
//  Created by Yuxuan Liu on 2024/7/19.
//  

//import SwiftUI
//
//struct ContentView: View {
//    @State private var modelName: String = "toy_biplane_idle"
//
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            ARViewContainer(modelName: $modelName)
//                .ignoresSafeArea(edges: .all)
//
//            Button {
//                // Exit or close logic here, if needed
//            } label: {
//                Image(systemName: "xmark.circle")
//                    .font(.largeTitle)
//                    .foregroundColor(.black)
//                    .background(.ultraThinMaterial)
//                    .clipShape(Circle())
//            }
//            .padding(24)
//        }
//    }
//}

import SwiftUI

struct ContentView: View {
    @State private var modelName: String = "toy_biplane_idle"

    var body: some View {
        ZStack {
            ARViewContainer(modelName: $modelName)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        // Action to be performed when the button is tapped
                        performNextOperation()
                    }) {
                        Image(systemName: "photo") // Replace with your image name
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                    }
                    .padding()

                    Spacer()
                    
                    Button(action: {
                        // Action to be performed when the second button is tapped
                        performOtherOperation()
                    }) {
                        Image("collage") // Replace with your image name
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.green)
                    }
                    .padding()
                }
            }
        }
    }

    func performNextOperation() {
        // Placeholder for the operation to be performed
        print("Next operation performed")
    }
    
    func performOtherOperation() {
        // Placeholder for the other operation to be performed
        print("Other operation performed")
    }
}



