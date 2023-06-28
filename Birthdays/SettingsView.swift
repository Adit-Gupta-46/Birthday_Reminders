//
//  SettingsView.swift
//  Birthdays
//
//  Created by Adit Gupta on 7/5/22.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var currentDate = Date()
    @State private var OnDayNotif = true
    @State private var OffsetNotif = true

    var body: some View {
        VStack{
            HStack{
                Text("Settings")
                    .font(.system(size:48))
                    .fontWeight(.bold)
                    .padding(.top, 7)
                    .padding(.bottom, -3)
                    .padding(.leading, 15)
                Spacer()
            }
            List {
                // first section
                Section(header: Text("Notifications")) {
                    HStack (spacing : 15) {
                        Image(systemName: "clock")
                        Text ("Set Notification Time")
                        Spacer()
                        DatePicker("", selection: $currentDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                
                Section(header: Text("Remind on")) {
                    HStack (spacing : 15) {
                        Image(systemName: "clock")
                        Toggle(isOn: $OnDayNotif) {
                            Text("Day Of")
                        }
                        
                    }
                    HStack (spacing : 15) {
                        Image(systemName: "clock")
                        Toggle(isOn: $OffsetNotif) {
                            Text("3 Days Before")
                        }
                    }
                }
                if OnDayNotif {
                    Text("dfgh")
                }
                if OffsetNotif {
                    Text("dfdfggh")
                }
                
                
                
                
                
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
