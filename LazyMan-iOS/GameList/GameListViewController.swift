//
//  GameListViewController.swift
//  LazyMan-iOS
//
//  Created by Nick Thompson on 2/18/18.
//  Copyright © 2018 Nick Thompson. All rights reserved.
//

import UIKit
import FSCalendar

protocol GameListViewControllerType: class
{
    func updateDate(date: Date)
    func updateCalendar(date: Date)
    func updateTodayButton(enabled: Bool)
    func updateRefreshing(refreshing: Bool)
    func updateGames()
}

class GameListViewController: UIViewController, GameListViewControllerType
{
    // MARK: - IBOutlets
    
    @IBOutlet private weak var leagueControl: UISegmentedControl!
    @IBOutlet private weak var calendar: FSCalendar!
    @IBOutlet private weak var calendarHeight: NSLayoutConstraint!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var todayButton: UIBarButtonItem!
    
    // MARK: - IBActions
    
    @IBAction func todayPressed(_ sender: Any)
    {
        self.presenter.todayPressed()
    }
    
    @IBAction func refreshPressed(_ sender: Any)
    {
        self.tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.height), animated: true)
        self.refreshControl.beginRefreshing()
        self.presenter.refreshPressed()
    }
    
    @IBAction func leagueChanged(_ sender: Any)
    {
        self.presenter.leagueChanged(league: self.leagueControl.selectedSegmentIndex == 1 ? .MLB : .NHL)
    }
    
    // MARK: - Properties
    
    private var presenter: GameListPresenterType!
    private var weekFormatter = DateFormatter()
    private var refreshControl = UIRefreshControl()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.presenter = GameListPresenter(view: self)
        self.presenter.viewDidLoad()
        
        self.calendar.scope = .week
        self.weekFormatter.dateFormat = "EEEE  MMMM d, yyyy"
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = self.refreshControl
        } else {
            self.tableView.backgroundView = self.refreshControl
        }
        self.refreshControl.addTarget(self, action: #selector(refreshGames), for: .valueChanged)
        self.refreshControl.tintColor = .lightGray
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.presenter.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.presenter.viewDidAppear()
    }
    
    // MARK: - GameListViewControllerType
    
    func updateDate(date: Date)
    {
        if self.calendar.scope == .week
        {
            UIView.animate(withDuration: 0.1, animations: {
                self.dateLabel.alpha = 0.2
            }) { (_) in
                self.dateLabel.text = self.weekFormatter.string(from: date)
                UIView.animate(withDuration: 0.1, animations: {
                    self.dateLabel.alpha = 1.0
                })
            }
        }
        else {
            self.dateLabel.text = self.weekFormatter.string(from: date)
        }
    }
    
    func updateCalendar(date: Date)
    {
        self.calendar.select(date, scrollToDate: true)
    }
    
    func updateTodayButton(enabled: Bool)
    {
        self.todayButton.isEnabled = enabled
    }
    
    func updateRefreshing(refreshing: Bool)
    {
        if refreshing
        {
            self.tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.height), animated: true)
            self.refreshControl.beginRefreshing()
        }
        else
        {
            self.refreshControl.endRefreshing()
        }
    }
    
    func updateGames()
    {
        self.tableView.reloadData()
    }
    
    // MARK: - Private
    
    @objc
    private func refreshGames()
    {
        self.presenter.refreshPressed()
    }
}

extension GameListViewController: FSCalendarDelegate
{
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition)
    {
        self.presenter.dateSelected(date: date)
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    {
        self.calendarHeight.constant = bounds.height
        self.view.layoutIfNeeded()
        
        if calendar.scope == .week {
            calendar.appearance.headerTitleColor = UIColor.clear
            UIView.animate(withDuration: 0.1, animations: {
                self.dateLabel.alpha = 1.0
            })
        }
        else {
            UIView.animate(withDuration: 0.001, animations: {
                self.dateLabel.alpha = 0.0
            }, completion: { (_) in
                calendar.appearance.headerTitleColor = UIColor.white
            })
        }
    }
}

extension GameListViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let gameViewController = navigationController?.storyboard?.instantiateViewController(withIdentifier: "GameView") as? GameViewController
        {
            gameViewController.presenter = GameViewPresenter(game: self.presenter.getGames()[indexPath.row])
            self.navigationController?.pushViewController(gameViewController, animated: true)
        }
    }
}

extension GameListViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.presenter.getGameCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as? GameTableViewCell else { return UITableViewCell() }
        
        cell.updateGameInfo(game: self.presenter.getGames()[indexPath.row])
        return cell
    }
}