import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/widgets/task/task_widgets.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Task? taskToEdit;

  const AddTaskScreen({
    super.key,
    required this.selectedDate,
    this.taskToEdit,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _roleTagController = TextEditingController();
  final _delegatedToController = TextEditingController();
  final _repeatDaysController = TextEditingController(text: '7');

  EnergyLevel _selectedEnergyLevel = EnergyLevel.renewal;
  String? _selectedContext;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _followUpDate;
  bool _isRepeatable = false;
  bool _originalIsRepeatable = false;
  bool _isDelegated = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.selectedDate;

    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _durationController.text = task.durationMinutes.toString();
      _selectedEnergyLevel = task.energyLevel;
      _selectedContext = task.contextTag;
      _selectedDate = task.dateScheduled;
      _roleTagController.text = task.roleTag ?? '';
      _delegatedToController.text = task.delegatedTo ?? '';
      _isDelegated = task.delegatedTo != null && task.delegatedTo!.isNotEmpty;
      _followUpDate = task.followUpDate;

      if (task.scheduledTime != null) {
        final parts = task.scheduledTime!.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }

      _isRepeatable = task.isRepeatable;
      _originalIsRepeatable = task.isRepeatable;
      
      if (task.isRepeatable && task.repeatDays != null) {
        _repeatDaysController.text = task.repeatDays.toString();
      }
    } else {
      _originalIsRepeatable = _isRepeatable;
    }

    _delegatedToController.addListener(() {
      final delegatedNow = _delegatedToController.text.trim().isNotEmpty;
      if (delegatedNow != _isDelegated) {
        setState(() => _isDelegated = delegatedNow);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _roleTagController.dispose();
    _delegatedToController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = context.read<TaskProvider>();

    String fmtDate(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    bool success = false;
    try {
      final delegatedToText = _delegatedToController.text.trim();
      final isDelegated = delegatedToText.isNotEmpty;
      final delegatedToSend = isDelegated ? delegatedToText : "";
      final followUpToSend = isDelegated && _followUpDate != null 
          ? fmtDate(_followUpDate!) 
          : "";

      // Lógica especial: Converter repetível para normal
      if (widget.taskToEdit != null && 
          _originalIsRepeatable && 
          !_isRepeatable) {
        
        await provider.deleteTask(widget.taskToEdit!.id);
        
        final newTask = Task(
          id: 0,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          energyLevel: _selectedEnergyLevel,
          durationMinutes: int.parse(_durationController.text),
          status: isDelegated ? TaskStatus.delegated : TaskStatus.active,
          dateScheduled: _selectedDate!,
          scheduledTime: _selectedTime != null
              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
              : null,
          roleTag: _roleTagController.text.trim().isNotEmpty 
              ? _roleTagController.text.trim() 
              : null,
          contextTag: _selectedContext,
          delegatedTo: isDelegated ? delegatedToSend : null,
          followUpDate: followUpToSend.isNotEmpty ? _followUpDate : null,
          isRepeatable: false,
          repeatDays: null,
          repeatCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await provider.createTask(newTask);
        
        if (mounted) Navigator.pop(context, true);
        setState(() => _isLoading = false);
        return;
      }

      // Lógica normal
      final Map<String, dynamic> taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'energy_level': _selectedEnergyLevel.value,
        'duration_minutes': int.parse(_durationController.text),
        'scheduled_time': _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'role_tag': _roleTagController.text.trim().isNotEmpty 
            ? _roleTagController.text.trim() 
            : null,
        'context_tag': _selectedContext,
        'delegated_to': delegatedToSend,
        'follow_up_date': followUpToSend,
        'is_repeatable': _isRepeatable,
        'repeat_days': _isRepeatable 
            ? (int.tryParse(_repeatDaysController.text) ?? 7) 
            : null,
      };

      if (widget.taskToEdit != null) {
        final wasDelegate = widget.taskToEdit!.delegatedTo != null && 
                            widget.taskToEdit!.delegatedTo!.isNotEmpty;
        
        if (wasDelegate != isDelegated) {
          taskData['status'] = isDelegated ? 'DELEGATED' : 'ACTIVE';
        }
      } else {
        taskData['status'] = isDelegated ? 'DELEGATED' : 'ACTIVE';
      }

      if (widget.taskToEdit == null || !widget.taskToEdit!.isRepeatable) {
         taskData['date_scheduled'] = fmtDate(_selectedDate!);
      }

      if (widget.taskToEdit != null) {
        success = await provider.updateTask(widget.taskToEdit!.id, taskData);
      } else {
        taskData['repeat_count'] = 0;
        final newTask = Task(
          id: 0,
          title: taskData['title'],
          description: taskData['description'],
          energyLevel: _selectedEnergyLevel,
          durationMinutes: taskData['duration_minutes'],
          status: isDelegated ? TaskStatus.delegated : TaskStatus.active,
          dateScheduled: _selectedDate!,
          scheduledTime: taskData['scheduled_time'],
          roleTag: taskData['role_tag'],
          contextTag: taskData['context_tag'],
          delegatedTo: isDelegated ? delegatedToSend : null,
          followUpDate: followUpToSend.isNotEmpty ? _followUpDate : null,
          isRepeatable: taskData['is_repeatable'],
          repeatDays: taskData['repeat_days'],
          repeatCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await provider.createTask(newTask);
      }
    } finally {
      setState(() => _isLoading = false);
    }

    if (success) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Erro ao salvar tarefa'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isFutureTask() {
    if (widget.taskToEdit == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tDate = widget.taskToEdit!.dateScheduled;
    final taskDay = DateTime(tDate.year, tDate.month, tDate.day);
    return taskDay.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    
    return Scaffold(
      backgroundColor: TaskFormStyles.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(isEditing),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: TaskFormStyles.accentColor),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção: Informações Básicas
                            const TaskFormSectionHeader(title: 'Informações Básicas', icon: Icons.info_outline),
                            const SizedBox(height: 12),
                            
                            // Título
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: TaskFormStyles.buildInputDecoration(
                                label: 'Título *',
                                icon: Icons.title,
                                counter: '${_titleController.text.length}/40',
                              ),
                              maxLength: 40,
                              maxLines: 1,
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Título obrigatório';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            // Descrição
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: TaskFormStyles.buildInputDecoration(
                                label: 'Descrição (opcional)',
                                icon: Icons.notes,
                                hint: 'Detalhes adicionais da tarefa',
                                counter: '${_descriptionController.text.length}/100',
                              ),
                              maxLength: 100,
                              maxLines: 2,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 0),

                            // Seção: Energia e Tempo
                            const TaskFormSectionHeader(title: 'Energia e Tempo', icon: Icons.bolt),

                            // Nível de Energia
                            EnergyLevelSelector(
                              selectedLevel: _selectedEnergyLevel,
                              onChanged: (level) => setState(() => _selectedEnergyLevel = level),
                            ),
                            const SizedBox(height: 20),

                            // Duração
                            TextFormField(
                              controller: _durationController,
                              style: const TextStyle(color: Colors.white),
                              decoration: TaskFormStyles.buildInputDecoration(
                                label: 'Duração (minutos) *',
                                icon: Icons.timer,
                                hint: 'Ex: 60',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Duração obrigatória';
                                }
                                final duration = int.tryParse(value);
                                if (duration == null || duration < AppConstants.minTaskDuration) {
                                  return 'Mínimo ${AppConstants.minTaskDuration} minutos';
                                }
                                if (duration > 480) {
                                  return 'Máximo 480 minutos (8 horas)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Seção: Agendamento
                            const TaskFormSectionHeader(title: 'Agendamento', icon: Icons.calendar_today),
                            const SizedBox(height: 12),

                            // Data e Horário lado a lado
                            Row(
                              children: [
                                Expanded(
                                  child: TaskDatePicker(
                                    selectedDate: _selectedDate!,
                                    isLocked: widget.taskToEdit != null && widget.taskToEdit!.isRepeatable,
                                    onDateChanged: (date) => setState(() => _selectedDate = date),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TaskTimePicker(
                                    selectedTime: _selectedTime,
                                    onTimeChanged: (time) => setState(() => _selectedTime = time),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Seção: Organização
                            const TaskFormSectionHeader(title: 'Organização', icon: Icons.folder_outlined),
                            const SizedBox(height: 12),

                            // Contexto
                            ContextDropdown(
                              selectedContext: _selectedContext,
                              onChanged: (value) => setState(() => _selectedContext = value),
                            ),
                            const SizedBox(height: 20),

                            // Role Tag
                            TextFormField(
                              controller: _roleTagController,
                              style: const TextStyle(color: Colors.white),
                              decoration: TaskFormStyles.buildInputDecoration(
                                label: 'Papel/Função',
                                icon: Icons.badge_outlined,
                                hint: 'Qual papel você exerce nesta tarefa?',
                                helper: 'Ex: Pai, Gestor, Atleta, Estudante',
                                counter: '${_roleTagController.text.length}/30',
                              ),
                              maxLength: 30,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),

                            // Seção: Delegação
                            const TaskFormSectionHeader(title: 'Delegação', icon: Icons.person_add_outlined),
                            const SizedBox(height: 12),

                            // Delegar para
                            TextFormField(
                              controller: _delegatedToController,
                              enabled: !_isRepeatable,
                              style: TextStyle(
                                color: _isRepeatable ? Colors.white38 : Colors.white,
                              ),
                              decoration: TaskFormStyles.buildInputDecoration(
                                label: 'Delegar para',
                                icon: Icons.forward,
                                hint: 'Nome da pessoa responsável',
                                counter: '${_delegatedToController.text.length}/50',
                                enabled: !_isRepeatable,
                              ),
                              maxLength: 50,
                              onChanged: (value) {
                                setState(() {
                                  _isDelegated = value.trim().isNotEmpty;
                                  if (_isDelegated) _isRepeatable = false;
                                });
                              },
                            ),

                            // Follow-up (se delegado)
                            if (_isDelegated) ...[
                              const SizedBox(height: 12),
                              FollowUpSection(
                                followUpDate: _followUpDate,
                                onDateChanged: (date) => setState(() => _followUpDate = date),
                              ),
                            ],

                            const SizedBox(height: 2),

                            // Seção: Repetição
                            const TaskFormSectionHeader(title: 'Repetição', icon: Icons.repeat),
                            const SizedBox(height: 12),
                            RepeatableSwitch(
                              isRepeatable: _isRepeatable,
                              isDisabled: _isDelegated || _isFutureTask(),
                              isDelegated: _isDelegated,
                              isFutureTask: _isFutureTask(),
                              onChanged: (v) => setState(() => _isRepeatable = v),
                            ),

                            if (_isRepeatable) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _repeatDaysController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: TaskFormStyles.buildInputDecoration(
                                  label: 'Repetir por quantos dias?',
                                  icon: Icons.date_range,
                                  hint: 'Ex: 7',
                                  helper: 'Máx. 30 dias de repetição',
                                ),
                                validator: (value) {
                                  if (_isRepeatable) {
                                    if (value == null || value.isEmpty) return 'Informe os dias';
                                    final n = int.tryParse(value);
                                    if (n == null || n < 1) return 'Mínimo 1 dia';
                                    if (n > 30) return 'Máximo 30 dias';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Botão Salvar
                            TaskSaveButton(
                              isEditing: isEditing,
                              onPressed: _saveTask,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TaskFormStyles.darkBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão Voltar
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TaskFormStyles.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: TaskFormStyles.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit : Icons.add_task,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Editar Tarefa' : 'Nova Tarefa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
