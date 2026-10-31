import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:uresax_invoice_sys_cloud/models/workday.dart';
import 'package:uresax_invoice_sys_cloud/settings.dart';
import 'package:uresax_invoice_sys_cloud/utils/functions.dart';
import 'package:uresax_invoice_sys_cloud/widgets/content.error.widget.dart';
import 'package:uresax_invoice_sys_cloud/widgets/toolbutton.widget.dart';

class WorkdayListPage extends StatefulWidget {
  const WorkdayListPage({super.key});

  @override
  State<WorkdayListPage> createState() => _WorkdayListPageState();
}

class _WorkdayListPageState extends State<WorkdayListPage> {
  List<WorkdayModel> xworkdays = [];

  Future? future;

  _loadWorkdays() async {
    try {
      xworkdays = await WorkdayModel.get();
      workdays = xworkdays;
      setState(() {});
    } catch (e) {
      rethrow;
    }
  }

  void _addOrEditWorkday({WorkdayModel? workday, bool editing = false}) async {
    final result = await showDialog<WorkdayModel>(
      context: context,
      builder: (_) => WorkdayFormDialog(workday: workday, editing: editing),
    );

    if (result != null) {
      setState(() {
        future = _loadWorkdays();
      });
    }
  }

  Future<void> _selectedWorkday({WorkdayModel? workday}) async {
    try {
      showLoader(context);
      company?.currentWorkdayId = workday?.id;
      await company?.updateCurrentWork();

      Navigator.pop(context);
      setState(() {});
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, message: e.toString(), color: Colors.red);
    }
  }

  @override
  void initState() {
    if (!mounted) return;
    setState(() {
      future = _loadWorkdays();
    });
    super.initState();
  }

  Widget get contentLoading {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget get contentEmpty {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/svgs/undraw_alarm-clock_zgtg.svg',
              width: 220)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Jornadas de trabajo (${workdays.length})"),
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight + kDefaultPadding,
        actions: [
          ToolButtonWidget(
              icon: Icons.close,
              onTap: () {
                Navigator.pop(context);
              }),
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
                  error: s.error?.toString() ?? '',
                  onRetry: () {
                    setState(() {
                      future = _loadWorkdays();
                    });
                  });
            }

            if (xworkdays.isEmpty) {
              return contentEmpty;
            }
            return ListView.separated(
              itemCount: xworkdays.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                final wd = xworkdays[index];
                return ListTile(
                    key: ValueKey(wd.id),
                    minVerticalPadding: kDefaultPadding / 2,
                    selected: company?.currentWorkdayId == wd.id,
                    selectedTileColor: const Color.fromARGB(255, 236, 234, 234),
                    leading: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(90),
                        color: Theme.of(context).primaryColor.withOpacity(0.04),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.history_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                    title: Text(wd.name ?? "Sin nombre"),
                    subtitle: Text(
                      "${wd.startHour?.format(context)} - ${wd.endHour?.format(context)} (${wd.hours}h)",
                    ),
                    trailing: Wrap(
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed:() => _selectedWorkday(workday: wd),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _addOrEditWorkday(workday: wd, editing: true),
                        ),
                      ],
                    ));
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditWorkday(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WorkdayFormDialog extends StatefulWidget {
  final WorkdayModel? workday;
  bool editing;
  WorkdayFormDialog({super.key, this.workday, this.editing = false});

  @override
  State<WorkdayFormDialog> createState() => _WorkdayFormDialogState();
}

class _WorkdayFormDialogState extends State<WorkdayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  TimeOfDay? _startHour;
  TimeOfDay? _endHour;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workday?.name ?? "");
    _startHour = widget.workday?.startHour;
    _endHour = widget.workday?.endHour;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.editing == false ? "Agregar jornada" : "Editar jornada",
        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: "Nombre", hintText: 'Jornada...'),
              validator: (value) =>
                  value == null || value.isEmpty ? "CAMPO OBLIGATORIO" : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startHour ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _startHour = picked);
                    },
                    child: Text(
                      _startHour == null
                          ? "Hora inicio"
                          : _startHour!.format(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endHour ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _endHour = picked);
                    },
                    child: Text(
                      _endHour == null ? "Hora fin" : _endHour!.format(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() &&
                _startHour != null &&
                _endHour != null) {
              try {
                showLoader(context);
                final duration = (_endHour!.hour * 60 + _endHour!.minute) -
                    (_startHour!.hour * 60 + _startHour!.minute);
                final hours = duration / 60.0;

                var workday = WorkdayModel(
                  id: widget.workday?.id ??
                      DateTime.now().millisecondsSinceEpoch,
                  name: _nameController.text,
                  startHour: _startHour,
                  endHour: _endHour,
                  hours: hours,
                  companyId: widget.workday?.companyId,
                  createdAt: DateTime.now(),
                );

                if (widget.editing) {
                  await workday.update();
                } else {
                  await workday.create();
                }

                Navigator.pop(context);

                Navigator.pop(context, workday);
              } catch (e) {
                Navigator.pop(context);
                showTopSnackBar(context,
                    message: e.toString(), color: Colors.red);
              }
            }
          },
          child: Text(widget.editing ? 'Editar' : "Guardar"),
        ),
      ],
    );
  }
}
