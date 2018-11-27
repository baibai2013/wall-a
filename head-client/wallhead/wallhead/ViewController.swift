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
    
    var serverChannel:PTChannel?
    var peerChannel:PTChannel?
    
    
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
    func ioFrameChannel(_ channel: PTChannel!, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: PTData?) {
        
    }
    
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
    
    func ioFrameChannel(_ channel: PTChannel!, didEndWithError error: Error?) {
        
    }
    
    func ioFrameChannel(_ channel: PTChannel!, didAcceptConnection otherChannel: PTChannel!,from address: PTAddress!) {
        
    }
    
  
}

