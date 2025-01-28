import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class GroupsPage extends StatefulWidget {
  final String? userId;

  GroupsPage({required this.userId});

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedGroupId;
  final _groupNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  String _generatedInviteCode = '';

  List<Map<String, dynamic>> _userGroups = [];

  @override
  void initState() {
    super.initState();
  }

  Stream<QuerySnapshot> _fetchUserGroups() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  String _generateInviteCode() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => charset[random.nextInt(charset.length)])
        .join();
  }

  Future<void> _createGroup(String groupName) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to create a group')));
      return;
    }

    try {
      DocumentReference newGroupRef =
          await _firestore.collection('groups').add({
        'groupName': groupName,
        'createdBy': userId,
        'members': [userId],
      });

      final groupId = newGroupRef.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedGroupId', groupId);

      setState(() {
        _selectedGroupId = groupId;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Group "$groupName" created!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating group: $e')));
    }
  }

  Future<void> _generateAndUpdateInviteCode() async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a group first')));
      return;
    }

    try {
      final inviteCode = _generateInviteCode();
      await _firestore.collection('groups').doc(_selectedGroupId).update({
        'inviteCode': inviteCode,
      });

      setState(() {
        _generatedInviteCode = inviteCode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite code generated: $inviteCode')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invite code: $e')));
    }
  }

  Future<void> _joinGroup(String inviteCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to join a group')));
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid invite code')));
        return;
      }

      final groupRef = querySnapshot.docs.first.reference;
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedGroupId', groupRef.id);

      setState(() {
        _selectedGroupId = groupRef.id;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Joined group successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error joining group: $e')));
    }
  }

  void _showCreateGroupForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(labelText: 'Group Name'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final groupName = _groupNameController.text;
                  if (groupName.isNotEmpty) {
                    _createGroup(groupName);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Create Group', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showInviteDialog() async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a group first')));
      return;
    }

    // Fetch the selected group information
    final groupSnapshot =
        await _firestore.collection('groups').doc(_selectedGroupId).get();
    final groupName =
        groupSnapshot.exists ? groupSnapshot['groupName'] : 'No Name';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Invite Users'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected Group: $groupName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _generateAndUpdateInviteCode,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Generate Invite Code',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  if (_generatedInviteCode.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Invite Code: $_generatedInviteCode',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, color: Colors.green),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: _generatedInviteCode));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _joinCodeController,
                    decoration: InputDecoration(labelText: 'Enter Invite Code'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final inviteCode = _joinCodeController.text;
                      if (inviteCode.isNotEmpty) {
                        await _joinGroup(inviteCode);
                        Navigator.pop(context);
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Join Group',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _showInviteDialog,
            tooltip: 'Invite Users',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchUserGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No groups found.'));
          }

          final groups = snapshot.data!.docs.map((doc) {
            return {
              'id': doc.id,
              'groupName': doc['groupName'] ?? 'No Name',
              'members': doc['members'] ?? [],
              'inviteCode':
                  (doc.data() as Map<String, dynamic>).containsKey('inviteCode')
                      ? doc['inviteCode']
                      : '',
            };
          }).toList();

          return ListView(
            children: groups.map((group) {
              return Card(
                color:
                    _selectedGroupId == group['id'] ? Colors.green[100] : null,
                child: GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _selectedGroupId = group['id'];
                    });
                  },
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Icon(Icons.group, color: Colors.green), // Group Icon
                        SizedBox(width: 8),
                        Text(group['groupName']),
                      ],
                    ),
                    children: [
                      // Display 'Members' label
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Members',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Fetch member names dynamically
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection('groups')
                            .doc(group['id'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Text('Error loading group data');
                          }

                          final groupData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final memberIds =
                              List<String>.from(groupData['members'] ?? []);
                          return FutureBuilder<List<String>>(
                            future: _fetchMemberNames(memberIds),
                            builder: (context, membersSnapshot) {
                              if (membersSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!membersSnapshot.hasData) {
                                return Text('Error loading member names');
                              }

                              final memberNames = membersSnapshot.data!;
                              return Column(
                                children: memberNames
                                    .map((name) => Text(name))
                                    .toList(),
                              );
                            },
                          );
                        },
                      ),
                      if (group['inviteCode'] != '')
                        Text('Invite Code: ${group['inviteCode']}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupForm,
        child: Icon(Icons.group_add_rounded),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<List<String>> _fetchMemberNames(List<String> memberIds) async {
    final List<String> memberNames = [];
    for (String memberId in memberIds) {
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        memberNames.add(userDoc['firstName'] ?? 'No Name');
      }
    }
    return memberNames;
  }
}
