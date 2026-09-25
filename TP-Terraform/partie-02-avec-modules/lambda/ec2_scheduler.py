"""Démarre / arrête les instances EC2 du TP.

Déclenchée par EventBridge Scheduler avec l'événement {"action": "start"} ou {"action": "stop"}.
Les IDs d'instances sont passés via la variable d'environnement INSTANCE_IDS (séparés par des virgules),
et le rôle IAM de la Lambda n'autorise QUE ces instances (moindre privilège).
"""
import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")


def handler(event, context):
    action = str((event or {}).get("action", "")).lower()
    instance_ids = [i.strip() for i in os.environ.get("INSTANCE_IDS", "").split(",") if i.strip()]

    if not instance_ids:
        raise ValueError("INSTANCE_IDS est vide")

    if action == "start":
        changes = ec2.start_instances(InstanceIds=instance_ids)["StartingInstances"]
    elif action == "stop":
        changes = ec2.stop_instances(InstanceIds=instance_ids)["StoppingInstances"]
    else:
        raise ValueError(f"Action invalide : {action!r} (attendu : 'start' ou 'stop')")

    result = [
        {
            "instance_id": c["InstanceId"],
            "previous_state": c["PreviousState"]["Name"],
            "current_state": c["CurrentState"]["Name"],
        }
        for c in changes
    ]
    logger.info(json.dumps({"action": action, "instances": result}))
    return {"action": action, "instances": result}
