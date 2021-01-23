import 'package:flutter/material.dart';
import 'package:flutter_app/SharedPrefData/SharedPreferenceData.dart';
import 'package:flutter_app/pages/AuthenticatePage.dart';
import 'package:flutter_app/pages/HomePage.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:provider/provider.dart';
void main() async{
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedin =false;
  @override
  void initState() {
    getLoggedInStatus();
    super.initState();
  }
  getLoggedInStatus()async{
    await Data.getUserLoggedInSharedPreference().then((value) {
      if(value!=null){
        setState(() {
          isLoggedin=value;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context)=>AuthBloc(),
      child: MaterialApp(
        title: 'Group Chat Application',
        debugShowCheckedModeBanner: false,
        home: isLoggedin ? HomePage(): AuthenticatePage(),
      ),
    );
  }
}


