
import 'package:flutter/material.dart';
import 'package:multiselect/multiselect.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';

class FilterProductsModal extends StatefulWidget {
  List<Category> categories;
  FilterProductsModal({super.key,required this.categories});

  @override
  State<FilterProductsModal> createState() => _FilterProductsModalState();
}

class _FilterProductsModalState extends State<FilterProductsModal> {

    _onSaved() async {
    Navigator.pop(context, {
      'categories': widget.categories
    });
  }

  @override
  Widget build(BuildContext context) {
     return Dialog(
      child: Form(
          child: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(kDefaultPadding),
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Filtros',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: Theme.of(context).primaryColor))),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close))
              ],
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            DropDownMultiSelect(
              options:categories,
              selectedValues: widget.categories,
              isDense: true,
              whenEmpty: 'CATEGORIA',
              decoration: InputDecoration(
                  labelText: 'CATEGORIA',
                  hintText: 'SELECCIONAR',
                   disabledBorder: InputBorder.none,
                   border: InputBorder.none,
                     contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                       
                      ),
                  constraints: BoxConstraints(
                    minHeight: 100
                  ),
                  ),
              menuItembuilder: (category) {
                return ListTile(
                  title: Text(category.name ?? ''),
                  selected: widget.categories.contains(category),
                  onTap: () {
                    setState(() {
                      if (category.id != null) {
                        if (widget.categories.contains(category)) {
                          widget.categories.remove(category);
                        } else {
                          widget.categories.add(category);
                        }
                   
                      }else{
                        widget.categories = [];
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
              childBuilder: (categories) {
                return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: kDefaultPadding),
                    child: Wrap(
                      
                      children: List.generate(categories.length, (i){
                        var category = categories[i];
                        return Container(
                          padding: EdgeInsets.all(kDefaultPadding/3),
                          margin: EdgeInsets.only(
                            right: kDefaultPadding/3,
                            top: kDefaultPadding/3,
                            bottom: kDefaultPadding/3
                          ),
                          decoration:BoxDecoration(
                            borderRadius: BorderRadius.circular(90),
                            color: Theme.of(context).primaryColor.withOpacity(0.04)
                          ),
                          child: Text(category.name ?? '',style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context).primaryColor
                          ),),
                        );
                      }),
                    ),
                    );
              },
              onChanged: (_) {},
            ),

            SizedBox(height: kDefaultPadding),
            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  ElevatedButton(onPressed: _onSaved, child: Text('APLICAR')),
            )
          ],
        ),
      )),
    );
  }
}