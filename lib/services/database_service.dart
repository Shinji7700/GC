import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/SharedPrefData/SharedPreferenceData.dart';

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});
  final CollectionReference userCollection =
      Firestore.instance.collection('users');
  final CollectionReference groupCollection =
      Firestore.instance.collection('groups');
  //this allows us to create a collection in firestore

  //this allows users to match the data registered with the object and stores in firestore
  Future updateUserData(String fullName, String email, String password) async {
    return await userCollection.document(uid).setData({
      'fullName': fullName,
      'email': email,
      'password': password,
      'groups': [],
      'profilePic': ''
    });
  }

  //This allows users to create group
  Future createGroup(String userName, String groupName) async{
    DocumentReference groupDocRef =await groupCollection.add({
      'groupName': groupName,
      'groupIcon': '',
      'admin': userName,
      'members': [],
      //'messages': ,
      'groupId': '',
      'recentMessage': '',
      'recentMessageSender': ''
    });
    await groupDocRef.updateData({
      'members':FieldValue.arrayUnion([uid + '_' + userName]),
      'groupId':groupDocRef.documentID
    });
    DocumentReference userDocRef = userCollection.document(uid);
    return await userDocRef.updateData({
      'groups':FieldValue.arrayUnion([groupDocRef.documentID +'_'+groupName])
    });
  }
  // toggling the user group join like shifting from 1 group to another
  Future togglingGroupjoin(String groupId, String groupName, String userName) async{
    DocumentReference userDocRef= userCollection.document(uid);

    DocumentSnapshot userDocSnapshot = await userDocRef.get();

    DocumentReference groupDocRef = groupCollection.document(groupId);

    List<dynamic> groups = await userDocSnapshot.data['groups'];
    //in the updated firestore data is now a separate function so use it with  data() []

    if(groups.contains(groupId + '_' + groupName)) {

      await userDocRef.updateData({
        'groups': FieldValue.arrayRemove([groupId + '_' + groupName])
      });

      await groupDocRef.updateData({
        'members': FieldValue.arrayRemove([uid + '_' + userName])
      });
    }
    else {
      await userDocRef.updateData({
        'groups': FieldValue.arrayUnion([groupId + '_' + groupName])
      });

      await groupDocRef.updateData({
        'members': FieldValue.arrayUnion([uid + '_' + userName])
      });
    }
  }
  // has user joined the group
  Future<bool> isUserJoined(String groupId, String groupName, String userName) async {

    DocumentReference userDocRef = userCollection.document(uid);
    DocumentSnapshot userDocSnapshot = await userDocRef.get();

    List<dynamic> groups = await userDocSnapshot.data['groups'];


    if(groups.contains(groupId + '_' + groupName)) {
      //print('he');
      return true;
    }
    else {
      //print('ne');
      return false;
    }
  }


  // get user data
  Future getUserData(String email) async {
    QuerySnapshot snapshot = await userCollection.where('email', isEqualTo: email).getDocuments();
    try {
      // Grab first document or document at index 0
      final _doc = snapshot.documents?.first;

      // Print document at index 0
      print(snapshot.documents[0].data);

      if (_doc.exists) {
        await Data.saveUserNameSharedPreference(_doc.data['fullName']);
      }
    } on RangeError catch (e) {

    } catch (e) {
      // This will handle another uncaught exception
      print('Unknown exception ==> $e');
    }
  }


  // get user groups
  getUserGroups() async {
    // return await Firestore.instance.collection("users").where('email', isEqualTo: email).snapshots();
    return Firestore.instance.collection("users").document(uid).snapshots();
  }


  // send message
  sendMessage(String groupId, chatMessageData) {
    Firestore.instance.collection('groups').document(groupId).collection('messages').add(chatMessageData);
    Firestore.instance.collection('groups').document(groupId).updateData({
      'recentMessage': chatMessageData['message'],
      'recentMessageSender': chatMessageData['sender'],
      'recentMessageTime': chatMessageData['time'].toString(),
    });
  }


  // get chats of a particular group
  getChats(String groupId) async {
    return Firestore.instance.collection('groups').document(groupId).collection('messages').orderBy('time').snapshots();
  }


  // search groups
  searchByName(String groupName) {
    return Firestore.instance.collection("groups").where('groupName', isEqualTo: groupName).getDocuments();
  }
  }