//
//  DetailedView.swift
//  Birthdays
//
//  Created by Adit Gupta on 7/6/22.
//

import SwiftUI
import Contacts
import ContactsUI
import MessageUI


struct DetailedView: View {
    @State private var showingAlert = false

    var currentContact: CNContact
    
    var body: some View {
        VStack{
            VStack(alignment: .center){
                if currentContact.thumbnailImageData != nil {
                    Image(uiImage: UIImage(data: currentContact.thumbnailImageData!)!)
                        .resizable()
                        .clipShape(Circle())
                        .padding(.all,2)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        .frame(width: 100, height: 100, alignment: .center)
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .clipShape(Circle())
                        .padding(.all,2)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        .frame(width: 100, height: 100, alignment: .center)
                }
                Text(currentContact.name)
                    .font(.system(size: 30))
                    .bold()
                    .multilineTextAlignment(.center)
                Text(currentContact.bDay)
                    .font(.system(size: 24))
            }
            .frame(width: UIScreen.main.bounds.width - 40, alignment: .center)
            .padding(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
            .background(Color.secondary.opacity(0.20))
            .cornerRadius(15)
            
            HStack{
                VStack{
                    Button(action: { sendMessage() })
                    {
                        Image(systemName: "message.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 45))
                    }
                    Text("Text")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary.opacity(2))
                }.padding(.trailing, 10)
                
                VStack{
                    Button(action: { sendCall() })
                    {
                        Image(systemName: "phone.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 45))
                    }
                    Text("Call")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary.opacity(2))
                }.padding(.trailing, 10)
                
                VStack{
                    let emailController = SendEmailViewController()
                    Button(action: { emailController.sendEmail(currentContact: currentContact) })
                    {
                        Image(systemName: "envelope.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 45))
                    }
                    Text("Email")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary.opacity(2))
                }.padding(.trailing, 10)
                
                VStack{
                    Button(action: { sendShop() })
                    {
                        Image(systemName: "gift.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 45))
                    }
                    Text("Shop")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary.opacity(2))
                }
            }
            .frame(width: UIScreen.main.bounds.width - 40, alignment: .center)
            .padding(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
            .background(Color.secondary.opacity(0.20))
            .cornerRadius(15)
            
            Spacer()
        }
        .padding(.init(top: 20, leading: 0, bottom: 20, trailing: 0))
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Sorry, a phone number could not be found"), dismissButton: .default(Text("Ok")))
        }
    }
    
    func sendMessage(){
        var number = ""
        if (currentContact.isKeyAvailable(CNContactPhoneNumbersKey)) {
            for phoneNumber:CNLabeledValue in currentContact.phoneNumbers {
                number = phoneNumber.value.stringValue
            }
        }
        let sms: String = "sms:\(number)&body=Happy birthday, \(currentContact.name)!"
        let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)
    }
    
    func sendCall(){
        var number = ""
        if (currentContact.isKeyAvailable(CNContactPhoneNumbersKey)) {
            for phoneNumber:CNLabeledValue in currentContact.phoneNumbers {
                number = phoneNumber.value.stringValue
            }
        }
        if number == ""{
            showingAlert = true
        } else {
            number = number.filter("0123456789.".contains)
            guard let url = URL(string: "telprompt://\(number)"),
                UIApplication.shared.canOpenURL(url) else {
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    func sendShop(){
        if let url = URL(string: "https://www.amazon.com/s?k=birthday+gifts") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
        }
    }
}

class SendEmailViewController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBAction func sendEmail(currentContact : CNContact) {
        var email = ""
        if (currentContact.isKeyAvailable(CNContactEmailAddressesKey)) {
            for currentEmail:CNLabeledValue in currentContact.emailAddresses {
                email = currentEmail.value as String
            }
        }
        
        let subject = "Happy Birthday!"
        let body = "It's your birthday! Happy birthday \(currentContact.name)! :)"
        
        // Show default mail composer
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            
            present(mail, animated: true)
        
        // Show third party email composer if default Mail app is not present
        } else if let emailUrl = createEmailUrl(to: email, subject: subject, body: body) {
            UIApplication.shared.open(emailUrl)
        }
    }
    
    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        }
        
        return defaultUrl
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

struct DetailedView_Previews: PreviewProvider {
    static var previews: some View {
        DetailedView(currentContact: CNContact())
    }
}
