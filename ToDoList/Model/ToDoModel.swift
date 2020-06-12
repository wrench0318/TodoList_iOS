//
//  RealmManager.swift
//  ToDoList
//
//  Created by 土橋正晴 on 2018/09/26.
//  Copyright © 2018 m.dobashi. All rights reserved.
//

import Foundation
import RealmSwift

final class ToDoModel: Object {

    // MARK: Properties
    
    /// todoのid(非推奨)
    @objc dynamic var id: String = ""
    
    /// Todoの期限
    @objc dynamic var todoDate: String?
    
    /// Todoのタイトル
    @objc dynamic var toDoName: String = ""
    
    /// Todoの詳細
    @objc dynamic var toDo: String = ""
    
    /// Todoの作成日時(プライマリキー)
    @objc dynamic var createTime: String?
    
    
    // createTimeをプライマリキーに設定
    override static func primaryKey() -> String? {
        return "createTime"
    }
    
    
    
    // MARK: init
    
    convenience init(id: String, toDoName: String, todoDate: String?, toDo: String, createTime: String?) {
        self.init()
        
        self.id = id
        self.toDoName = toDoName
        self.todoDate = todoDate
        self.toDo = toDo
        self.createTime = createTime
    }
    
    
    
    
    
    /// Realmのインスタンス化
    private class func initRealm(_ vc: UIViewController) -> Realm? {
        let realm: Realm
        
        do {
            realm = try Realm()
            
            return realm
        }
        catch {
            AlertManager().alertAction(vc, message: "エラーが発生しました") { _ in
                                        return
            }
        }
        
        return nil
    }
    
    
    /// ToDoを追加する
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - addValue: 登録するTodoの値
    class func addRealm(_ vc: UIViewController, addValue: ToDoModel) {
        guard let realm = initRealm(vc) else { return }
        
        let toDoModel: ToDoModel = ToDoModel(id: addValue.id,
                                             toDoName: addValue.toDoName,
                                             todoDate: addValue.todoDate,
                                             toDo: addValue.toDo,
                                             createTime: Format().stringFromDate(date: Date(), addSec: true)
        )
        
        
        do {
            try realm.write() {
                realm.add(toDoModel)
            }
            
            NotificationManager().addNotification(toDoModel: toDoModel) { result in
                NotificationCenter.default.post(name: Notification.Name(TableReload), object: nil)
                NotificationCenter.default.post(name: Notification.Name(toast), object: result)
            }
            
        }
        catch {
            AlertManager().alertAction(vc, message: "ToDoの登録に失敗しました") { _ in
                                        return
            }
        }
    
    }
    
    
    /// ToDoの更新
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - todoId: TodoId
    ///   - updateValue: 更新する値
    class func updateRealm(_ vc: UIViewController, todoId: String, updateValue: ToDoModel) {
        guard let realm = initRealm(vc) else { return }
        
        let toDoModel: ToDoModel = ToDoModel.findRealm(vc, todoId: updateValue.id, createTime: updateValue.createTime)!
        
        do {
            try realm.write() {
                toDoModel.toDoName = updateValue.toDoName
                toDoModel.todoDate = updateValue.todoDate
                toDoModel.toDo = updateValue.toDo
            }
            
            NotificationManager().addNotification(toDoModel: toDoModel) { result in
                NotificationCenter.default.post(name: Notification.Name(TableReload), object: nil)
                NotificationCenter.default.post(name: Notification.Name(toast), object: result)
            }
              
        }
        catch {
            AlertManager().alertAction(vc,
                                       message: "ToDoの更新に失敗しました") { _ in
                                        return
            }
        }
        
    }
    
    
    /// １件取得
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - todoId: TodoId
    ///   - createTime: Todoの作成時間
    /// - Returns: 取得したTodoの最初の1件を返す
    class func findRealm(_ vc: UIViewController, todoId: String, createTime: String?) -> ToDoModel? {
        guard let realm = initRealm(vc) else { return nil }
        
        if let _createTime = createTime {
            return (realm.objects(ToDoModel.self).filter("createTime == '\(String(describing: _createTime))'").first)
        } else {
            return(realm.objects(ToDoModel.self).filter("id == '\(todoId)'").first!)
        }
        
        
    }
    
    
    /// 全件取得
    /// - Parameter vc: 呼び出し元のViewController
    /// - Returns: 取得したTodoを全件返す
    class func allFindRealm(_ vc: UIViewController) -> Results<ToDoModel>? {
        guard let realm = initRealm(vc) else { return nil }
        
        return realm.objects(ToDoModel.self)
    }
    
    
    /// ToDoの削除
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - todoId: TodoId
    ///   - createTime: Todoの作成時間
    ///   - completion: 削除完了後の動作
    class func deleteRealm(_ vc: UIViewController, todoId: String, createTime: String?, completion: () -> Void) {
        guard let realm = initRealm(vc) else { return }
        
        let toDoModel: ToDoModel = ToDoModel.findRealm(vc, todoId: todoId, createTime: createTime)!
        
        NotificationManager().removeNotification([toDoModel.createTime!])
        
        do {
            try realm.write() {
                realm.delete(toDoModel)
            }
            completion()
        }
        catch {
            AlertManager().alertAction(vc,
                                       message: "ToDoの削除に失敗しました") { _ in
                                        return
            }
        }
        
        
        
    }
    
    
    /// 全件削除
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - completion: 削除完了後の動作
    class func allDeleteRealm(_ vc: UIViewController, completion:@escaping () ->Void) {
        guard let realm = initRealm(vc) else { return }
        
        AlertManager().alertAction(vc, title: "データベースの削除", message: "作成した問題や履歴を全件削除します", didTapDeleteButton: { (action) in
            try! realm.write {
                realm.deleteAll()
                print("ToDoを全件削除しました")
            }
            NotificationManager().allRemoveNotification()
            completion()

        }) { (action) in return }
        
    }
    
    
    
    /// 全件削除
    class func allDelete() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
            print("ToDoを全件削除しました")
        }
        NotificationManager().allRemoveNotification()
        
    }
    
    

}
