//
//  DecryptionTableViewController.swift
//  PGPro
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ObjectivePGP

class DecryptionTableViewController: UITableViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passphraseTextField: UITextField!
    @IBOutlet weak var textView: UITextView!
    
    static var decryptionContact: Contact? = nil
    var decryptionKey: Key? {
        return DecryptionTableViewController.decryptionContact?.key
    }
    
    var keyRequiresPassphrase = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        self.hideKeyboardWhenTappedAround()
        
        update()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "envelope.open.fill")?.withTintColor(UIColor.label),
            style: .plain,
            target: self,
            action: #selector(decrypt)
        )
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.update),
                                               name: Constants.NotificationNames.privateKeySelectionChange,
                                               object: nil
        )
    }
    
    
    
    @objc
    func update(){
        var t = "Select Private Key..."
        if (DecryptionTableViewController.decryptionContact != nil){
            t = DecryptionTableViewController.decryptionContact!.userID
        }
        titleLabel.text = t
        
        keyRequiresPassphrase = decryptionKey?.isEncryptedWithPassword ?? false
        
        tableView.reloadData()
    }
    
    
    
    @objc
    func decrypt() {
        if let encryptedMessage = textView.text {
            if (encryptedMessage == "") {
                alert(text: "Paste Message to Decrypt!")
                return
            }
            if let encryptedMessageData = encryptedMessage.data(using: .ascii) {
                
                let passphrase = passphraseTextField.text
                var decryptedMessage = Data()
                
                if (decryptionKey == nil){
                    alert(text: "No Private Key Selected!")
                    return
                }
                
                if (keyRequiresPassphrase && passphrase == nil) {
                    alert(text: "Key Requires Passphrase!")
                    return
                }
                
                do {
                    if (keyRequiresPassphrase){
                        decryptedMessage = try ObjectivePGP.decrypt(encryptedMessageData,
                                                                        andVerifySignature: false,
                                                                        using: [decryptionKey!],
                                                                        passphraseForKey: {(_) -> (String?) in return passphrase})
                        
                    } else {
                        decryptedMessage = try ObjectivePGP.decrypt(encryptedMessageData,
                                                                        andVerifySignature: false,
                                                                        using: [decryptionKey!],
                                                                        passphraseForKey: nil)
                    }
                    
                    performSegue(withIdentifier: "showDecryptedMessage", sender: String(decoding: decryptedMessage, as: UTF8.self))
                } catch {
                    alert(text: "Decryption Failed!")
                }
            } else {
                alert(text: "Message Decoding Failed!")
            }
        } else {
            alert(text: "Failed to Retrieve Encrypted Message!")
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /* Give decrypted message to subview */
        if (segue.identifier == "showDecryptedMessage") {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! DecryptedMessageViewController
            targetController.message = sender as? String
        }
        
    }
    
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0){
            
            /* Private Key Selection */
            performSegue(withIdentifier: "showPrivateKeys", sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else if (indexPath.row == 2) {
            
            /* Paste from Clipboard */
            textView.text = UIPasteboard.general.string
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        /* Hide passphrase field if not required */
        if (!keyRequiresPassphrase) {
            if (indexPath.row == 1) {
                return 0
            }
        }
        
        if (indexPath.row == 3) {
            
            /* (Full-height) Message Row */
            var height = self.view.frame.height
            if (!keyRequiresPassphrase) {
                height -= 88
            } else {
                height -= 132
            }
            height -= (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0)
            height -= (self.navigationController?.navigationBar.frame.height ?? 0.0)
            height -= (self.tabBarController?.tabBar.frame.size.height ?? 0.0)
            
            return height
            
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

}
