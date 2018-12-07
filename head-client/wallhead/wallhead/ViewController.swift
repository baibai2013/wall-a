//
//  ViewController.swift
//  wallhead
//
//  Created by li on 2018/11/26.
//  Copyright © 2018 li. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,UITextFieldDelegate,PTChannelDelegate{
   
    
    let portNumber:Int = 2345
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var output: UITextView!
    
    var serverChannel:PTChannel? = nil
    var peerChannel:PTChannel? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        output.text = ""
        input.delegate = self
        
        
        PTChannel(delegate: self).listen(onPort: in_port_t(portNumber), iPv4Address: INADDR_LOOPBACK) { (error:Error?) in
            if(error != nil){
                self.appendOutputMessage(String.init(format:"Failed to listen on 127.0.0.1:%d: %@",self.portNumber,error! as CVarArg))
            }else {
                self.appendOutputMessage(String.init(format:"Listening on  127.0.0.1:%d",self.portNumber))
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let content = textField.text ?? ""
        if(self.peerChannel != nil){
            self.sendMessage(content)
            textField.text = ""
            let offset = UIScreen.main.bounds.height-self.input.frame.height
            UIView.animate(withDuration: 0.3, animations: {
                self.input.frame.origin.y = offset
            })
            return false
        }else {
             return true
        }
       
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let offset = UIScreen.main.bounds.height-300
        UIView.animate(withDuration: 0.3, animations: {
            self.input.frame.origin.y = offset
        })
        return true
    }
    
    func appendOutputMessage(_ msg: String){
        print(">> %@", msg);
        self.output.text.append(msg+"\n")
        self.output.scrollRangeToVisible(NSMakeRange(0 , self.output.text.count))
    }
    
    func sendMessage(_ msg: String){
        if(peerChannel != nil){
            let payload = PTExampleTextDispatchDataWithString(msg)
            peerChannel!.sendFrame(ofType: UInt32(PTExampleFrameTypeTextMessage),tag: PTFrameNoTag,withPayload: payload,callback: {(error:Error?) in
                if(error != nil){
                    print("Failed to send message: %@", error!)
                }
                self.appendOutputMessage("[you]:"+msg)
            })
        }else {
            self.appendOutputMessage("Can not send message — not connected")
        }
    }

    
    //MARK: - PTChannelDelegate
    /**
    * 当某个终端接受到数据片段时调用。
    **/
    func ioFrameChannel(_ channel: PTChannel!, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: PTData?) {
        if(type == PTExampleFrameTypeTextMessage){
            self.appendOutputMessage(String.init(format:"%@",payload.data))
        }else if(type == PTExampleFrameTypePing && peerChannel != nil){
            peerChannel.sendFrame(ofType: UInt32(PTExampleFrameTypePong),tag,withPayload:nil,callback:nil)
        }
    }
    
    /**
    * 当终端传入一个数据片段时调用。返回false忽略这个这个数据片段，如果这个delegate没有执行，所有数据片段都会被接受。
    **/
    func ioFrameChannel(_ channel: PTChannel!, shouldAcceptFrameOfType type: UInt32, tag: UInt32, payloadSize: UInt32)-> Bool {
        if(channel != peerChannel){
            return false
        }else if( type != PTExampleFrameTypeTextMessage && type != PTExampleFrameTypePing){
            print("Unexpected frame of type %u", type)
            channel.close()
            return false
        }
        return true
    }
    
    /**
    *当终端关闭时，该方法被调用。如果是错误到导致的关闭，输出错误
    **/
    func ioFrameChannel(_ channel: PTChannel!, didEndWithError error: Error?) {
        if(error != nil){
            self.appendOutputMessage(String.init(format:"%@ ended with error:%@",channel,error))
        }else {
            self.appendOutputMessage(String.init(format:"Disconnected form:%@",channel.userInfo))
        }
    }
    
    /**
     * 监听终端，当一个新的终端被接受时触发这个方法
    **/
    func ioFrameChannel(_ channel: PTChannel!, didAcceptConnection otherChannel: PTChannel!,from address: PTAddress!) {
        if(self.peerChannel != nil){
            self.peerChannel.cancel
        }
        self.peerChannel = otherChannel
        self.peerChannel = address
        self.appendOutputMessage(String.init(format: "Connected to %@", address))
    }
    
  
}

