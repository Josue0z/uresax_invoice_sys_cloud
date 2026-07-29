import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uresax_invoice_sys_cloud/models/sale.element.abs.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';

class ImageSelectorWidget extends StatefulWidget {
  SaleElement? element;
  String? imageBase64;
  String? imageUrl;
  Function(String?, String?)? onChanged;
  Function(String? type)? onDelete;

  ImageSelectorWidget(
      {super.key,
      this.imageBase64,
      this.imageUrl,
      this.element,
      this.onChanged,
      this.onDelete});

  @override
  State<ImageSelectorWidget> createState() => _ImageSelectorWidgetState();
}

class _ImageSelectorWidgetState extends State<ImageSelectorWidget> {
  File? file;

  _onOpenPicker() async {
    final ImagePicker picker = ImagePicker();
    var res = await picker.pickImage(source: ImageSource.gallery);
    if (res != null) {
      file = File(res.path);
      var bytes = await file?.readAsBytes();
      widget.imageBase64 = base64Encode(bytes!);

      if (widget.onChanged != null) {
        widget.onChanged!(widget.imageBase64, widget.imageUrl);
      }
      setState(() {});
    }
  }

  _removeImagen() async {
    showLoader(context);
    try {
      if (widget.imageUrl != null) {
        await widget.element?.deleteImage();
      }
      file = null;
      widget.imageBase64 = null;
      if (widget.onChanged != null) {
        widget.onChanged!(widget.imageBase64, widget.imageUrl);
      }

      Navigator.pop(context);

      if (widget.imageUrl != null) {
        widget.imageUrl = null;
        widget.onDelete!('FROM-URL');
      }
      setState(() {});
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  Widget get imageWidget {
    if (widget.imageUrl != null) {
      print(widget.imageUrl);
      return Image.network(widget.imageUrl ?? '', width: 180);
    }
    if (widget.imageBase64 != null) {
      return Image.memory(base64Decode(widget.imageBase64 ?? ''), width: 180);
    }

    return Container();
  }

  Widget get contentFilled {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12)),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imageWidget,
            SizedBox(height: kDefaultPadding),
            TextButton(onPressed: _removeImagen, child: Text('Eliminar Imagen'))
          ],
        ),
      ),
    );
  }

  Widget get contentDefault {
    return GestureDetector(
      onTap: _onOpenPicker,
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12)),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 90, color: Colors.black12),
              SizedBox(height: kDefaultPadding),
              Text('Cargar Imagen')
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageBase64 == null && widget.imageUrl == null) {
      return contentDefault;
    }
    return contentFilled;
  }
}
