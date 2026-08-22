# Auditoria do ambiente local

Data: 18 de agosto de 2026

Ambiente: Windows 10 amd64, PowerShell, workspace em `P:\certificacao\hospital-java`

## Resultado executivo

O ambiente já contém as ferramentas necessárias para desenvolver e compilar o backend e o frontend. Nenhuma instalação foi realizada. Maven 3.9.16 utiliza corretamente o JDK 21 configurado em `JAVA_HOME`, apesar de o `java` global no PATH apontar para JDK 26. O projeto fixa Java 21 no Maven para manter compatibilidade LTS.

Oracle Database, Oracle XE/Free, SQLcl e SQL Plus não foram encontrados no PATH, nas variáveis de ambiente, nos serviços ou nos diretórios usuais inspecionados. Docker está instalado, mas seu serviço está parado. A estratégia prevista é Oracle Free em contêiner apenas quando o ambiente de banco for executado, sem alterar instalações globais.

## Inventário

| Componente | Estado | Versão ou caminho | Decisão |
|---|---|---|---|
| Java no PATH | Encontrado | Temurin 26.0.1 | Não usar no build do projeto |
| javac no PATH | Encontrado | 26.0.1 | Maven usará o JDK 21 |
| JAVA_HOME | Encontrado | `P:\nexora-bank\.tools\jdk-21\jdk-21.0.12+8` | Reutilizar |
| Maven | Encontrado | 3.9.16 | Reutilizar |
| Gradle | Ausente | — | Não instalar |
| Node.js | Encontrado | 24.18.0 | Reutilizar |
| npm | Encontrado | 10.4.0 | Reutilizar |
| Git | Encontrado | 2.55.0.windows.1 | Reutilizar |
| Docker | Encontrado | 26.1.1 | Daemon iniciado em 19 de agosto de 2026 |
| Oracle Database/XE/Free | Não detectado | — | Usar contêiner quando autorizado |
| SQLcl / SQL Plus | Ausente | — | Não necessário para compilar |
| PostgreSQL | Serviço encontrado | 15, em execução | Preservar; não usar como substituto |
| DBeaver | Não detectado | — | Não instalar |
| VS Code | Encontrado | 1.133.0 | Reutilizar |
| IntelliJ IDEA | Encontrado | 2026.2.0.1 | Reutilizar |
| Python | Alias sem runtime acessível | WindowsApps | Não necessário |
| PowerShell | Encontrado | Shell atual | Reutilizar |
| WSL | Encontrado | 2.1.5.0 | Opcional |
| GitHub CLI | Ausente | — | Não necessário |

## Restrições e observações

O Docker Desktop não foi iniciado automaticamente. Nenhum serviço, variável global ou configuração compartilhada foi alterado. A execução de testes Oracle reais permanecerá marcada como bloqueada até haver uma instância Oracle acessível. Testes unitários e de arquitetura não devem simular como aprovado aquilo que depende de Oracle.
