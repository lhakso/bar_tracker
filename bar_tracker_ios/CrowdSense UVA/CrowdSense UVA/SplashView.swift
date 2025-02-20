//
//  SplashView.swift
//  CrowdSense UVA
//
//  Created by Luke Hakso on 2/3/25.
//
import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
            if isActive {
                    ContentView()
            } else {
                Image("logo_no_background")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .scaleEffect(opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 10/255, green: 10/255, blue: 60/255))
                    .onAppear {
                        withAnimation { opacity = 1.0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation { isActive = true }
                        }
                    }
            }

    }
}
