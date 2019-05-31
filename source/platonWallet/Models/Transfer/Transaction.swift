//
//  Transaction.swift
//  platonWallet
//
//  Created by matrixelement on 19/10/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import Foundation
import BigInt
import Realm
import RealmSwift
import Localize_Swift

let oneMultiplier = "1"
let ETHToWeiMultiplier = "1000000000000000000"
let GMultiplier = "1000000000"

let THE8powerof10 = "100000000"
let THE9powerof10 = "1000000000"
let THE18powerof10 = "1000000000000000000"

enum TxType: String, Decodable {
    case transfer
    case MPCtransaction
    case contractCreate
    case voteTicket
    case transactionExecute
    case candidateDeposit
    case candidateApplyWithdraw
    case candidateWithdraw
    case unknown
    
    var localizeTitle: String {
        switch self {
        case .transfer:
            return Localized("TransactionStatus_transfer_title")
        case .MPCtransaction:
            return Localized("TransactionStatus_MPCtransaction_title")
        case .contractCreate:
            return Localized("TransactionStatus_contractCreate_title")
        case .voteTicket:
            return Localized("TransactionStatus_voteTicket_title")
        case .transactionExecute:
            return Localized("TransactionStatus_transactionExecute_title")
        case .candidateDeposit:
            return Localized("TransactionStatus_candidateDeposit_title")
        case .candidateApplyWithdraw:
            return Localized("TransactionStatus_candidateApplyWithdraw_title")
        case .candidateWithdraw:
            return Localized("TransactionStatus_candidateWithdraw_title")
        case .unknown:
            return Localized("TransactionStatus_unknown_title")
        }
    }
    
}


enum TransanctionType: Int {
    case Send
    case Receive
    case Vote
    
    public var localizedDesciption: String? {
        switch self {
        case .Send:
            return Localized("walletDetailVC_tx_type_send")
        case .Receive:
            return Localized("walletDetailVC_tx_type_receive")
        case .Vote:
            return Localized("walletDetailVC_tx_type_vote")
        }
    }
}

enum TransferStatus{
    case pending
    case confiming
    case success
    case fail
}

enum TransactionStatus {
    case sending
    case sendSucceed
    case sendFailed
    case receiving
    case receiveSucceed
    case receiveFailed
    case voting
    case voteSucceed
    case voteFailed
    
    var localizeTitle : String {
        switch self {
        case .sending:
            return Localized("TransactionStatus_sending_title")
        case .sendSucceed:
            return Localized("TransactionStatus_sendSucceed_title")
        case .sendFailed:
            return Localized("TransactionStatus_sendFailed_title")
        case .receiving:
            return Localized("TransactionStatus_receiving_title")
        case .receiveSucceed:
            return Localized("TransactionStatus_receiveSucceed_title")
        case .receiveFailed:
            return Localized("TransactionStatus_receiveFailed_title")
        case .voting:
            return Localized("TransactionStatus_voting_title")
        case .voteSucceed:
            return Localized("TransactionStatus_voteSucceed_title")
        case .voteFailed:
            return Localized("TransactionStatus_voteFailed_title")
        }
    }
    
    var localizeDescAndColor : (String, UIColor) {
        
        let succeedColor = cell_Transaction_success_color
        let pendingColor = cell_Transaction_pending_color
        let failedColor  = cell_Transaction_fail_color
        
        let pendingDesc = Localized("TransactionStatus_pending_desc")
        let succeedDesc = Localized("TransactionStatus_succeed_desc")
        let failedDesc = Localized("TransactionStatus_failed_desc")
        
        switch self {
        case .sending, .receiving, .voting:
            return (pendingDesc, pendingColor)
        case .sendSucceed, .receiveSucceed, .voteSucceed:
            return (succeedDesc, succeedColor)
        case .sendFailed, .receiveFailed, .voteFailed:
            return (failedDesc, failedColor)
        }
    }
    
}

class Transaction : Object, Decodable {
    
    @objc dynamic var txhash : String? = ""
    
    var nonce : CLongLong? = 0
    
    @objc dynamic var blockHash : String?  = ""
    
    @objc dynamic var blockNumber : String?  = ""
    
    @objc dynamic var from : String? = ""
    
    @objc dynamic var to : String?  = ""
    
    @objc dynamic var value : String? = ""
    
    @objc dynamic var gasPrice : String? = ""
    
    @objc dynamic var gas : String? = ""
    
    @objc dynamic var gasUsed : String? = ""
    
    @objc dynamic var memo : String? = ""
    
    @objc dynamic var input : String? = ""
    
    @objc dynamic var confirmTimes = 0

    @objc dynamic var createTime = 0
    
    @objc dynamic var transactionType = 0
    
    @objc dynamic var extra: String?
    
    @objc dynamic var nodeURLStr: String = ""
    
    var sequence: String?
    
    var txType: TxType? = .unknown
    
    var actualTxCost: String? = ""
    
    var transactionIndex: Int = 0
    
    var txReceiptStatus: Int = -1 //-1为处理中，兼容本地缓存的数据，后台只返回1：成功 0：失败
    
    //to confirm send or receive
    var senderAddress: String?
    
    var transactionStauts: TransactionStatus {
        get {
            switch transanctionTypeLazy {
            case .Send:
                if txReceiptStatus == 0 {
                    return .sendFailed
                } else if txReceiptStatus == 1 {
                    return .sendSucceed
                } else {
                    return .sending
                }
            case .Receive:
                if txReceiptStatus == 0 {
                    return .receiveFailed
                } else if txReceiptStatus == 1 {
                    return .receiveSucceed
                } else {
                    return .receiving
                }
            case .Vote:
                if txReceiptStatus == 0 {
                    return .voteFailed
                } else if txReceiptStatus == 1 {
                    return .voteSucceed
                } else {
                    return .voting
                }
            }
        }
    }
    
    var valueDescription : String?{
        get{
            guard value != nil else{
                return "0.00"
            }
            return BigUInt(value!)?.divide(by: ETHToWeiMultiplier, round: 8)
        }
    }
    
    var feeDescription : String?{
        get{
            var feeB : BigUInt?
            guard gasUsed != nil, gasUsed != "" ,gasPrice != nil, gasPrice != "" else{
                return "0.00"
            }
            
            
            feeB = BigUInt(gasUsed!)?.multiplied(by: BigUInt(gasPrice!)!)
            guard feeB != nil else{
                return "0.00"
            }
            return feeB!.divide(by: ETHToWeiMultiplier, round: 8)
            
        }
    }
    
    var actualTxCostDescription: String? {
        get {
            let cost = BigUInt.safeInit(str: actualTxCost).divide(by: ETHToWeiMultiplier, round: 8)
            return cost
        }
    }
    
    
    var transanctionTypeLazy : TransanctionType {
        get{
            switch txType! {
            case .transfer:
                if senderAddress != nil && (senderAddress?.ishexStringEqual(other: from))! {
                    return .Send
                } else {
                    return .Receive
                }
            case .MPCtransaction:
                return .Send
            case .contractCreate:
                return .Send
            case .voteTicket:
                return .Vote
            case .transactionExecute:
                return .Send
            case .candidateDeposit:
                return .Send
            case .candidateApplyWithdraw:
                return .Send
            case .candidateWithdraw:
                return .Send
            case .unknown:
                return .Send
            default:
                let type = TransanctionType(rawValue: transactionType) ?? .Send
                if type == .Send {
                    if senderAddress != nil && (senderAddress?.ishexStringEqual(other: from))! {
                        return .Send
                    }else {
                        return .Receive
                    }
                }else {
                    return type
                }
            }
        }
    }
    
    private func transactionReachTrustworthyStatus() -> (String,UIColor){
        var des : String = ""
        var color : UIColor = .white
        
        if (TransactionService.service.lastedBlockNumber != nil) && (TransactionService.service.lastedBlockNumber?.length)! > 0{
            let lastedBlockNumber = BigUInt(TransactionService.service.lastedBlockNumber!)
            let txBlockNumber = BigUInt((self.blockNumber)!)
            
            var lastedBlockNumberCopy = BigUInt(String((lastedBlockNumber!)))
            let overflow = lastedBlockNumberCopy?.subtractReportingOverflow(txBlockNumber!)
            if overflow! {
                return (des,color)
            }
            
            let blockDiff = BigUInt.safeSubStractToUInt64(a: lastedBlockNumber!, b: txBlockNumber!)
            if Int64(blockDiff) > MinTransactionConfirmations{
                //success
                des = Localized("walletDetailVC_tx_status_success")
                color = cell_Transaction_success_color
            }else{
                //block confirming or chain data rollback(debug)
                des = String(format: "%@(%d/%d)", Localized("walletDetailVC_tx_status_confirming"),blockDiff,MinTransactionConfirmations)
                color = cell_Transaction_success_color
            }
        }else{
            //network unreachable
            des = "--"
        }
        return (des,color)
    }
    
    override public static func ignoredProperties() ->[String] {
        return ["sharedWalletOwners","sharedWalletConOwners","sharedWalletRejectOwners","valueDescription","senderAddress", "sequence", "actualTxCost"]
    }
    
    override public static func primaryKey() -> String? {
        return "txhash"
    }
    
    enum CodingKeys: String, CodingKey {
        case actualTxCost
        case txhash = "hash"
        case from
        case to
        case blockHash
        case blockNumber
        case value
        case gasUsed = "energonUsed"
        case gasPrice = "energonPrice"
        case sequence
        case txType
        case confirmTimes = "timestamp"
        case transactionIndex
        case txReceiptStatus
        case extra = "txInfo"
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockNumber = try? container.decode(String.self, forKey: .blockNumber)
        txhash = try? container.decode(String.self, forKey: .txhash)
        from = try? container.decode(String.self, forKey: .from)
        to = try? container.decode(String.self, forKey: .to)
        blockHash = try? container.decode(String.self, forKey: .blockHash)
        value = try? container.decode(String.self, forKey: .value)
        gasUsed = try? container.decode(String.self, forKey: .gasUsed)
        gasPrice = try? container.decode(String.self, forKey: .gasPrice)
        sequence = try? container.decode(String.self, forKey: .sequence)
        txType = try? container.decode(TxType.self, forKey: .txType)
        let timeStampString = try? container.decode(String.self, forKey: .confirmTimes)
        if let ts = Int(timeStampString ?? "0") {
            confirmTimes = ts
        }
        actualTxCost = try? container.decode(String.self, forKey: .actualTxCost)
        let indexString = try? container.decode(String.self, forKey: .transactionIndex)
        if let index = Int(indexString ?? "0") {
            transactionIndex = index
        }
        let txReceiptStatusString = try? container.decode(String.self, forKey: .txReceiptStatus)
        if let status = Int(txReceiptStatusString ?? "0") {
            txReceiptStatus = status
        }
        
        extra = try? container.decode(String.self, forKey: .extra)
    }
    
}

class VoteTicket: Decodable {
    var price: Decimal?
    var count: Int?
    var nodeId: String?
    var nodeName: String?
    var deposit: String?
}

class VoteTicketInfo: Decodable {
    var functionName: String?
    var type: String?
    var parameters: VoteTicket?
}

class CandidateDeposit: Decodable {
    var owner: String?
    var Extra: String?
    var port: String?
    var fee: String?
    var host: String?
    var nodeId: String?
}

class CandidateDepositInfo: Decodable {
    var functionName: String?
    var parameters: CandidateDeposit?
    var type: String?
}
