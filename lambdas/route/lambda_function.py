import json
import boto3
import os
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
BUCKET = os.environ["BUCKET_NAME"]

def lambda_handler(event, context):
    logger.info(f"[ROUTE] Evento recibido: {json.dumps(event)}")

    risk_level     = event.get("risk_level", "low")
    transaction_id = event.get("transaction_id", "unknown")

    # Determinar carpeta destino
    folder = "approved" if risk_level == "low" else "review"

    timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    key       = f"{folder}/{transaction_id}_{timestamp}.json"

    s3.put_object(
        Bucket      = BUCKET,
        Key         = key,
        Body        = json.dumps(event, indent=2),
        ContentType = "application/json"
    )

    event["s3_destination"] = f"s3://{BUCKET}/{key}"
    event["route_status"]   = "stored"

    logger.info(f"[ROUTE] Guardado en {event['s3_destination']}")
    return event