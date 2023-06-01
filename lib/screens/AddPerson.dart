import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddPerson extends StatefulWidget {
  final DocumentSnapshot person;

  AddPerson({Key key, this.person}) : super(key: key);

  @override
  _AddPersonState createState() => _AddPersonState();
}

class _AddPersonState extends State<AddPerson> {
  Firestore _db = Firestore.instance;
  TextEditingController _controllerName = TextEditingController();
  TextEditingController _controllerBirth = TextEditingController();
  MaskTextInputFormatter _maskFormatter = MaskTextInputFormatter(
      mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _userLogged;
  FocusNode _focusNodeName = FocusNode();
  FocusNode _focusNodeBirth = FocusNode();
  bool _savingPerson = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _loadUser() async {
    _userLogged = await _auth.currentUser();
  }

  _validateFields(BuildContext context) {
    var name = _controllerName.text;
    var birth = _controllerBirth.text;
    var birthUnmasked = birth.replaceAll(RegExp('[^\\d]'), '');
    var errorMessage = "";

    if (name.isEmpty) {
      setState(() {
        errorMessage = "Enter the name!";
      });
    } else if (birthUnmasked.isEmpty) {
      setState(() {
        errorMessage = "Enter the date of birth!";
      });
    } else if (birthUnmasked.length != 8) {
      setState(() {
        errorMessage = "Enter a valid date!";
      });
    }

    if (errorMessage.isNotEmpty) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } else {
      setState(() {
        _savingPerson = true;
      });

      if (widget.person != null) {
        _db
            .collection("users")
            .document(_userLogged.uid)
            .collection("people")
            .document(widget.person.documentID)
            .setData({
              "name": name,
              "birth": birth,
            })
            .then((_) { _saveSuccess(context, name); })
            .catchError((error) { _saveError(context, name, error); });
      } else {
        _db
            .collection("users")
            .document(_userLogged.uid)
            .collection("people")
            .add({
              "name": name,
              "birth": birth,
              "created": DateTime.now().millisecondsSinceEpoch,
            })
            .then((_) { _saveSuccess(context, name); })
            .catchError((error) { _saveError(context, name, error); });
      }
    }
  }

  _saveSuccess(BuildContext context, String name) {
    setState(() {
      _savingPerson = false;
    });

    if (widget.person == null) {
      _controllerName.clear();
      _controllerBirth.clear();

      FocusScope.of(context).requestFocus(_focusNodeName);
    } else {
      FocusScope.of(context).unfocus();
    }

    Scaffold.of(context).showSnackBar(
        SnackBar(content: Text(
            widget.person == null
            ? "$name successfully registered."
            : "$name updated successfully.",
        )));
  }

  _saveError(BuildContext context, String name, Object error) {
    setState(() {
      _savingPerson = false;
    });

    AlertDialog alert = AlertDialog(
      title: Text("Oops"),
      content: Text("Something went wrong, try again!\n\n$error"),
      actions: [
        FlatButton(
          child: Text("OK"),
          onPressed: () {
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

    if (widget.person != null) {
      _controllerName.text = widget.person.data["name"];
      _controllerBirth.text = widget.person.data["birth"];
    }

    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();

    _controllerName.dispose();
    _controllerBirth.dispose();
    _focusNodeName.dispose();
    _focusNodeBirth.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.person == null ? "Register new person" : "Update person"),
      ),
      body: Builder(
        builder: (context) => Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _controllerName,
                      focusNode: _focusNodeName,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        hintText: "Name",
                      ),
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_focusNodeBirth);
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: TextField(
                      inputFormatters: [_maskFormatter],
                      controller: _controllerBirth,
                      focusNode: _focusNodeBirth,
                      keyboardType: TextInputType.datetime,
                      style: TextStyle(fontSize: 20),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        suffix: Text("dd/mm/yyyy"),
                        hintText: "Date of birth",
                      ),
                      onSubmitted: (_) {
                        _validateFields(context);
                      },
                    ),
                  ),
                  _savingPerson
                      ? Padding(
                          padding: EdgeInsets.all(25),
                          child: CircularProgressIndicator(),
                        )
                      : Padding(
                          padding: EdgeInsets.only(top: 25),
                          child: SizedBox(
                            width: double.infinity,
                            child: RaisedButton(
                              child: Text(
                                widget.person == null
                                    ? "Register person"
                                    : "Save changes",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20
                                ),
                              ),
                              color: Colors.green,
                              padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                              onPressed: () {
                                _validateFields(context);
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
