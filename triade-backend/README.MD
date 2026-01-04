Rodando backend:

.\venv\Scripts\activate
python run.py


Rodando frontend:

flutter run
ou
flutter run --debug



---- Atualizando Na Nuvem ----
Depois de atualizar o frontend:
Conectar celular no USB
flutter devices
flutter run --release -d 0076832793

Depois de atualizar o backend:
Entre no site do PythonAnywhere > Aba Files.
Navegue até o arquivo (ex: triade-backend/app/routes.py).
Edite o código direto no navegador e clique em Save.
Vá na aba Web e clique em Reload (Isso é obrigatório para a mudança valer).

Se você mudou muitos arquivos no seu PC:
Zipe a pasta do backend atualizada no seu PC.
No PythonAnywhere > Aba Files, delete a pasta antiga (ou os arquivos dentro dela).
Faça o Upload do novo ZIP e descompacte (unrar x arquivo.rar).
Vá na aba Web e clique em Reload.

Se você mudar a estrutura do banco, você tem duas opções simples por enquanto:
Opção Destrutiva: Apagar o arquivo triade.db na aba Files do PythonAnywhere e dar Reload na aba Web. O sistema vai criar um banco novo do zero (mas você perde as tarefas antigas).
Opção Manual: Usar comandos SQL no Bash Console para adicionar a coluna na mão (ex: ALTER TABLE tasks ADD COLUMN nova_coluna TEXT;).