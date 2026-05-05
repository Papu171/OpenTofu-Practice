# Banking Transaction Processor — AWS Step Functions Pipeline

## Descripción del escenario

Este proyecto implementa un simulador de sistema antifraude bancario usando AWS Step Functions, AWS Lambda y Amazon S3, desplegado completamente con OpenTofu (Infrastructure as Code).

El pipeline procesa transacciones bancarias de forma automática: cuando un cliente realiza un pago, el sistema valida los datos, evalúa el nivel de riesgo y decide si la transacción se aprueba directamente o se envía a revisión manual por un agente humano. Las reglas de negocio se basan en dos factores: el monto de la transacción y el país de origen. Transacciones mayores a $10,000 USD o provenientes de países distintos a México se consideran de alto riesgo y requieren revisión. Las demás se aprueban automáticamente.

Este tipo de lógica es común en sistemas reales como los usados por instituciones financieras para detectar fraudes, lavado de dinero o transacciones inusuales sin intervención humana en el camino feliz.

---

## Arquitectura del pipeline

```
Input JSON
    │
    ▼
[ValidateTransaction]  ──(error)──► [ValidationFailed] FAIL
    │
    ▼
[RiskAssessTransaction] ──(error)──► [ValidationFailed] FAIL
    │
    ▼
[ChooseRoute]
    ├── risk_level == "high" ──► [RouteToReview]   ──► [TransactionFlaggedForReview] SUCCEED
    └── risk_level == "low"  ──► [RouteToApproved] ──► [TransactionApproved] SUCCEED
```

---

## Componentes

### 3 Funciones Lambda

| Lambda | Descripción |
|--------|-------------|
| `banking-tx-processor-validate` | Valida que `amount > 0`, `country` tenga formato ISO de 2 letras y `account` tenga formato `XXXX-XXXX` |
| `banking-tx-processor-risk-assess` | Calcula `risk_level`: `high` si `amount > 10000` o `country != "MX"`, `low` en caso contrario |
| `banking-tx-processor-route` | Guarda el JSON de la transacción en S3 bajo `approved/` o `review/` según el nivel de riesgo |

### Step Function (7 estados)

1. `ValidateTransaction` — Task
2. `RiskAssessTransaction` — Task
3. `ChooseRoute` — **Choice** (1 estado Choice con 2 branches)
4. `RouteToReview` — Task
5. `RouteToApproved` — Task
6. `TransactionFlaggedForReview` — Succeed
7. `ValidationFailed` — Fail

---

## Input de ejemplo

```json
{
  "transaction_id": "tx-9912",
  "account": "1234-5678",
  "amount": 15000.00,
  "country": "MX",
  "merchant": "Amazon"
}
```

---

## Requisitos previos

- AWS CLI v2 instalado
- OpenTofu instalado
- Credenciales de AWS Academy activas

---

## Pasos de despliegue

```bash
# 1. Configurar credenciales (obtenerlas de AWS Academy → AWS Details)
$env:AWS_ACCESS_KEY_ID="ASIA..."
$env:AWS_SECRET_ACCESS_KEY="xxxx..."
$env:AWS_SESSION_TOKEN="xxxx..."

# 2. Verificar conexión
aws sts get-caller-identity

# 3. Inicializar e inicializar OpenTofu
tofu init

# 4. Desplegar infraestructura
tofu apply -auto-approve
```

El despliegue crea automáticamente:
- 1 bucket S3 con versionado habilitado
- 3 funciones Lambda (Python 3.12)
- 2 IAM roles con políticas mínimas necesarias
- 1 Step Function con la lógica de negocio

---

## Pruebas

Ejecutar desde la consola de AWS → Step Functions → `banking-tx-processor-state-machine` → Start execution:

### Test 1 — Alto riesgo por monto (→ `review/`)
```json
{"transaction_id": "tx-0001", "account": "1234-5678", "amount": 15000.00, "country": "MX", "merchant": "Amazon"}
```

### Test 2 — Alto riesgo por país (→ `review/`)
```json
{"transaction_id": "tx-0002", "account": "9999-0001", "amount": 500.00, "country": "US", "merchant": "Walmart"}
```

### Test 3 — Aprobada (→ `approved/`)
```json
{"transaction_id": "tx-0003", "account": "4321-8765", "amount": 350.00, "country": "MX", "merchant": "Oxxo"}
```

### Test 4 — Inválida (→ `ValidationFailed`)
```json
{"transaction_id": "tx-0004", "account": "INVALID", "amount": -100, "country": "MEX", "merchant": ""}
```

### Verificar archivos en S3
```bash
aws s3 ls s3://banking-tx-processor-emiliano-corona --recursive
```

---

## Destruir infraestructura

```bash
tofu destroy -auto-approve
```

Esto elimina todos los recursos: bucket S3, Lambdas, IAM roles y Step Function.

---

## Estructura del proyecto

```
proyecto/
├── lambdas/
│   ├── validate/lambda_function.py
│   ├── risk_assess/lambda_function.py
│   └── route/lambda_function.py
├── modules/
│   └── lambda_function/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── tests/
│   ├── test_high_risk_amount.json
│   ├── test_high_risk_country.json
│   ├── test_low_risk.json
│   └── test_invalid.json
├── main.tf
├── step_function.tf
├── iam.tf
├── variables.tf
└── outputs.tf
```

---

## Notas técnicas

- Desarrollado con **OpenTofu** (compatible con Terraform)
- Runtime de Lambdas: **Python 3.12**
- Región: **us-east-1**
- Cada Lambda recibe el evento completo, agrega campos y lo retorna
- El bucket tiene `force_destroy = true` para que `tofu destroy` funcione aunque haya archivos
