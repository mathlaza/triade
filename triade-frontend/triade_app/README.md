-- PERSISTIR TAREFAS repetiveis futuras marcadas como done no backeend. Arquivos:
app\models.py
app\routes.py
triade_app\lib\services\api_service.dart
triade_app\lib\providers\task_provider.dart
triade_app\lib\models\task.dart


Existe uma única coisa que NÃO está sendo salva no banco de dados backend, mas sim na memória do celular (SharedPreferences), do jeito que o código está agora:

O "Check" (Done) de uma tarefa repetível em um dia específico.
Como está hoje: Se você tem uma tarefa "Ir à Academia" (Repetível) e marca como feita hoje:

O app salva no seu celular: "A tarefa Academia foi feita dia 03/01/2026".
O banco de dados não sabe disso. Ele só sabe que a tarefa existe.
O risco: Se você desinstalar o app ou trocar de celular, as tarefas repetíveis antigas aparecerão como "Não Feitas", pois esse histórico estava apenas no aparelho antigo.


-- Dashboard com gráficos + Histórico
O coração do método é saber se você está vivendo na esfera da Importância, Urgência ou Circunstância.

Feature: Um gráfico de pizza simples na tela inicial ou perfil.
Lógica: O app calcula o tempo das tarefas concluídas. Se o usuário fez 5 tarefas urgentes de 1 hora cada, o gráfico mostra que o dia dele foi 100% reativo. Isso gera o "choque de realidade" que o método propõe.