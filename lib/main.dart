import 'dart:html';
import 'dart:js';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  //事前処理
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase初期化
  await Firebase.initializeApp();
  runApp(ChatApp());
}

// 更新可能なデータ
class UserState extends ChangeNotifier {
  User? user;

  void setUser(User newUser) {
    user = newUser;
    notifyListeners();
  }
}

class ChatApp extends StatelessWidget {
  // ユーザーの情報を管理するデータ
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserState>(
        create: (context) => UserState(),
        child: MaterialApp(
          //アプリ名
          title: 'ChatApp',
          theme: ThemeData(
            //テーマカラー
            primarySwatch: Colors.blue,
          ),
          //ログイン画面を表示
          home: LoginPage(),
        ));
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';

  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // メールアドレス入力
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              // パスワード入力
              TextFormField(
                decoration: InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,
                // ユーザー登録ボタン
                child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // メール・パスワードでユーザー登録
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final result =
                            await auth.createUserWithEmailAndPassword(
                                email: email, password: password);
                        // ユーザー情報を更新
                        userState.setUser(result.user!);
                        // ユーザー登録に成功した場合
                        // チャット画面に繊維＋ログイン画面を破棄
                        await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                          return ChatPage(); // Providerの導入によって引数に状態を渡さない
                        }));
                      } catch (e) {
                        // ユーザー登録に失敗した場合
                        setState(() {
                          infoText = "登録に失敗しました: ${e.toString()}";
                        });
                      }
                    },
                    child: Text('ユーザー登録')),
              ),
              const SizedBox(
                height: 8,
              ),
              Container(
                width: double.infinity,
                // ログイン登録ボタン
                child: OutlinedButton(
                    onPressed: () async {
                      try {
                        // メール・パスワードでログイン
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final result = await auth.signInWithEmailAndPassword(
                            email: email, password: password);
                        // ユーザー情報を更新
                        userState.setUser(result.user!);
                        // ログインに成功した場合
                        // チャット画面に遷移＋ログイン画面を破棄
                        await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                          return ChatPage(); // Providerの導入によって引数に状態を渡さない
                        }));
                      } catch (e) {
                        // ログインに失敗した場合
                        setState(() {
                          infoText = "ログインに失敗しました${e.toString()}";
                        });
                      }
                    },
                    child: Text('ログイン')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// チャット画面用Widget
class ChatPage extends StatelessWidget {
  // コンストラクタを作成して、引数からユーザー情報を受け取れるようにする
  // ChatPage(this.user);
  // →Providerの導入によって、コンストラクタ＋引数で状態を受け取らなくて良くなった

  // ユーザー情報
  // final User user; Providerなしのパターンの記述

  @override
  Widget build(BuildContext context) {
    // ユーザー情報をbuildメソッド内で受け取る
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
        appBar: AppBar(
          title: Text('チャット'),
          actions: <Widget>[
            IconButton(
                onPressed: () async {
                  // ログアウト処理
                  // 内部で保持しているログイン情報等が初期化される
                  // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫）
                  await FirebaseAuth.instance.signOut();
                  // ログイン画面に遷移＋チャット画面を破棄
                  await Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(builder: (context) {
                    return LoginPage();
                  }));
                },
                icon: Icon(Icons.logout))
          ],
        ),
        body: Column(
          children: [
            Container(
                padding: EdgeInsets.all(8),
                child: Text('ログイン情報:${user.email}')),
            Expanded(
                // FutureBuilder
                // 非同期処理の結果を元にWidgetを作れる
                child: StreamBuilder<QuerySnapshot>(
              // 投稿メッセージ一覧を取得（非同期処理）
              // 投稿日時でソート
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                // データが取得できた場合
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  // 取得した投稿メッセージ一覧を元にリスト表示
                  return ListView(
                    children: documents.map(
                      (document) {
                        return Card(
                          child: ListTile(
                            title: Text(document['text']),
                            subtitle: Text(document['email']),
                            // 自分の投稿メッセージの場合は削除ボタンを表示
                            trailing: document['email'] == user.email
                                ? IconButton(
                                    onPressed: () async {
                                      // 投稿メッセージのドキュメントを削除
                                      await FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(document.id)
                                          .delete();
                                    },
                                    icon: Icon(Icons.delete))
                                : null,
                          ),
                        );
                      },
                    ).toList(),
                  );
                }
                return Center(
                  child: Text('読込中'),
                );
              },
            ))
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            // 投稿画面に遷移
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) {
              return AddPostPage(); // Providerの導入に伴って、引数に状態を渡す必要がなくなった
            }));
          },
        ));
  }
}

class AddPostPage extends StatefulWidget {
  // ↓Providerの導入に伴ってコンストラクタ＋引数で状態を受け取らなくて良い
  // 引数からユーザー情報を受け取る
  // AddPostPage(this.user);
  // ユーザー情報
  // final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

// 投稿画面用Widget
class _AddPostPageState extends State<AddPostPage> {
  //入力した投稿メッセージ
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    // class AddPostPage extends StatefulWidgetの代わりに
    // build()内でユーザー情報を受け取る

    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 投稿メッセージ入力
              TextFormField(
                decoration: InputDecoration(labelText: '投稿メッセージ'),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    messageText = value;
                  });
                },
              ),
              const SizedBox(
                height: 8,
              ),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('投稿'),
                  onPressed: () async {
                    final date =
                        DateTime.now().toLocal().toIso8601String(); // 現在の日時

                    // Provider導入前は = widget.user.email
                    final email = user.email; // AddPostPage のデータを参照
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('posts') // コレクションID指定
                        .doc() // ドキュメントID自動生成
                        .set({
                      'text': messageText,
                      'email': email,
                      'date': date
                    });
                    // ひとつ前の画面に戻る
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ChangeNotifierを継承すると変更可能なデータを渡せる
class CountData extends ChangeNotifier {
  int count = 0;

  void increment() {
    count = count + 1;
    // 値が変更したことを知らせる
    //  >> UIを再構築する
    notifyListeners();
  }
}

class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Provider<T>() で子Widgetにデータを渡す
    // ※ 渡すデータの クラス と <T> は揃える

    return ChangeNotifierProvider<CountData>(
      // 渡すデータ
      create: (context) => CountData(),
      child: Container(
        child: ChildWidget(),
      ),
    );
  }
}

class ChildWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Provider.of<T>(context) で親Widgetからデータを受け取る
    // ※ 受け取るデータの クラス と <T> は揃える
    final CountData data = Provider.of<CountData>(context);

    return Column(
      children: <Widget>[
        // 受け取ったデータを使いUI作成
        Text('count is ${data.count.toString()}'),
        ElevatedButton(
            onPressed: () {
              // データ更新
              data.increment();
            },
            child: Text('Increment'))
      ],
    );
  }
}
