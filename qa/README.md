# QA do HospitalCore Management

Esta pasta contém o processo de teste de software do projeto.

Execute a suíte local com:

```powershell
.\qa\run-qa.ps1
```

Com Oracle disponível, aplique as migrations e execute:

```powershell
sql usuario/senha@localhost:1521/FREEPDB1 @qa/sql/run_all.sql
```

Arquivos principais:

- `TEST_PLAN.md`: estratégia, entradas, saídas e ambientes
- `TEST_CASES.md`: cenários funcionais e negativos
- `TRACEABILITY_MATRIX.md`: requisitos ligados à implementação e aos testes
- `ACCEPTANCE_CRITERIA.md`: gates objetivos
- `BUG_REPORT.md`: defeitos, riscos e impedimentos
- `EXECUTION_REPORT.md`: resultados realmente executados
- `RELEASE_CHECKLIST.md`: decisão de release
- `sql`: smoke tests, invariantes e performance
- `evidence`: saídas geradas pelo runner
