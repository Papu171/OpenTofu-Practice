import json
import re
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"[VALIDATE] Evento recibido: {json.dumps(event)}")

    transaction_id = event.get("transaction_id", "")
    account        = event.get("account", "")
    amount         = event.get("amount", None)
    country        = event.get("country", "")
    merchant       = event.get("merchant", "")

    # Validar amount > 0
    if not isinstance(amount, (int, float)) or amount <= 0:
        raise ValueError(f"amount inválido: {amount}. Debe ser numérico y > 0.")

    # Validar country: exactamente 2 letras ISO
    if not re.fullmatch(r"[A-Z]{2}", country):
        raise ValueError(f"country inválido: '{country}'. Debe ser código ISO de 2 letras (ej. MX, US).")

    # Validar account: formato XXXX-XXXX
    if not re.fullmatch(r"\d{4}-\d{4}", account):
        raise ValueError(f"account inválido: '{account}'. Formato esperado: XXXX-XXXX.")

    # Validar description no vacía
    if not merchant or not str(merchant).strip():
        raise ValueError("merchant no puede estar vacío.")

    event["validation_status"] = "passed"
    event["amount"]             = float(amount)   # normalizar a float

    logger.info(f"[VALIDATE] Validación exitosa para tx: {transaction_id}")
    return event