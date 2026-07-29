import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/modals/user.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/box.dart';
import 'package:uresax_invoice_sys_cloud/models/user.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];

  _showUserModal({required User user, bool editing = false}) async {
    boxes = [
      Box(name: 'CAJA'),
      ...await Box.get()
    ];
    var res = await showDialog(
        context: context,
        builder: (ctx) => UserEditorModal(user: user, editing: editing));

    if (res == 'CREATE' || res == 'UPDATE') {
      _initAsync();
    }
  }

  _initAsync() async {
    try {
      users = await User.get();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    if(!mounted)return;
    _initAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TUS USUARIOS (${users.length})'),
        actions:[
          CircleAvatar(
            child:IconButton(
              tooltip: 'AGREGAR USUARIO',
              icon:Icon(Icons.add),
              onPressed: (){
                _showUserModal(user: User());
              },
            )
          ),
          SizedBox(width: kDefaultPadding)
        ]
      ),
      body: ListView.separated(
        separatorBuilder: (ctx, i) => const Divider(),
        itemCount: users.length,
        itemBuilder: (ctx, index) {
          var user = users[index];
          return ListTile(
            key: ValueKey(user.id),
            minVerticalPadding: kDefaultPadding,
            leading: Container(
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                color: Theme.of(context).primaryColor.withOpacity(0.04),
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
            ),
            title: Text(user.name?.toUpperCase() ?? '',
                style: Theme.of(context).textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username ?? ''),
                SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Container(
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(user.roleName ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white)),
                )
              ],
            ),
            trailing: Wrap(
              children: [
                user.roleId == 3 && (currentUser?.id != user.id)
                    ? SizedBox()
                    : IconButton(
                        onPressed: () {
                          _showUserModal(user: user, editing: true);
                        },
                        icon: Icon(Icons.edit)),
                SizedBox(
                  width: kDefaultPadding,
                )
              ],
            ),
          );
        },
      ),
     
    );
  }
}
