import 'package:flutter/material.dart';

void main() {
  runApp(ChatApp());
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
                      .push(MaterialPageRoute(builder: (context) {
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
