import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/modals/category.editor.modal.dart';
import 'package:uresax_invoice_sys_cloud/models/categorie.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/scrollmove.event.widget.dart';

class CategoriesPage extends StatefulWidget {
  bool selectorMode;
  Category? parentCategory;
  bool subCategories;
  CategoriesPage(
      {super.key,
      this.selectorMode = false,
      this.parentCategory,
      this.subCategories = false});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> options = [];
  List<Category> categories = [];
  Future? future;
  final TextEditingController _searchController = TextEditingController();
  ScrollController scrollControllerY = ScrollController();

  _onSelected(Category? category) {
    if (widget.subCategories) {
      Navigator.pop(context);
      Navigator.pop(context, category);
    } else {
      Navigator.pop(context, category);
    }
  }

  _showModal({bool editing = false, required Category category}) async {
    var res = await showDialog(
        context: context,
        builder: (ctx) => CategoryEditorModal(
              editing: editing,
              category: category,
              isSubcategory: widget.subCategories,
              parentCategory: widget.parentCategory
            ));

    if (res == 'CREATE') {
      setState(() {
        future = _initAsync();
      });
    }

    if (res == 'UPDATE') {
      setState(() {
        future = _initAsync();
      });
    }
  }

  _onSelectOption(int value, Category category) async {
    switch (value) {
      case 1:
        _showModal(editing: true, category: category);
        break;
      case 2:
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (ctx) => CategoriesPage(
                    selectorMode: widget.selectorMode,
                    parentCategory: category,
                    subCategories: true)));

        break;
    }
  }

  Widget get contentFilled {
    return ScrollMoveEventWidget(
        scrollControllerY: scrollControllerY,
        child: ListView.separated(
            controller: scrollControllerY,
            itemBuilder: (ctx, index) {
              var category = categories[index];
              options = [
                {'id': 1, 'name': 'EDITAR CATEGORIA'},
              ];

              if (!widget.subCategories) {
                options.add({'id': 2, 'name': 'VER SUBCATEGORIAS'});
              }
              return ListTile(
                minVerticalPadding: kDefaultPadding,
                leading: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    color: Theme.of(context).primaryColor.withOpacity(0.04),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.category_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                ),
                title: Text(category.name ?? ''),
                onTap: widget.selectorMode
                    ? () {
                        _onSelected(category);
                      }
                    : null,
                trailing: Wrap(
                  children: [
                    widget.selectorMode
                        ? IconButton(
                            onPressed: () {
                              _onSelected(category);
                            },
                            icon: Icon(Icons.arrow_right))
                        : SizedBox(),
                    PopupMenuButton<int>(
                        itemBuilder: (ctx) {
                          return List.generate(options.length, (index) {
                            var option = options[index];
                            return PopupMenuItem(
                                value: option['id'],
                                child: Text(option['name']));
                          });
                        },
                        onSelected: (v) => _onSelectOption(v, category))
                  ],
                ),
              );
            },
            separatorBuilder: (ctx, i) => const Divider(),
            itemCount: categories.length));
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_product-iteration_r2wg.svg',
              width: 250)
        ],
      ),
    );
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  String get title {
    if (widget.subCategories) {
      return 'SUBCATEGORIAS - ${widget.parentCategory?.name ?? ''}';
    }
    return 'CATEGORIAS';
  }

  _initAsync([String? words]) async {
    try {
      categories = await Category.get(
          search: words, parentCategoryId: widget.parentCategory?.id);
    } catch (e) {
      print(e);
    } finally {
      setState(() {});
    }
  }

  @override
  void initState() {
    setState(() {
      future = _initAsync();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('$title (${categories.length})'),
          actions: [
            Wrap(
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 50,
                  child: TextFormField(
                    controller: _searchController,
                    onFieldSubmitted: (words) async {
                      setState(() {
                        future = _initAsync(words);
                      });
                    },
                    decoration: InputDecoration(
                        hintText: 'Nombre...',
                        fillColor: Colors.white,
                        filled: true,
                        suffixIcon: Icon(Icons.search)),
                  ),
                ),
                SizedBox(width: kDefaultPadding),
                CircleAvatar(
                    child: IconButton(
                  tooltip: 'AGREGAR CATEGORIA',
                  onPressed: () {
                    _showModal(category: Category());
                  },
                  icon: Icon(Icons.add),
                )),
                SizedBox(width: kDefaultPadding),
              ],
            )
          ],
        ),
        body: FutureBuilder(
            future: future,
            builder: (ctx, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return contentLoading;
              }

              if (s.hasError) {
                return ContentErrorWidget(
                  error: s.error.toString(),
                  onRetry: () {
                    setState(() {
                      future = _initAsync();
                    });
                  },
                );
              }
              if (s.connectionState == ConnectionState.done &&
                  categories.isNotEmpty) {
                return contentFilled;
              }

              return contentEmpty;
            }),
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: 20,
              right: kDefaultPadding * 2,
              child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      future = _initAsync();
                    });
                  },
                  child: Icon(Icons.restore)),
            )
          ],
        ));
  }
}
