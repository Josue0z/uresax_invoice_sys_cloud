
import 'package:flutter/material.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class ToolButtonWidget extends StatelessWidget {
  IconData icon;
  VoidCallback? onTap;
  ToolButtonWidget({super.key,required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      
      color: Colors.transparent,
      shape: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white12
        )
      ),
      child: SizedBox(
        width: 70,
        height: kDefaultNavbarHeight,
        child: Ink(
          
          child: InkWell(
            focusNode: FocusNode(skipTraversal: true),
            onTap: (){
              if(onTap != null){
                onTap!();
              }
            },
          child: Icon(icon),
          ),
        ),
      ),
    );
  }
}