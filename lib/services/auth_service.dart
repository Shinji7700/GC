import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/FirebaseUserObjDet/user.dart';
import 'package:flutter_app/SharedPrefData/SharedPreferenceData.dart';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'database_service.dart';
class AuthService{
  final FirebaseAuth _auth=FirebaseAuth.instance;

  // create user object based on FirebaseUser
  User userFromFirebaseUser(FirebaseUser user) {
    return (user != null) ? User(uid: user.uid) : null;
  }

  Future<AuthResult> signInWithCredentail(AuthCredential credential) => _auth.signInWithCredential(credential);

  Stream<FirebaseUser> get currentUser=>_auth.onAuthStateChanged;


  Future<void> logout() => _auth.signOut();
  //sign in with email and password
  Future signInwithEmailAndPassword(String email, String password) async{
    try{
      AuthResult result=await _auth.signInWithEmailAndPassword(email: email, password: password);
      //renamed to UserCredential because of updated firebaseauth doesnt accept AuthResult
      FirebaseUser user=result.user;
      return userFromFirebaseUser(user);
    }
    catch(e){
      print(e.toString());
      return null;
    }
  }

// register with email and password
  Future registerWithEmailAndPassword(String fullName, String email, String password) async {
    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      //renamed to UserCredential because of updated firebaseauth doesnt accept AuthResult
      FirebaseUser user = result.user;

      // Create a new document for the user with uid
      await DatabaseService(uid: user.email).updateUserData(fullName, email, password);
      return userFromFirebaseUser(user);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

//sign out
  Future signOut() async {
    try {
      await Data.saveUserLoggedInSharedPreference(false);
      await Data.saveUserEmailSharedPreference('');
      await Data.saveUserNameSharedPreference('');

      return await _auth.signOut().whenComplete(() async {
        print("Logged out");
        await Data.getUserLoggedInSharedPreference().then((value) {
          print("Logged in: $value");
        });
        await Data.getUserEmailSharedPreference().then((value) {
          print("Email: $value");
        });
        await Data.getUserNameSharedPreference().then((value) {
          print("Full Name: $value");
        });
      });
    } catch(e) {
      print(e.toString());
      return null;
    }
  }
}
class AuthBloc{
  //facebook login
  final plugin = FacebookLogin(debug: true);
  final authService=AuthService();
  final fb=FacebookLogin();
  Stream<FirebaseUser> get currentUser=>authService.currentUser;
  FBLogin()async{
    print('Starting facebook login');
    final res = await fb.logIn(
        permissions: [
          FacebookPermission.publicProfile,
          FacebookPermission.email
        ]
    );

    switch(res.status){
      case FacebookLoginStatus.success:
        print('the user login through facebook');

        //Get Token
        final FacebookAccessToken fbToken=res.accessToken;

        //Convert to Auth Credential
        final AuthCredential credential=FacebookAuthProvider.getCredential(accessToken: fbToken.token);

        //User Credential to Sign in with Firebase
        final result = await authService.signInWithCredentail(credential);
        _updateLoginInfo();
        print('${result.user.displayName} is now logged in');
        break;
      case FacebookLoginStatus.cancel:
        print('the user cancelled the login');
        break;
      case FacebookLoginStatus.error:
        print('There was an error');
        break;
    }
  }

  logout(){
    authService.logout();
  }
}
class MyApp extends StatelessWidget {
  final plugin = FacebookLogin(debug: true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHome(plugin: plugin),
    );
  }
}

class MyHome extends StatefulWidget {
  final FacebookLogin plugin;

  const MyHome({Key key, @required this.plugin})
      : assert(plugin != null),
        super(key: key);

  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  String _sdkVersion;
  FacebookAccessToken _token;
  FacebookUserProfile _profile;
  String _email;
  String _imageUrl;
  final authService=AuthService();
  Stream<FirebaseUser> get currentUser=>authService.currentUser;

  @override
  void initState() {
    super.initState();

    _getSdkVersion();
    _updateLoginInfo();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _token != null && _profile != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login via Facebook example'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
        child: Center(
          child: Column(
            children: <Widget>[
              if (_sdkVersion != null) Text('SDK v$_sdkVersion'),
              if (isLogin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildUserInfo(context, _profile, _token, _email),
                ),
              isLogin
                  ? OutlineButton(
                child: const Text('Log Out'),
                onPressed: _onPressedLogOutButton,
              )
                  : OutlineButton(
                child: const Text('Log In'),
                onPressed: _onPressedLogInButton,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, FacebookUserProfile profile,
      FacebookAccessToken accessToken, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageUrl != null)
          Center(
            child: Image.network(_imageUrl),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('User: '),
            Text(
              '${profile.firstName} ${profile.lastName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Text('AccessToken: '),
        Text(
          accessToken.token,
          softWrap: true,
        ),
        if (email != null) Text('Email: $email'),
      ],
    );
  }

  Future<void> _onPressedLogInButton() async {
    await widget.plugin.logIn(permissions: [
      FacebookPermission.publicProfile,
      FacebookPermission.email,
    ]);
    await _updateLoginInfo();
  }

  Future<void> _onPressedExpressLogInButton(BuildContext context) async {
    final res = await widget.plugin.expressLogin();
    if (res.status == FacebookLoginStatus.success) {
      await _updateLoginInfo();
    } else {
      await showDialog<Object>(
        context: context,
        builder: (context) => const AlertDialog(
          content: Text("Can't make express log in. Try regular log in."),
        ),
      );
    }
  }

  Future<void> _onPressedLogOutButton() async {
    await widget.plugin.logOut();
    await _updateLoginInfo();
  }

  Future<void> _getSdkVersion() async {
    final sdkVesion = await widget.plugin.sdkVersion;
    setState(() {
      _sdkVersion = sdkVesion;
    });
  }


}


Future<void> _updateLoginInfo() async {
  //final plugin = widget.plugin;
  final token = await FacebookLogin().accessToken;
  FacebookUserProfile profile;
  String email;
  String imageUrl;

  if (token != null) {
    profile = await FacebookLogin().getUserProfile();
    if (token.permissions?.contains(FacebookPermission.email.name) ?? false) {
      email = await FacebookLogin().getUserEmail();
    }
    imageUrl = await FacebookLogin().getProfileImageUrl(width: 100);
  }

  var _token = token;
  var  _profile = profile;
  var _email = email;
  var _imageUrl = imageUrl;
  var _name = 'test';
  var _pass = 'test';




  print('email : $_email');
  await DatabaseService(uid: email).updateUserData(_name, _email, _pass);

}