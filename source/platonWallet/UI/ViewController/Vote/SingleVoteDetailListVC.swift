//
//  SingleVoteDetailListVC.swift
//  platonWallet
//
//  Created by Ned on 27/12/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import UIKit
import Localize_Swift

class SingleVoteDetailListVC : BaseViewController, UITableViewDelegate,UITableViewDataSource {

    let tableView = UITableView()
    
    var tableViewHeader : VoteDetailHeader?
    
    var candidate : CandidateBasicInfo?
    
    var tickets: [Ticket]?
    
    var dataSource : [SingleVote] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSubViews()
        initData()
    }
    
    @objc func onNavigationLeft(){
        
    }
    
    func initSubViews() {
        
        self.navigationItem.localizedText = "SingleVoteDetailListVC_nav_title"
        
        view.backgroundColor = UIViewController_backround
        
        tableView.backgroundColor = UIViewController_backround
        tableView.separatorStyle = .none
        tableView.delegate = self as UITableViewDelegate
        tableView.dataSource = (self as UITableViewDataSource)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        tableView.registerCell(cellTypes: [VoteDetailCell.self])
        tableView.tableHeaderView = tableviewHeader()
        
        tableView.emptyDataSetView { [weak self] view in
            view.customView(self?.emptyViewForTableView(forEmptyDataSet: (self?.tableView)!, Localized("MyVoteListVC_Empty_tips")))
        }
    }
    
    func tableviewHeader() -> VoteDetailHeader? {
        if tableViewHeader == nil{
            tableViewHeader = UIView.viewFromXib(theClass: VoteDetailHeader.self) as? VoteDetailHeader
        }
        return tableViewHeader
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let header = tableviewHeader()

        var height = header?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var newFrame = header?.frame
        if height == nil || height == 0.0{
            height = 98
        }
        newFrame?.size.height = height!;
        header?.frame = newFrame!
        tableView.tableHeaderView = header
    }
    
    func initData(){
        
        
        guard let candidate = candidate else {
            return
        }
        
        guard let tickets = tickets else {
            return
        }
        
        tableViewHeader?.updateView(candidate)
        
        let data = VotePersistence.getSingleVotesByCandidate(candidateId: candidate.id)
        
        var tempDic = [String:Ticket]()
        for ticket in tickets {
            tempDic[ticket.ticketId ?? ""] = ticket
        }
        for vote in data {
            for var t in vote.tickets {
                t = tempDic[t.ticketId ?? ""]!
            }
        }
        
        dataSource = data
  
        
//        VoteManager.sharedInstance.CandidateDetails(candidateId: candidateId!) { [weak self] (res, data) in
//            switch res{
//            case .success:
//                self?.tableViewHeader?.updateView(data as! Candidate)
//            default:
//                break
//            }
//            
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : VoteDetailCell = tableView.dequeueReusableCell(withIdentifier: String(describing: VoteDetailCell.self)) as! VoteDetailCell

        cell.updateCell(singleVote: dataSource[indexPath.section])

        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 226
    }
    
    
    //MARK: - UIButton Action
    
    @objc func onVote(){
        let voteVC = VotingViewController0()
        navigationController?.pushViewController(voteVC, animated: true)
    }

}
