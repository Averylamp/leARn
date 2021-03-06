//
//  ChatViewController.swift
//  leARn
//
//  Created by Pramoda Karnati on 7/28/18.
//  Copyright © 2018 Avery Lamp. All rights reserved.
//

import UIKit
import AgoraSigKit

protocol ChatDelegate {
    func newMessage(message:Message)
    func dismissChatVC()
    func onlineNumberChanged(numOnline: Int)
}

class ChatViewController: UIViewController {
    
    var delegate: ChatDelegate?
    
    @IBOutlet weak var chatRoomTableView: UITableView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var chatRoomName: UILabel!
    
    @IBOutlet weak var bottomOffsetConstraint: NSLayoutConstraint!
    
    
    var chatId: String = "testroom"
    var accountId : String = "potato"
    
    var messageList = MessageList()
    
    var userNum = 0 {
        didSet {
            DispatchQueue.main.async(execute: {
                if self.userNum < 0 {
                    self.userNum = 0
                }
                self.title = self.chatId + " (\(String(self.userNum)))"
                self.chatRoomName.text? = "Chatroom: \(self.chatId), \(self.userNum) online"
                if let delegate = self.delegate{
                    delegate.onlineNumberChanged(numOnline: self.userNum)
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.view.safeAreaInsets.bottom)

        // Do any additional setup after loading the view.
        
//        let article = WikipediaKit.sharedInstance.returnArticleFromAPI(name: "Stack Overflow")
//        print(article.title)
//        print(article.content)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        blurEffectView.layer.cornerRadius = 50
        blurEffectView.clipsToBounds = true
        blurEffectView.frame = self.view.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(blurEffectView, at: 0)
        
        self.inputField.delegate = self
        
        self.chatRoomTableView.rowHeight = UITableView.automaticDimension
        self.chatRoomTableView.estimatedRowHeight = 100
        self.chatRoomTableView.delegate = self
        self.chatRoomTableView.dataSource = self
        
    }
    @IBAction func backButtonClicked(_ sender: Any) {
        if let delegate = self.delegate{
            delegate.dismissChatVC()
        }
    }
    
    func instantiateChat(){
        AgoraSignalKit.Kit.channelQueryUserNum(chatId)
        messageList.messageListId = chatId
        logInToAgoraAPI()
        addAgoraSignalBlock()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        instantiateChat()
    }

    func didLeaveChat(){
        AgoraSignalKit.Kit.channelLeave(chatId)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)

    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        print("Keyboard height \(keyboardHeight)")
        print("\(UIApplication.shared.keyWindow?.safeAreaInsets.bottom)")
        bottomOffsetConstraint.constant =  -keyboardHeight + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom)!
        self.view.layoutIfNeeded()
        
    }
    @objc func keyboardWillHide(notification: Notification){
        bottomOffsetConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    
    func logInToAgoraAPI() {
        AgoraSignalKit.Kit.login2(Key.key, account: accountId, token: "_no_need_token", uid: 0, deviceID: nil, retry_time_in_s: 60, retry_count: 5)
        
        // check for new account log in
        let lastAccount = UserDefaults.standard.string(forKey: "myAccount")
        if (lastAccount != accountId) {
            UserDefaults.standard.set(accountId, forKey: "myAccount")
            chatMessages.removeAll()
        }
        
        if (userColor[accountId] == nil) {
            userColor[accountId] = UIColor.randomColor()
        }
    }
    
    func addAgoraSignalBlock() {
        AgoraSignalKit.Kit.channelJoin(chatId)
        
        chatRoomName.text? = "Chatroom: \(self.chatId), \(self.userNum) online"
        
        AgoraSignalKit.Kit.onMessageChannelReceive = { [weak self] (channelID, account, uid, msg) -> () in
            DispatchQueue.main.async(execute: {
                let message = Message(name: account, message: msg)
                self?.messageList.list.append(message)
                self?.updateTableView((self?.chatRoomTableView)!, with: message)
                if let delegate = self?.delegate {
                        delegate.newMessage(message: message)
                }
            })
        }
        
        AgoraSignalKit.Kit.onChannelQueryUserNumResult = { [weak self] (channelID, ecode, num) -> () in
            self?.userNum = Int(num)
        }
        
        AgoraSignalKit.Kit.onChannelUserJoined = { [weak self] (account, uid) -> () in
            self?.userNum += 1
        }
        
        AgoraSignalKit.Kit.onChannelUserLeaved = { [weak self] (account, uid) -> () in
            self?.userNum -= 1
        }
    }
    
    @IBAction func sendMessageButtonClicked(_ sender: Any) {
        self.sendMessage()
    }
    
    func updateTableView(_ tableView: UITableView, with message: Message) {
        let indexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .none)
        tableView.endUpdates()
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendMessage()
        return true
    }
    
    func sendMessage(){
        guard let message = inputField.text, message.count > 0 else { return  }
        AgoraSignalKit.Kit.messageChannelSend(chatId, msg: message, msgID: String(messageList.list.count))
        self.inputField.text = ""        
    }
}

extension ChatViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.list.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myAccount = UserDefaults.standard.string(forKey: "myAccount")
        if (messageList.list[indexPath.row].name != myAccount) {
            if (userColor[messageList.list[indexPath.row].name] == nil) {
                userColor[messageList.list[indexPath.row].name] = UIColor.randomColor()
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "chatMessageTableCellLeft", for: indexPath) as! ChatMessageTableViewCell
            cell.setCellViewWith(message: messageList.list[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "chatMessageTableCellRight", for: indexPath) as! ChatMessageTableViewCell
            cell.setCellViewWith(message: messageList.list[indexPath.row])
            return cell
        }
    }
}
