//
//  TransactionListViewController.swift
//  platonWallet
//
//  Created by matrixelement on 1/11/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import UIKit
import Localize_Swift
import MJRefresh

class TransactionListViewController: BaseViewController,UITableViewDelegate,UITableViewDataSource {
    
    let listSize = 20

    lazy var txnTableView = { () -> UITableView in
        let tbView = UITableView(frame: .zero)
        tbView.delegate = self
        tbView.dataSource = self
        tbView.register(WalletTableViewCell.self, forCellReuseIdentifier: "WalletTableViewCell")
        tbView.separatorStyle = .none
        tbView.backgroundColor = normal_background_color
        tbView.registerCell(cellTypes: [TransactionCell.self])
        tbView.rowHeight = 69.0
        return tbView
    }()
    
    lazy var dropdownListView = { () -> DropdownListView in
        let view = DropdownListView(for: selectedWallet)
        return view
    }()
    
    var dataSource : [Transaction] = []
    
    var selectedWallet: Wallet?
    
    lazy var refreshHeader: MJRefreshHeader = {
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(fetchTransactionLastest))!
        return header
    }()
    
    lazy var refreshFooter: MJRefreshFooter = {
        let footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(fetchTransactionMore))!
        return footer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        initSubView()
        txnTableView.mj_header.beginRefreshing()
    }
    
    @objc func fetchTransactionLastest() {
        var addressStrs: [String] = []
        
        if let wallet = selectedWallet {
            addressStrs.append(wallet.key!.address)
        } else {
            let allLocalAddresses = AssetVCSharedData.sharedData.walletList.filterClassicWallet.map { cwallet in
                return cwallet.key!.address
            }
            addressStrs.append(contentsOf: allLocalAddresses)
        }
        
        guard addressStrs.count > 0 else {
            self.txnTableView.mj_header.endRefreshing()
            self.txnTableView.mj_footer.endRefreshing()
            return
        }
        fetchTransaction(addressStrs: addressStrs, beginSequence: -1, direction: "new")
    }
    
    @objc func fetchTransactionMore() {
        var addressStrs: [String] = []
        
        if let wallet = selectedWallet {
            addressStrs.append(wallet.key!.address)
        } else {
            let allLocalAddresses = AssetVCSharedData.sharedData.walletList.filterClassicWallet.map { cwallet in
                return cwallet.key!.address
            }
            addressStrs.append(contentsOf: allLocalAddresses)
        }
        
        guard addressStrs.count > 0 else {
            self.txnTableView.mj_header.endRefreshing()
            self.txnTableView.mj_footer.endRefreshing()
            return
        }
        
        guard let lastTransaction = dataSource.last else {
            return
        }
        
        guard let sequence = Int(lastTransaction.sequence ?? "0") else { return }
        fetchTransaction(addressStrs: addressStrs, beginSequence: sequence, direction: "old")
    }
    
    func fetchTransaction(addressStrs: [String], beginSequence: Int, direction: String) {
        TransactionService.service.getBatchTransaction(addresses: addressStrs, beginSequence: beginSequence, listSize: listSize, direction: direction) { (result, response) in
            
            self.txnTableView.mj_header.endRefreshing()
            self.txnTableView.mj_footer.endRefreshing()
            
            switch result {
            case .success:
                if beginSequence == -1 {
                    self.dataSource.removeAll()
                    self.txnTableView.reloadData()
                }
                
                guard let transactions = response as? [Transaction], transactions.count > 0 else {
                    self.txnTableView.mj_footer.isHidden = self.dataSource.count == 0
                    return
                }
                
                if let currentAddress = self.selectedWallet?.key?.address {
                    let _ = transactions.map({ (tx) -> Transaction in
                        switch tx.txType! {
                        case .transfer:
                            tx.direction = (currentAddress.lowercased() == tx.from?.lowercased() ? .Sent : currentAddress.lowercased() == tx.to?.lowercased() ? .Receive : .unknown)
                            return tx
                        case .delegateWithdraw,
                             .stakingWithdraw:
                            tx.direction = .Receive
                            return tx
                        default:
                            tx.direction = .Sent
                            return tx
                        }
                    })
                } else {
                    let addresses = (AssetVCSharedData.sharedData.walletList as! [Wallet]).map { return $0.key!.address.lowercased() }
                    let _ = transactions.map({ (tx) -> Transaction in
                        switch tx.txType! {
                        case .transfer:
                            if
                                let from = tx.from?.lowercased(),
                                let to = tx.to?.lowercased(),
                                (addresses.contains(from) && addresses.contains(to)) {
                                tx.direction = .Sent
                            } else {
                                if let from = tx.from?.lowercased(), addresses.contains(from) {
                                    tx.direction = .Sent
                                } else if let to = tx.to?.lowercased(), addresses.contains(to) {
                                    tx.direction = .Receive
                                }
                            }
                            return tx
                        case .delegateWithdraw,
                             .stakingWithdraw:
                            tx.direction = .Receive
                            return tx
                        default:
                            tx.direction = .Sent
                            return tx
                        }
                    })
                }
                
                if transactions.count >= self.listSize {
                    self.txnTableView.mj_footer.resetNoMoreData()
                } else {
                    self.txnTableView.mj_footer.endRefreshingWithNoMoreData()
                }
                
                self.dataSource.append(contentsOf: transactions)
                self.txnTableView.reloadData()
                self.txnTableView.mj_footer.isHidden = self.dataSource.count == 0
            case .fail(_, _):
                break
            }
        }
    }

    func initSubView(){
        
        navigationController?.view.addSubview(dropdownListView)
        dropdownListView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.size.height ?? 44) + 7).priorityHigh()
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(50)
        }
        dropdownListView.dropdownListDidHandle = { [weak self] wallet in
            guard let self = self else { return }
            self.selectedWallet = wallet
            self.txnTableView.mj_header.beginRefreshing()
        }
        
        
        view.addSubview(txnTableView)
        txnTableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(50 + 7)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)
        }
        
        super.leftNavigationTitle = "TransactionListVC_nav_title"
        txnTableView.emptyDataSetView { [weak self] view in
            let emptyView = self.self?.emptyViewForTableView(forEmptyDataSet: (self?.txnTableView)!, Localized("walletDetailVC_no_transactions_text"),"empty_no_data_img")
            emptyView?.backgroundColor = normal_background_color
            view.customView(emptyView)
            view.backgroundColor = normal_background_color
            view.isScrollAllowed(true)
        }
        
        txnTableView.mj_header = refreshHeader
        txnTableView.mj_footer = refreshFooter
        txnTableView.mj_footer.isHidden = true
    }
}

extension TransactionListViewController {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TransactionCell.self)) as! TransactionCell
        let tx = dataSource[indexPath.row]
        cell.updateCell(tx: tx)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transferVC = TransactionDetailViewController()
        transferVC.transaction = dataSource[indexPath.row]
        transferVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(transferVC, animated: true)
    }
}
