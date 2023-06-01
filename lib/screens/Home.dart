import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_ages/screens/AddPerson.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _streamController = StreamController<QuerySnapshot>.broadcast();
  Firestore _db = Firestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _userLogged;
  List<DocumentSnapshot> _documents = List();

  _loadUser() async {
    _userLogged = await _auth.currentUser();

    _listPeople();
  }

  _listPeople() async {
    _db
        .collection("users")
        .document(_userLogged.uid)
        .collection("people")
        .orderBy("name")
        .snapshots()
        .listen((data) {
          _streamController.add(data);
        });
  }

  _calculateAge(String birth) {
    var dateParse = DateFormat("dd/MM/yyyy").parse(birth);
    var dateString = DateFormat("yyyy-MM-dd").format(dateParse);
    var parsedDate = DateTime.parse(dateString);

    Duration duration = DateTime.now().difference(parsedDate);

    var years = duration.inDays ~/ 365.25;

    if (years > 0) {
      var months = (duration.inDays - (years * 365.25)) ~/ 30.41;
      var days = (duration.inDays - (years * 365.25) - (months * 30.41)).toInt();

      return "$years years, $months months and $days days";
    } else {
      return "$years years";
    }
  }

  _showAlertDialog(BuildContext context, int index) {
    DocumentSnapshot person = _documents[index];
    String id = person.documentID;
    String name = person.data['name'];

    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: Text("Would you like to delete this person?"),
      actions: [
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            setState(() {
              _listPeople();
            });

            Navigator.pop(context);
          },
        ),
        FlatButton(
          child: Text("Confirm"),
          onPressed: () {

            _db
                .collection("users")
                .document(_userLogged.uid)
                .collection("people")
                .document(id)
                .delete()
                .then((_) {
                  Scaffold.of(context).showSnackBar(
                      SnackBar(content: Text("$name was deleted.")));
                });

            Navigator.pop(context);

          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();

    _streamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Family Ages"),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: (choice) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Confirmation"),
                    content: Text("Do you want to disconnect from this account?"),
                    actions: [
                      FlatButton(
                        child: Text("Cancel"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      FlatButton(
                        child: Text("Confirm"),
                        onPressed: () {
                          _auth.signOut();

                          SystemNavigator.pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            padding: EdgeInsets.all(0),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: "sign_out",
                  child: Text("Sign out"),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              if (!snapshot.hasError) {
                QuerySnapshot data = snapshot.data;
                _documents = data.documents.toList();

                if (data.documents.length == 0) {
                  return Container(
                    child: Center(
                      child: Text("No family members registered."),
                    ),
                  );
                } else {
                  return ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    itemCount: data.documents.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot person = _documents[index];

                      String name = person.data["name"];
                      String birth = person.data["birth"];

                      String age = _calculateAge(birth);
                      String subtitle = "Birth: $birth\nAge: $age";

                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          _showAlertDialog(context, index);
                        },
                        background: Container(
                          color: Colors.red,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                          title: Text(
                            name,
                            style: TextStyle(fontSize: 20),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return AddPerson(person: person);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              }
              break;
          }

          return Container(
            child: Center(
              child: Text("Oops... something went wrong :("),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return AddPerson();
              },
            ),
          );
        },
      ),
    );
  }
}
