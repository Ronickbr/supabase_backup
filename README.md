Backup de Banco de Dados Supabase com GitHub Actions
Este repositório oferece uma maneira prática de automatizar os backups do seu banco de dados Supabase usando GitHub Actions. Ele cria backups diários das permissões (roles), esquema (schema) e dados do seu banco, armazenando-os diretamente no seu repositório. Também inclui um mecanismo para restaurar facilmente o banco de dados caso algo dê errado.

Funcionalidades
Backups Diários Automáticos: Agendados para rodar todos os dias à meia-noite.

Separação de Roles, Schema e Dados: Cria arquivos de backup modulares para facilitar a organização.

Controle de Fluxo Flexível: Ative ou desative os backups através de uma simples variável de ambiente.

Integração com GitHub Actions: Utiliza a infraestrutura gratuita e confiável do GitHub para automação.

Restauração Facilitada: Passos claros para recuperar seu banco de dados a partir dos arquivos de backup.

Como Começar
1. Configurar Variáveis no Repositório
Vá nas configurações do seu repositório e navegue até Actions > Variables. Adicione o seguinte:

Secrets (Segredos):

SUPABASE_DB_URL: Sua string de conexão PostgreSQL do Supabase. Formato:

postgresql://<USUÁRIO>:<SENHA>@<HOST>:5432/postgres

Variables (Variáveis):

BACKUP_ENABLED: Defina como true para ativar os backups ou false para desativá-los.

2. Como o Fluxo de Trabalho (Workflow) Funciona
O workflow do GitHub Actions é acionado quando:

Ocorre um push ou pull request nos branches main ou dev.

É disparado manualmente pela interface do GitHub.

Chega o horário agendado (diariamente à meia-noite).

O processo segue estas etapas:

Verifica se os backups estão ativos através da variável BACKUP_ENABLED.

Executa a CLI do Supabase para criar três arquivos:

roles.sql: Contém usuários e permissões.

schema.sql: Contém a estrutura das tabelas e banco.

data.sql: Contém os dados inseridos nas tabelas.

Faz o commit automático dos arquivos de backup de volta para o repositório.

3. Restaurando Seu Banco de Dados
Para restaurar o banco:

Instale a Supabase CLI.

Abra o terminal e navegue até a pasta que contém os arquivos de backup.

Execute os seguintes comandos na ordem abaixo:

Bash

supabase db execute --db-url "<SUPABASE_DB_URL>" -f roles.sql
supabase db execute --db-url "<SUPABASE_DB_URL>" -f schema.sql
supabase db execute --db-url "<SUPABASE_DB_URL>" -f data.sql
Isso restaurará as permissões, a estrutura e os dados, retornando o banco ao estado do último backup.

Requisitos
Um projeto no Supabase com banco de dados PostgreSQL.

Supabase CLI instalada (apenas para restauração manual).

Um repositório no GitHub com as Actions habilitadas.

Contribuição
Contribuições são bem-vindas! Se você tiver melhorias ou correções, sinta-se à vontade para enviar um pull request.

Licença
Este projeto está sob a licença MIT. Consulte o arquivo LICENSE para mais detalhes.
