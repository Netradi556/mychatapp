import 'dart:html';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Firebase初期化
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyFirestorePage(),
    );
  }
}

class MyFirestorePage extends StatefulWidget {
  @override
  _MyFirestorePageState createState() => _MyFirestorePageState();
}

class _MyFirestorePageState extends State<MyFirestorePage> {
  // 作成したドキュメント一覧
  List<DocumentSnapshot> documentList = [];

  // 指定したドキュメントの情報
  String orderDocumentInfo = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
                onPressed: () async {
                  // ドキュメント作成
                  await FirebaseFirestore.instance
                      .collection('users') // コレクションID
                      .doc('id_abc') //ドキュメントID
                      .set({'name': '鈴木', 'age': 40});
                },
                child: Text('コレクション＋ドキュメント作成')),
            ElevatedButton(
                onPressed: () async {
                  // サブコレクション内にドキュメント作成
                  await FirebaseFirestore.instance
                      .collection('users') // コレクションID
                      .doc('id_abc') // ドキュメントID <<usersコレクション内のドキュメント>>
                      .collection('orders') // サブコレクションID
                      .doc('id_123') // ドキュメントID <<サブコレクション内のドキュメント>>
                      .set({'price': 600, 'date': '9/13'});
                },
                child: Text('サブコレクション＋ドキュメント作成')),
            ElevatedButton(
                onPressed: () async {
                  // コレクション内のドキュメント一覧を取得
                  final snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .get();
                  // 取得したドキュメント一覧をUIに反映
                  setState(() {
                    documentList = snapshot.docs; // エラーになってしまう、テキストでは.documents
                  });
                },
                child: Text('ドキュメント一覧取得')),
            Column(
              children: documentList.map((document) {
                return ListTile(
                  title: Text('${document['name']}さん'),
                  subtitle: Text('${document['aget']}歳'),
                );
              }).toList(),
            ),
            ElevatedButton(
                child: Text('ドキュメントを指定して取得'),
                onPressed: () async {
                  // コレクションIDとドキュメントIDを指定して取得
                  final document = await FirebaseFirestore.instance
                      .collection('users')
                      .doc('id_abc')
                      .collection('orders')
                      .doc('id_123')
                      .get();
                  // 取得したドキュメントの情報をUIに反映
                  setState(() {
                    orderDocumentInfo =
                        '${document['date']} ${document['price']}円';
                  });
                }),
            // ドキュメントの情報を表示
            ListTile(title: Text(orderDocumentInfo)),
            ElevatedButton(
                onPressed: () async {
                  // ドキュメント更新
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc('id_abc')
                      .update({'age': 41});
                },
                child: Text('ドキュメント更新')),
            ElevatedButton(
                onPressed: () async {
                  // ドキュメント削除
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc('id_abc')
                      .collection('orders')
                      .doc('id_123')
                      .delete();
                },
                child: Text('ドキュメント削除'))
          ],
        ),
      ),
    );
  }
}

class MyAuthPage extends StatefulWidget {
  @override
  _MyAuthPageState createState() => _MyAuthPageState();
}

class _MyAuthPageState extends State<MyAuthPage> {
  // 入力されたメールアドレス
  String newUserEmail = "";
  // 入力されたパスワード
  String newUserPassword = "";
  // 入力されたメールアドレス（ログイン）
  String loginUserEmail = "";
  // 入力されたパスワード（ログイン）
  String loginUserPassword = "";
  // 登録・ログインに関する情報を表示
  String infoText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              TextFormField(
                // テキスト入力のラベルを設定
                decoration: InputDecoration(labelText: "メールアドレス"),
                onChanged: (String value) {
                  setState(() {
                    newUserEmail = value;
                  });
                },
              ),
              const SizedBox(
                height: 8,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "パスワード"),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    newUserPassword = value;
                  });
                },
              ),
              const SizedBox(
                height: 8,
              ),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      // メールアドレス/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final UserCredential result =
                          await auth.createUserWithEmailAndPassword(
                              email: newUserEmail, password: newUserPassword);

                      // 登録したユーザー情報
                      final User user = result.user!;
                      setState(() {
                        infoText = "登録OK: ${user.email}";
                      });
                    } catch (e) {
                      // 登録に失敗したユーザー
                      setState(() {
                        infoText = "登録NG: ${e.toString()}";
                      });
                    }
                  },
                  child: Text("ユーザー登録")),
              TextFormField(
                decoration: InputDecoration(labelText: "メールアドレス"),
                onChanged: (String value) {
                  setState(() {
                    loginUserEmail = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "パスワード"),
                onChanged: (String value) {
                  setState(() {
                    loginUserPassword = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final UserCredential result =
                          await auth.signInWithEmailAndPassword(
                              email: loginUserEmail,
                              password: loginUserPassword);
                      // ログインに成功した場合
                      final User user = result.user!;
                      setState(() {
                        infoText = "ログインOK:${user.email}";
                      });
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = "ログインNG:${e.toString()}";
                      });
                    }
                  },
                  child: Text("ログイン")),
              const SizedBox(height: 8),
              Text(infoText)
            ],
          ),
        ),
      ),
    );
  }
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //アプリ名
      title: 'ChatApp',
      theme: ThemeData(
        //テーマカラー
        primarySwatch: Colors.blue,
      ),
      //ログイン画面を表示
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // チャット画面に繊維＋ログイン画面を破棄
          ElevatedButton(
              onPressed: () async {
                await Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (context) {
                  return ChatPage();
                }));
              },
              child: Text('ログイン'))
        ],
      ),
    ));
  }
}

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                onPressed: () async {
                  //投稿画面に遷移
                  await Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(builder: (context) {
                    return LoginPage();
                  }));
                },
                icon: Icon(Icons.close))
          ],
          title: Text('チャット'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            // 投稿画面に遷移
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) {
              return AddPostPage();
            }));
          },
        ));
  }
}

// 投稿画面用Widget
class AddPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('戻る'),
          onPressed: () {
            // １つ前の画面に戻る
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
