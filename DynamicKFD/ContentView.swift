//
//  ContentView.swift
//  DynamicKFD
//
//  Created by ethernal on 08/01/23.
//

import SwiftUI

struct ContentView: View {
    
    @State private var kfd: UInt64 = 0

    private var puaf_pages_options = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puaf_pages_index = 7
    @State private var puaf_pages = 0

    private var puaf_method_options = ["physpuppet", "smith"]
    @State private var puaf_method = 1

    private var kread_method_options = ["kqueue_workloop_ctl", "sem_open"]
    @State private var kread_method = 1

    private var kwrite_method_options = ["dup", "sem_open"]
    @State private var kwrite_method = 1
    
    @AppStorage(DynamicKeys.isEnabled.rawValue) private var isEnabled: Bool = false
    @AppStorage(DynamicKeys.currentSet.rawValue) private var currentSet: Int = 0
    @AppStorage(DynamicKeys.originalDeviceSubType.rawValue) private var originalDeviceSubType: Int = 0
    
    
    @State private var isDoing: Bool = false
    
    private let dynamicPath = "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    
    @State private var deviceSize: Int = 0
    
    @State var checkedPro: Bool = false
    @State var checkedProMax: Bool = false
    
    @State var tappedOnSettings: Bool = false
    
    @State var shouldAlertDeviceSubTypeError: Bool = false
    @State var shouldAlertPlistCorrupted: Bool = false
    
    @State var shouldRedBarFix: Bool = false
    
    var body: some View {
        NavigationStack{
            VStack{
   
                AppearanceCellView(checkedPro: $checkedPro, checkedProMax: $checkedProMax)
                    .disabled(isEnabled)
                    .disabled(isDoing)
                    .opacity(isEnabled ? 0.8 : 1)
                    .opacity(isDoing ? 0.8 : 1)
  
                Spacer()
                
                Button {
                    
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
    
                    if isEnabled{
                        DynamicKFD(2556, 1179) // Cant think of anything to put here atm
                    }else{
                        //enable
                        if checkedProMax {
                            DynamicKFD(2796, 1290)
                            currentSet = 2796
                        }else{
                            DynamicKFD(2556, 1179)
                            currentSet = 2556
                        }
                        withAnimation{
                            isDoing = true
                            isEnabled = true
                        }
                        
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(height: 54)
                        .foregroundColor(.white.opacity(0.9))
                        .overlay {
                            if !isDoing{
                                Text(isEnabled ? "Disable" : "Enable & kclose")
                                    .foregroundColor(.black)
                                    .bold()
                            }else{
                                ProgressView()
                                    .tint(.black)
                            }
                        }
                }
                .padding()
                .disabled(checkedPro || checkedProMax ? false : true)
                .disabled(isDoing)
                .opacity(checkedPro || checkedProMax ? 1 : 0.8)
                .opacity(isDoing ? 0.8 : 1)

                
            }
            .padding()
            .onAppear{
                if currentSet == 2556{
                    withAnimation{
                        checkedPro = true
                    }
                }else if currentSet == 2796{
                    withAnimation{
                        checkedProMax = true
                    }
                }
            }
            
            .navigationTitle("DynamicKFD")
            .toolbar {
            
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
                .disabled(isDoing)
                .opacity(isDoing ? 0.8 : 1)
            
                if !isDoing {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isEnabled ? .green : .red)
                        .font(.title2)
                        .animation(.spring(), value: isEnabled)
                }else{
                    ProgressView()
                        .tint(.white)
                }
                    
                
            }
        }.tint(.white)
            .onAppear{
                puaf_pages = puaf_pages_options[puaf_pages_index]
                kfd = do_kopen(UInt64(puaf_pages), UInt64(puaf_method), UInt64(kread_method), UInt64(kwrite_method))
                
                switch UIDevice().machineName {
                case "iPhone11,8":
                    shouldRedBarFix = true
                    break
                case "iPhone12,1":
                    shouldRedBarFix = true
                    break
                default:
                    break
                }
                
            }
            .alert(isPresented: $shouldAlertDeviceSubTypeError) {
                Alert(title: Text("Error"), message: Text("There was an error getting the deviceSubType, maybe your plist file is corrupted, please tap on Reset and reopen the app again.\nNote: Your device will respring."), dismissButton: .destructive(Text("Reset"),action: {
                    // restore plist
                    killMobileGestalt()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                        respring()
                    }
                }))
            }
            .alert(isPresented: $shouldAlertPlistCorrupted) {
                Alert(title: Text("Error"), message: Text("There was an error modyfing your plist file is corrupted, please tap on Reset and reopen the app again.\nNote: Your device will respring."), dismissButton: .destructive(Text("Reset"),action: {
                    // restore plist
                    killMobileGestalt()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                        respring()
                    }
                }))
            }
    }
    
    
    func respring(){
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

            let view = UIView(frame: UIScreen.main.bounds)
            view.backgroundColor = .black
            view.alpha = 0

            UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first!.windows.first!.addSubview(view)
            UIView.animate(withDuration: 0.2, delay: 0, animations: {
                view.alpha = 1
            })

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                respringBackboard()
            })
    }

    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
