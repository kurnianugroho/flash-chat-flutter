import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _loggedInUser;
  bool _showSpinner = false;

  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    _loggedInUser = _auth.currentUser!;
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                //Implement logout functionality
                setState(() {
                  _showSpinner = true;
                });

                try {
                  await _auth.signOut();
                  Navigator.pop(context);
                } catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()),
                  ));
                } finally {
                  setState(() {
                    _showSpinner = false;
                  });
                }
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _showSpinner,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      bool fromOther;
                      var messages = snapshot.data?.docs.reversed;
                      if (messages != null) {
                        List<Widget> messagesWidget = [];
                        for (var message in messages) {
                          fromOther = message['sender'] != _loggedInUser.email;
                          Widget messageWidget = Align(
                              alignment: fromOther
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                  margin: fromOther
                                      ? EdgeInsets.only(
                                          bottom: 25.0, left: 10.0)
                                      : EdgeInsets.only(
                                          bottom: 25.0, right: 10.0),
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: fromOther
                                        ? Colors.lightGreen
                                        : Colors.lightBlue,
                                    borderRadius: fromOther
                                        ? BorderRadius.only(
                                            topRight: Radius.circular(15.0),
                                            bottomRight: Radius.circular(15.0),
                                            topLeft: Radius.circular(15.0))
                                        : BorderRadius.only(
                                            topRight: Radius.circular(15.0),
                                            bottomLeft: Radius.circular(15.0),
                                            topLeft: Radius.circular(15.0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2.0,
                                        spreadRadius: 2.0,
                                        offset: Offset(2.0,
                                            2.0), // shadow direction: bottom right
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: fromOther
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        message['sender'],
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 2.0,
                                      ),
                                      Text(
                                        message['text'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.0,
                                        ),
                                      ),
                                    ],
                                  )));
                          messagesWidget.add(messageWidget);
                        }

                        return Expanded(
                          child: ListView(reverse: true, children: [
                            Column(
                              children: messagesWidget,
                            ),
                          ]),
                        );
                      } else {
                        return Container();
                      }
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  }),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () async {
                        //Implement send functionality.
                        try {
                          await _firestore.collection('messages').add({
                            'text': _messageController.text,
                            'sender': _loggedInUser.email,
                            'timestamp': Timestamp.now()
                          });
                          _messageController.text = '';
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                          ));
                        }
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
