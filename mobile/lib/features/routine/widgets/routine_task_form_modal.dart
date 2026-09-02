import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/selection_option_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../models/routine_task.dart';

enum RoutineTaskFormAction {
  save,
  delete,
}

class RoutineTaskFormResult {
  const RoutineTaskFormResult({
    required this.action,
    required this.task,
  });

  final RoutineTaskFormAction action;
  final RoutineTask task;
}

class RoutineTaskFormModal extends StatefulWidget {
  const RoutineTaskFormModal({
    super.key,
    required this.selectedDate,
    required this.elderId,
    required this.createdByUserId,
    required this.createdByRole,
    this.task,
  });

  final DateTime selectedDate;
  final String elderId;
  final String createdByUserId;
  final RoutineTaskCreatorRole createdByRole;
  final RoutineTask? task;

  bool get isEditing => task != null;

  @override
  State<RoutineTaskFormModal> createState() =>
      _RoutineTaskFormModalState();
}

class _RoutineTaskFormModalState extends State<RoutineTaskFormModal> {
  late final TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _repeatWeekly;
  late Set<int> _selectedWeekdays;
  String? _errorMessage;

  static const _weekdays = <({int value, String label})>[
    (value: DateTime.sunday, label: 'D'),
    (value: DateTime.monday, label: 'S'),
    (value: DateTime.tuesday, label: 'T'),
    (value: DateTime.wednesday, label: 'Q'),
    (value: DateTime.thursday, label: 'Q'),
    (value: DateTime.friday, label: 'S'),
    (value: DateTime.saturday, label: 'S'),
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _startTime = task == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(task.startAt);
    _endTime = task == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : TimeOfDay.fromDateTime(task.endAt);
    _repeatWeekly = task?.repeatWeekly ?? false;
    _selectedWeekdays = task?.repeatWeekdays.isNotEmpty == true
        ? {...task!.repeatWeekdays}
        : {widget.selectedDate.weekday};
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime({required bool start}) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      helpText: start ? 'Horário de começo' : 'Horário de término',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      if (start) {
        _startTime = selectedTime;
      } else {
        _endTime = selectedTime;
      }
    });
  }

  DateTime _dateWithTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  RoutineTaskType _inferTaskType(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('café')) return RoutineTaskType.breakfast;
    if (normalized.contains('remédio') ||
        normalized.contains('medicamento')) {
      return RoutineTaskType.medication;
    }
    if (normalized.contains('almoço') ||
        normalized.contains('jantar') ||
        normalized.contains('lanche')) {
      return RoutineTaskType.meal;
    }
    if (normalized.contains('caminhada') ||
        normalized.contains('pilates') ||
        normalized.contains('exercício')) {
      return RoutineTaskType.exercise;
    }
    if (normalized.contains('leitura') ||
        normalized.contains('lazer')) {
      return RoutineTaskType.leisure;
    }
    if (normalized.contains('consulta') ||
        normalized.contains('médico')) {
      return RoutineTaskType.appointment;
    }
    if (normalized.contains('banho') ||
        normalized.contains('higiene')) {
      return RoutineTaskType.hygiene;
    }
    if (normalized.contains('dormir') ||
        normalized.contains('sono')) {
      return RoutineTaskType.sleep;
    }

    return RoutineTaskType.other;
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Informe o nome da tarefa.');
      return;
    }

    if (_repeatWeekly && _selectedWeekdays.isEmpty) {
      setState(() {
        _errorMessage = 'Escolha pelo menos um dia da semana.';
      });
      return;
    }

    final originalTask = widget.task;
    final scheduleDate = originalTask == null
        ? RoutineTask.dateOnly(widget.selectedDate)
        : RoutineTask.dateOnly(originalTask.startAt);
    final startAt = _dateWithTime(scheduleDate, _startTime);
    var endAt = _dateWithTime(scheduleDate, _endTime);
    if (!endAt.isAfter(startAt)) {
      endAt = endAt.add(const Duration(days: 1));
    }

    final task = originalTask == null
        ? RoutineTask(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            elderId: widget.elderId,
            title: title,
            startAt: startAt,
            endAt: endAt,
            createdByUserId: widget.createdByUserId,
            createdByRole: widget.createdByRole,
            type: _inferTaskType(title),
            repeatWeekly: _repeatWeekly,
            repeatWeekdays:
                _repeatWeekly ? {..._selectedWeekdays} : const <int>{},
          )
        : originalTask.copyWith(
            title: title,
            startAt: startAt,
            endAt: endAt,
            type: _inferTaskType(title),
            repeatWeekly: _repeatWeekly,
            repeatWeekdays:
                _repeatWeekly ? {..._selectedWeekdays} : const <int>{},
          );

    Navigator.of(context).pop(
      RoutineTaskFormResult(
        action: RoutineTaskFormAction.save,
        task: task,
      ),
    );
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;

    final confirmed = await showAppModal<bool>(
      context: context,
      size: AppModalSize.small,
      title: 'Tem certeza que deseja\ndeletar esta tarefa?',
      showCloseButton: false,
      barrierDismissible: false,
      child: _DeleteConfirmationContent(
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.of(context).pop(
      RoutineTaskFormResult(
        action: RoutineTaskFormAction.delete,
        task: task,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nome da tarefa:', style: theme.textTheme.bodySmall),
        SizedBox(height: sizes.sm),
        TextFieldWidget(
          controller: _titleController,
          hintText: 'Qual é a tarefa?',
          variant: TextFieldVariant.tinted,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
        ),
        SizedBox(height: sizes.xl),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Começo:',
                time: _startTime,
                onPressed: () => _selectTime(start: true),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                sizes.sm,
                sizes.lg,
                sizes.sm,
                0,
              ),
              child: Container(
                width: sizes.xl,
                height: sizes.xs / 2,
                color: context.appGradientColors.bottom,
              ),
            ),
            Expanded(
              child: _TimeField(
                label: 'Término:',
                time: _endTime,
                onPressed: () => _selectTime(start: false),
              ),
            ),
          ],
        ),
        SizedBox(height: sizes.xl),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: sizes.xs,
          runSpacing: sizes.sm,
          children: [
            for (final weekday in _weekdays)
              SelectionOptionWidget(
                label: weekday.label,
                selected: _selectedWeekdays.contains(weekday.value),
                size: sizes.xl,
                semanticLabel: 'Dia ${weekday.label}',
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWeekdays.add(weekday.value);
                    } else {
                      _selectedWeekdays.remove(weekday.value);
                    }
                  });
                },
              ),
          ],
        ),
        SizedBox(height: sizes.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Repetir tarefa?',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Switch(
              value: _repeatWeekly,
              activeThumbColor: colorScheme.primary,
              onChanged: (value) {
                setState(() => _repeatWeekly = value);
              },
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: sizes.sm),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
        SizedBox(height: sizes.xl),
        ButtonWidget(
          label: widget.isEditing ? 'Salvar' : 'Criar',
          variant: ButtonVariant.secondary,
          onPressed: _save,
        ),
        if (widget.isEditing) ...[
          SizedBox(height: sizes.md),
          ButtonWidget(
            label: 'Deletar',
            variant: ButtonVariant.secondary,
            onPressed: _delete,
          ),
        ],
        SizedBox(height: sizes.md),
        ButtonWidget(
          label: 'Cancelar',
          variant: ButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onPressed,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final minute = time.minute.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        SizedBox(height: sizes.sm),
        Material(
          color: Color.alphaBlend(
            context.appGradientColors.bottom.withValues(alpha: .55),
            colorScheme.surface,
          ),
          elevation: sizes.xs / 2,
          shadowColor: colorScheme.shadow.withValues(alpha: .24),
          borderRadius: BorderRadius.circular(sizes.radiusFull),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: sizes.buttonMedium,
              child: Center(
                child: Text(
                  '${time.hour}:$minute',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteConfirmationContent extends StatelessWidget {
  const _DeleteConfirmationContent({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return Row(
      children: [
        Expanded(
          child: ButtonWidget(
            label: 'Sim',
            size: ButtonSize.small,
            variant: ButtonVariant.secondary,
            onPressed: onConfirm,
          ),
        ),
        SizedBox(width: sizes.md),
        Expanded(
          child: ButtonWidget(
            label: 'Não',
            size: ButtonSize.small,
            variant: ButtonVariant.outlined,
            onPressed: onCancel,
          ),
        ),
      ],
    );
  }
}
