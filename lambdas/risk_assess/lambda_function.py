import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"[RISK_ASSESS] Evento recibido: {json.dumps(event)}")

    amount  = event.get("amount", 0)
    country = event.get("country", "")

    # Regla de negocio:
    # high  → monto > 10,000 O país distinto a MX
    # low   → monto <= 10,000 Y país == MX
    if amount > 10000 or country != "MX":
        risk_level = "high"
    else:
        risk_level = "low"

    event["risk_level"] = risk_level

    logger.info(
        f"[RISK_ASSESS] tx={event.get('transaction_id')} "
        f"amount={amount} country={country} → risk={risk_level}"
    )
    return event