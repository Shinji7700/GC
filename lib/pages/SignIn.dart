import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/SharedPrefData/SharedPreferenceData.dart';
import 'package:flutter_app/UIPurpose/Decorations.dart';
import 'package:flutter_app/UIPurpose/Loading.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/database_service.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:provider/provider.dart';

import 'HomePage.dart';


class SignInPage extends StatefulWidget {
  final Function toggleView;
  SignInPage({this.toggleView});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var authBloc=Provider.of<AuthBloc>(context,listen: false);
    loginstatesubscription=authBloc.currentUser.listen((fbUser) {
      if(fbUser!=null){
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>HomePage()));
      }
    });
  }
  StreamSubscription<FirebaseUser>loginstatesubscription;
//dispose
  @override
  void dispose(){
    loginstatesubscription.cancel();
    super.dispose();
  }
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  _onSignIn() async {
    if (_formKey.currentState.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _auth.signInwithEmailAndPassword(email, password).then((result) async {
        if (result != null) {
          QuerySnapshot userInfoSnapshot = await DatabaseService().getUserData(email);

          await Data.saveUserLoggedInSharedPreference(true);
          await Data.saveUserEmailSharedPreference(email);
          try {
            // Grab first document or document at index 0
            final fullName = userInfoSnapshot.documents[0].data['fullName'];

            // Print document at index 0
            print(userInfoSnapshot.documents[0].data);

            if (fullName.isNotEmpty) {
              await Data.saveUserNameSharedPreference(fullName);
            }
          } on RangeError catch (e) {
            // Show an error message
            print(e);
          } catch (e){
            print('Unhandled Exception ==> $e');
          }


          print("Signed In");
          await Data.getUserLoggedInSharedPreference().then((value) {
            print("Logged in: $value");
          });
          await Data.getUserEmailSharedPreference().then((value) {
            print("Email: $value");
          });
          await Data.getUserNameSharedPreference().then((value) {
            print("Full Name: $value");
          });

          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
        }
        else {
          setState(() {
            error = 'Error signing in!';
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var authBloc=Provider.of<AuthBloc>(context);
    return _isLoading ? Loading() : Scaffold(
        body: Form(
          key: _formKey,
          child: Container(
            color: Colors.black,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text("Create or Join Groups", style: TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.bold)),

                    SizedBox(height: 30.0),

                    Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 25.0)),

                    SizedBox(height: 20.0),

                    TextFormField(
                      style: TextStyle(color: Colors.white),
                      decoration: textInputDecoration.copyWith(labelText: 'Email'),
                      validator: (val) {
                        return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val) ? null : "Please enter a valid email";
                      },

                      onChanged: (val) {
                        setState(() {
                          email = val;
                        });
                      },
                    ),

                    SizedBox(height: 15.0),

                    TextFormField(
                      style: TextStyle(color: Colors.white),
                      decoration: textInputDecoration.copyWith(labelText: 'Password'),
                      validator: (val) => val.length < 6 ? 'Password not strong enough' : null,
                      obscureText: true,
                      onChanged: (val) {
                        setState(() {
                          password = val;
                        });
                      },
                    ),

                    SizedBox(height: 20.0),

                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: RaisedButton(
                          elevation: 0.0,
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          child: Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16.0)),
                          onPressed: () {
                            _onSignIn();
                          }
                      ),
                    ),

                    SizedBox(height: 10.0),

                    Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Register here',
                            style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              widget.toggleView();
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10.0),

                    Text(error, style: TextStyle(color: Colors.red, fontSize: 14.0)),
                    SizedBox(height: 10.0),
                    SignInButton(
                        Buttons.Facebook,
                        onPressed: ()=>authBloc.FBLogin()
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
    );
  }
}
