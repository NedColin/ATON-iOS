//
//  PlatonContractTest.swift
//  platonWallet
//
//  Created by matrixelement on 9/11/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import Foundation

class PlatonContractTest {
    
    let platonWeb3 = Web3(rpcURL: "http://192.168.9.180:7789")
    static let sharedInstance = PlatonContractTest()
    
    func mutiplyDeploy(){
        let gasPrice = BigUInt("22000000000")
        let gas = BigUInt("4300000")
        let binPath = Bundle.main.path(forResource: "PlatonAssets/multisig", ofType: "wasm")
        let bin = try? Data(contentsOf: URL(fileURLWithPath: binPath!))
        
        let abiPath = Bundle.main.path(forResource: "PlatonAssets/multisig.cpp.abi", ofType: "json")
        var abiS = try? String(contentsOfFile: abiPath!)
        abiS = abiS?.replacingOccurrences(of: "\r\n", with: "")
        abiS = abiS?.replacingOccurrences(of: "\n", with: "")
        abiS = abiS?.replacingOccurrences(of: " ", with: "")
        
        let sender = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219"
        let privateKey = "4484092b68df58d639f11d59738983e2b8b81824f3c0c759edd6773f9adadfe7"
        
        platonWeb3.eth.platonDeployContract(abi: abiS!, bin: bin!, sender: sender, privateKey: privateKey, gasPrice: gasPrice!, gas: gas!, estimateGas: false, timeout: 20, completion:{
            (result,contractAddress,transactionHash) in
            
            switch result{
                
            case .success:
                do {
                    self.initSharedWallet(contractAddress: contractAddress!)
                }
            case .fail(_, _):
                do {
                    
                }
            }
            
        })
        
//        platonWeb3.eth.platonDeployContract(abi: abiS!, bin: bin!, sender: sender, privateKey: privateKey, gasPrice: gasPrice!, gas: gas!,completion: { (ret, ret2) in
        
//            })
        
//        platonWeb3.eth.platonDeployContract(abi: abiS!, bin: bin!, sender: sender, privateKey: privateKey, gasPrice: gasPrice!, gas: gas!,completion: )
    }
    
    func initSharedWallet(contractAddress : String){
        var balanceOfAccout = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219"
        balanceOfAccout = balanceOfAccout + ":" + "0xffffca9c1290ee56b98d4e160ef0453f7c40ffff"
        let callpraram = balanceOfAccout.data(using: .utf8)
        let rquire = Data(bytes: [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02])
        let paramter = SolidityFunctionParameter(name: "", type: .string)
        platonWeb3.eth.platonCall(contractAddress: contractAddress, functionName: "initWallet", from: balanceOfAccout, [callpraram!,rquire], outputs: [paramter], completion: {(result,data) in
            switch result{
                
            case .success:
                do {
                    self.platonWeb3.eth.platonCall(contractAddress: contractAddress, functionName: "getOwners", from: balanceOfAccout, [], outputs: [paramter], completion: {(callRes,callret)in
                        
                    })
                }
            case .fail(_, _):
                do
                {
                    
                }
            }
        })
    }
    
    func testDeploy(){
        let gasPrice = BigUInt("22000000000")
        let gas = BigUInt("4300000")
        let binPath = Bundle.main.path(forResource: "PlatonAssets/demo01", ofType: "wasm")
        let bin = try? Data(contentsOf: URL(fileURLWithPath: binPath!))
        
        let abiPath = Bundle.main.path(forResource: "PlatonAssets/demo01.cpp.abi", ofType: "json")
        var abiS = try? String(contentsOfFile: abiPath!)
        abiS = abiS?.replacingOccurrences(of: "\r\n", with: "")
        abiS = abiS?.replacingOccurrences(of: "\n", with: "")
        
        let sender = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219"
        let privateKey = "4484092b68df58d639f11d59738983e2b8b81824f3c0c759edd6773f9adadfe7"
        
//        platonWeb3.eth.platonDeployContract(abi: abiS!, bin: bin!, sender: sender, privateKey: privateKey, gasPrice: gasPrice!, gas: gas!, completion: { (ret1,ret2) in
//
//        })
    }
    
    func testCall(){
        let balanceOfAccout = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219"
        let callpraram = balanceOfAccout.data(using: .utf8)
        let paramter = SolidityFunctionParameter(name: "", type: .string)
        platonWeb3.eth.platonCall(contractAddress: "0x43355c787c50b647c425f594b441d4bd751951c1", functionName: "getBalance", from: balanceOfAccout, [callpraram!], outputs: [paramter],completion: nil)
    }
    
    func testSendRawTransaction(){
        
        let sender = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219"
        let privateKey = "4484092b68df58d639f11d59738983e2b8b81824f3c0c759edd6773f9adadfe7"
        
        let contractAddress = "0x43355c787c50b647c425f594b441d4bd751951c1"
        let functionName = "transfer02"
        let param_from = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219".data(using: .utf8)
        let param_to = "0xaa31ca9d892800aa67383bb88114b61868221ee5".data(using: .utf8)
        let param_assert = Data(bytes: [0x00,0x00,0x00,0x14])
        
        let gasPrice = BigUInt("22000000000")
        let gas = BigUInt("4300000")
            
        platonWeb3.eth.plantonSendRawTransaction(contractAddress: contractAddress, functionName: functionName, [param_from!,param_to!,param_assert], sender: sender, privateKey: privateKey, gasPrice: gasPrice!, gas: gas!, estimated: false, completion: nil)
    }
    
    func test(){
        let address = "0x..".data(using: .utf8)
        let amout = Data(bytes: [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02])
        let gasPrice = BigUInt("22000000000")
        let gas = BigUInt("4300000")
        let sender = "0x60ceca9c1290ee56b98d4e160ef0453f7c40d219"
        let privateKey = "4484092b68df58d639f11d59738983e2b8b81824f3c0c759edd6773f9adadfe7"
        let contractAddress = "0x43355c787c50b647c425f594b441d4bd751951c1"
        web3.eth.plantonSendRawTransaction(contractAddress: contractAddress, functionName: "transfer", [address!, amout], sender: sender, privateKey: privateKey, gasPrice: gasPrice!, gas: gas!,estimated: false, completion: { (result, data) in
            switch result{
            case .success:
                do{}
            case .fail(_,_):
                do{}
            }
        })
    }
}
