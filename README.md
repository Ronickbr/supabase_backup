# Backup do Banco de Dados Supabase com GitHub Actions

Este repositório oferece uma maneira simples de automatizar backups do seu banco de dados Supabase usando GitHub Actions. Ele cria backups diários das funções (roles), esquema (schema) e dados do seu banco de dados, e os armazena no seu repositório. Ele também inclui um mecanismo para restaurar facilmente seu banco de dados caso algo dê errado.

---

## Funcionalidades

- **Backups Diários Automáticos:** Backups agendados são executados todos os dias à meia-noite.
- **Separação de Funções, Esquema e Dados:** Cria arquivos de backup modulares para funções, esquema e dados.
- **Controle Flexível do Fluxo de Trabalho:** Habilite ou desabilite backups com uma simples variável de ambiente.
- **Integração com GitHub Actions:** Utiliza o GitHub Actions, gratuito e confiável, para automação.
- **Restauração Fácil do Banco de Dados:** Passos claros para restaurar seu banco de dados a partir dos backups.

---

## Primeiros Passos

### 1. **Configurar Variáveis do Repositório**

Vá para as configurações do seu repositório e navegue até **Actions > Variables**. Adicione o seguinte:

- **Secrets (Segredos):**

  - `SUPABASE_DB_URL`: Sua string de conexão PostgreSQL do Supabase. Formato:  
    `postgresql://<USER>:<PASSWORD>@<HOST>:5432/postgres`

- **Variables (Variáveis):**
  - `BACKUP_ENABLED`: Defina como `true` para habilitar os backups ou `false` para desabilitá-los.

---

### 2. **Como o Fluxo de Trabalho Funciona**

O fluxo de trabalho do GitHub Actions é acionado em:

- Pushes ou pull requests para as branches `main` ou `dev`.
- Acionamento manual através da interface do GitHub.
- Um agendamento diário à meia-noite.

O fluxo de trabalho executa os seguintes passos:

1. Verifica se os backups estão habilitados usando a variável `BACKUP_ENABLED`.
2. Executa o Supabase CLI para criar três arquivos de backup:
   - `roles.sql`: Contém funções e permissões.
   - `schema.sql`: Contém a estrutura do banco de dados.
   - `data.sql`: Contém os dados da tabela.
3. Commita os backups no repositório usando uma ação de auto-commit.

---

### 3. **Restaurando Seu Banco de Dados**

Para restaurar seu banco de dados:

1. Instale o [Supabase CLI](https://supabase.com/docs/guides/cli).
2. Abra um terminal e navegue até a pasta que contém seus arquivos de backup.
3. Execute os seguintes comandos em ordem:

```bash
supabase db execute --db-url "<SUPABASE_DB_URL>" -f roles.sql
supabase db execute --db-url "<SUPABASE_DB_URL>" -f schema.sql
supabase db execute --db-url "<SUPABASE_DB_URL>" -f data.sql
```

Isso restaura funções, esquema e dados, trazendo seu banco de dados de volta ao estado do backup.

### Alternância do Fluxo de Trabalho

Use a variável `BACKUP_ENABLED` para controlar se os backups são executados:

- Defina como `true` para habilitar os backups.
- Defina como `false` para pular os backups sem precisar editar o arquivo de fluxo de trabalho.

## Requisitos

- Um projeto Supabase com um banco de dados PostgreSQL.
- Supabase CLI instalado para restauração manual.
- Um repositório GitHub com Actions habilitado.

## Contribuições

Contribuições são bem-vindas! Se você tiver melhorias ou correções, sinta-se à vontade para enviar um pull request.

## Licença

Este projeto está licenciado sob a Licença MIT. Consulte o arquivo `LICENSE` para obter detalhes.
