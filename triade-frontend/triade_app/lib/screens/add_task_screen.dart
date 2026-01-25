import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';

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
  TimeOfDay? _selectedTime; // Horário agendado (opcional)
  DateTime? _followUpDate;
  bool _isRepeatable = false;
  bool _originalIsRepeatable = false; // trava o valor ao editar
  bool _isDelegated = false; // VARIÁVEL ADICIONADA
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

    // Parse scheduled_time se existir
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
    
    // ✅ CORREÇÃO: Preenche o campo de dias com o valor real da tarefa
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

    // 🔥 LÓGICA ESPECIAL: Converter repetível para normal
    if (widget.taskToEdit != null && 
        _originalIsRepeatable && 
        !_isRepeatable) {
      
      // 1. Deletar a repetível original
      await provider.deleteTask(widget.taskToEdit!.id);
      
      // 2. Criar nova tarefa normal
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

    // ✅ CORREÇÃO: Só altera o status se mudou a delegação
    // Se está editando e não mudou delegação, NÃO envia status
    if (widget.taskToEdit != null) {
      final wasDelegate = widget.taskToEdit!.delegatedTo != null && 
                          widget.taskToEdit!.delegatedTo!.isNotEmpty;
      
      // Só envia status se houve mudança na delegação
      if (wasDelegate != isDelegated) {
        taskData['status'] = isDelegated ? 'DELEGATED' : 'ACTIVE';
      }
      // Se não mudou delegação, não envia 'status' para preservar o atual
    } else {
      // Tarefa nova sempre define o status
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
    // Normaliza para meia-noite para comparar apenas datas
    final today = DateTime(now.year, now.month, now.day);
    final tDate = widget.taskToEdit!.dateScheduled;
    final taskDay = DateTime(tDate.year, tDate.month, tDate.day);
    return taskDay.isAfter(today);
  }

  // Cores e estilos seguindo a identidade visual da Daily View
  static const _primaryGradient = LinearGradient(
    colors: [Color(0xFFFFD60A), Color(0xFFFFCC00)],
  );
  static const _darkBackground = Color(0xFF1C1C1E);
  static const _cardBackground = Color(0xFF2C2C2E);
  static const _accentColor = Color(0xFFFFD60A);

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    String? counter,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: enabled ? Colors.white70 : Colors.white38,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      helperText: helper,
      helperStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      counterText: counter,
      counterStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: _accentColor.withValues(alpha: 0.8)),
      filled: true,
      fillColor: enabled ? _cardBackground : _cardBackground.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    
    return Scaffold(
      backgroundColor: _darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _darkBackground,
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
                        color: _cardBackground,
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
                            gradient: _primaryGradient,
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
            ),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção: Informações Básicas
                            _buildSectionHeader('Informações Básicas', Icons.info_outline),
                            const SizedBox(height: 12),
                            
                            // Título
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
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
                            const SizedBox(height: 16),

                            // Descrição
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                label: 'Descrição (opcional)',
                                icon: Icons.notes,
                                hint: 'Detalhes adicionais da tarefa',
                                counter: '${_descriptionController.text.length}/100',
                              ),
                              maxLength: 100,
                              maxLines: 2,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),

                            // Seção: Energia e Tempo
                            _buildSectionHeader('Energia e Tempo', Icons.bolt),

                            // Nível de Energia
                            _buildEnergySelector(),
                            const SizedBox(height: 20),

                            // Duração
                            TextFormField(
                              controller: _durationController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
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
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Seção: Agendamento
                            _buildSectionHeader('Agendamento', Icons.calendar_today),
                            const SizedBox(height: 12),

                            // Data e Horário lado a lado
                            Row(
                              children: [
                                Expanded(child: _buildDatePicker()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTimePicker()),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Seção: Organização
                            _buildSectionHeader('Organização', Icons.folder_outlined),
                            const SizedBox(height: 12),

                            // Contexto
                            _buildContextDropdown(),
                            const SizedBox(height: 20),

                            // Role Tag
                            TextFormField(
                              controller: _roleTagController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
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
                            _buildSectionHeader('Delegação', Icons.person_add_outlined),
                            const SizedBox(height: 12),

                            // Delegar para
                            TextFormField(
                              controller: _delegatedToController,
                              enabled: !_isRepeatable,
                              style: TextStyle(
                                color: _isRepeatable ? Colors.white38 : Colors.white,
                              ),
                              decoration: _buildInputDecoration(
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
                              _buildFollowUpSection(),
                            ],

                            const SizedBox(height: 2),

                            // Seção: Repetição
                            _buildSectionHeader('Repetição', Icons.repeat),
                            const SizedBox(height: 12),
                            _buildRepeatableSwitch(),

                            if (_isRepeatable) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _repeatDaysController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  label: 'Repetir por quantos dias?',
                                  icon: Icons.date_range,
                                  hint: 'Ex: 7',
                                  helper: 'Define a duração do ciclo de repetição',
                                ),
                                validator: (value) {
                                  if (_isRepeatable) {
                                    if (value == null || value.isEmpty) return 'Informe os dias';
                                    final n = int.tryParse(value);
                                    if (n == null || n < 1) return 'Mínimo 1 dia';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Botão Salvar
                            _buildSaveButton(),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accentColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEnergySelector() {
    // Ordem correta: Alta Energia, Renovação, Baixa Energia
    final orderedLevels = [
      EnergyLevel.highEnergy,
      EnergyLevel.renewal,
      EnergyLevel.lowEnergy,
    ];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: orderedLevels.map((level) {
          final isSelected = _selectedEnergyLevel == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedEnergyLevel = level),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? level.color.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: level.color, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: level.color,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: level.color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDatePicker() {
    final isLocked = widget.taskToEdit != null && widget.taskToEdit!.isRepeatable;
    
    return GestureDetector(
      onTap: isLocked
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate!,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: isLocked ? Colors.white38 : _accentColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data',
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yy').format(_selectedDate!),
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock : Icons.chevron_right,
              color: Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? TimeOfDay.now(),
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: _accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horário',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Opcional',
                    style: TextStyle(
                      color: _selectedTime != null ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedTime != null)
              GestureDetector(
                onTap: () => setState(() => _selectedTime = null),
                child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildContextDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedContext,
        dropdownColor: _cardBackground,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.label_outline, color: _accentColor),
          labelText: 'Contexto',
          labelStyle: TextStyle(color: Colors.white70),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Nenhum', style: TextStyle(color: Colors.white54)),
          ),
          ...ContextColors.colors.keys.map((contextTag) {
            final color = ContextColors.getColor(contextTag);
            return DropdownMenuItem(
              value: contextTag,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(contextTag, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }),
        ],
        onChanged: (value) => setState(() => _selectedContext = value),
      ),
    );
  }

  Widget _buildFollowUpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade300, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tarefa delegada. Defina quando fazer o follow-up.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _followUpDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() => _followUpDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _followUpDate != null
                          ? 'Follow-up: ${DateFormat('dd/MM/yyyy').format(_followUpDate!)}'
                          : 'Definir data de follow-up',
                      style: TextStyle(
                        fontSize: 14,
                        color: _followUpDate != null ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                  if (_followUpDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _followUpDate = null),
                      child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatableSwitch() {
    final isDisabled = _isDelegated || _isFutureTask();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.repeat,
            color: isDisabled ? Colors.white38 : _accentColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarefa repetível',
                  style: TextStyle(
                    color: isDisabled ? Colors.white38 : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isDisabled)
                  Text(
                    _isDelegated ? 'Não disponível para tarefas delegadas' : 'Não disponível para tarefas futuras',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Switch(
            value: _isRepeatable,
            onChanged: isDisabled ? null : (v) => setState(() => _isRepeatable = v),
            activeColor: _accentColor,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: _primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.taskToEdit != null ? Icons.check : Icons.add,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              widget.taskToEdit != null ? 'Atualizar Tarefa' : 'Criar Tarefa',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
