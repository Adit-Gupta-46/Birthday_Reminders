//
//  ContentView.swift
//  Birthdays
//
//  Created by Adit Gupta on 6/16/22.
//

import SwiftUI
import Contacts

struct ContentView: View {
    
    @EnvironmentObject var store: ContactStore
    @State private var searchText: String = ""
    @State var viewSettings: Bool = false
    @State var viewDetails: Bool = false
    @State var currentContact: CNContact = CNContact()
    
    var body: some View {
        NavigationView{
            VStack {
                HStack {
                    Text("Birthdays")
                        .font(.system(size:48))
                        .fontWeight(.bold)
                        .padding(.top, 7)
                        .padding(.bottom, -3)
                        .padding(.leading, 15)
                    Spacer()
                    Button(action: { viewSettings.toggle() })
                    {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                            .font(.system(size: 36))
                            .padding(.top, 7)
                            .padding(.bottom, -3)
                    }.padding(.trailing, 10)
                }.padding(.bottom,5)
                VStack {
                    SearchBarView(text: $searchText, placeholder: "Type here")
                    List{
                        ForEach(self.store.contacts.filter{
                            self.searchText.isEmpty ? true : $0.name.lowercased().contains(self.searchText.lowercased())
                        }, id: \.self.name) {
                            (contact: CNContact) in
                            Button(action: {
                                viewDetails.toggle()
                                currentContact = contact
                            }) {
                                HStack{
                                    if contact.thumbnailImageData != nil {
                                        Image(uiImage: UIImage(data: contact.thumbnailImageData!)!)
                                            .resizable()
                                            .clipShape(Circle())
                                            .padding(.all,2)
                                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                            .frame(width: 50, height: 50, alignment: .center)

                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .clipShape(Circle())
                                            .padding(.all,2)
                                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                            .frame(width: 50, height: 50, alignment: .center)
                                    }
                                    VStack(alignment: .leading){
                                        Text(contact.name).font(.headline)
                                        Text(contact.bDay).font(.headline)
                                    }
                                    Spacer()
                                    Image(systemName: "arrowshape.turn.up.forward")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 26))
                                }
                            }
                        }
                    }
                    .onAppear{
                        DispatchQueue.main.async {
                            self.store.fetchContacts()
                        }
                    }
                }
                NavigationLink(
                    LocalizedStringKey(""),
                    destination: SettingsView(),
                    isActive: $viewSettings)
                NavigationLink(
                    LocalizedStringKey(""),
                    destination: DetailedView(currentContact: currentContact),
                    isActive: $viewDetails)
            }
            .hiddenNavigationBarStyle()
        }
    }
}

struct HiddenNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
}

extension View {
    func hiddenNavigationBarStyle() -> some View {
        modifier( HiddenNavigationBar() )
    }
}

struct SearchBarView: UIViewRepresentable {

    @Binding var text: String
    var placeholder: String

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.showsCancelButton = true
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar,
                      context: Context) {
        uiView.text = text
    }
}

class Coordinator: NSObject, UISearchBarDelegate {

    @Binding var text: String

    init(text: Binding<String>) {
        _text = text
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        text = searchText
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(ContactStore())
    }
}

class ContactStore: ObservableObject {
    
    @Published var contacts: [CNContact] = []
    @Published var error: Error? = nil
    
     func fetchContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }
            
            if granted {

                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey, CNContactThumbnailImageDataKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                request.sortOrder = .givenName
                
                do {

                    var contactsBeforeArray = [CNContact]()
                    var contactsAfterArray = [CNContact]()
                    let date = Date()
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        if contact.birthday != nil {
                            if ((contact.birthday?.month)! < Calendar.current.component(.month, from: date) || ((contact.birthday?.month)! == Calendar.current.component(.month, from: date) && (contact.birthday?.day)! < Calendar.current.component(.day, from: date))){
                                contactsBeforeArray.append(contact)
                            } else {
                                contactsAfterArray.append(contact)
                            }
                        }
                    })
                    contactsBeforeArray = contactsBeforeArray.sorted{(lhs, rhs) in
                        if lhs.birthday?.month == rhs.birthday?.month { // <1>
                            return ((lhs.birthday?.day)! < (rhs.birthday?.day)!)
                        }
                        return ((lhs.birthday?.month)! < (rhs.birthday?.month)!) // <2>
                    }
                    contactsAfterArray = contactsAfterArray.sorted{(lhs, rhs) in
                        if lhs.birthday?.month == rhs.birthday?.month { // <1>
                            return ((lhs.birthday?.day)! < (rhs.birthday?.day)!)
                        }
                        return ((lhs.birthday?.month)! < (rhs.birthday?.month)!) // <2>
                    }
                    
                    self.contacts = contactsAfterArray + contactsBeforeArray
                    
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        }
    }
}

extension CNContact: Identifiable {
    var name: String {
        return [givenName, familyName].filter{ $0.count > 0}.joined(separator: " ")
    }
    
    var birthMonth: Int {
        return birthday?.month ?? 0
    }
    
    var birthDay: Int{
        return birthday?.day ?? 0
    }
    
    var bDay: String {
        let yearNumber = birthday?.year ?? -1
        if yearNumber != -1{
            return "\(DateFormatter().monthSymbols[birthMonth - 1]) \(birthDay), \(yearNumber)"
        } else {
            return "\(DateFormatter().monthSymbols[birthMonth - 1]) \(birthDay)"
        }
    }
}

