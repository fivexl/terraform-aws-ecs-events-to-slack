import http.client
import json
import logging
import os

import boto3

# Boolean flag, which determins if the incoming even should be printed to the output.
LOG_EVENTS = os.getenv("LOG_EVENTS", "False").lower() in ("true", "1", "t", "yes", "y")

# Set the log level
logging.basicConfig()
log = logging.getLogger()
log.setLevel(os.environ.get("LOG_LEVEL", "INFO"))




# ---------------------------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------------------------------------------------------------------

def ecs_events_parser(detail_type, detail):
    emoji_event_type = {
        "ERROR": ":exclamation:",
        "WARN": ":warning:",
        "INFO": ":information_source:",
    }
    emoji_event_name = {
        "SERVICE_DEPLOYMENT_IN_PROGRESS": ":arrows_counterclockwise:",
        "SERVICE_DEPLOYMENT_COMPLETED": ":white_check_mark:",
        "SERVICE_DEPLOYMENT_FAILED": ":x:",
    }
    emoji_task_status = {
        "PROVISIONING": ":clock1:",
        "PENDING": ":clock6:",
        "ACTIVATING": ":clock11:",
        "RUNNING": ":up:",
        "DEACTIVATING": ":arrow_backward:",
        "STOPPING": ":rewind:",
        "DEPROVISIONING": ":black_left_pointing_double_triangle_with_vertical_bar:",
        "STOPPED": ":black_square_for_stop:",
    }

    if detail_type == "ECS Container Instance State Change":
        result = (
            "*Instance ID:* "
            + detail["ec2InstanceId"]
            + "\n"
            + "• Status: "
            + detail["status"]
        )
        if "statusReason" in detail:
            result = result + "\n" + "• Reason: " + detail["statusReason"]
        return result

    if detail_type == "ECS Deployment State Change":
        result = (
            "*Event Detail:*"
            + emoji_event_type.get(detail["eventType"], "")
            + emoji_event_name.get(detail["eventName"], "")
            + "\n"
            + "• "
            + detail["eventType"]
            + " - "
            + detail["eventName"]
            + "\n"
            + "• Deployment: "
            + detail["deploymentId"]
            + "\n"
            + "• Reason: "
            + detail["reason"]
        )
        return result

    if detail_type == "ECS Service Action":
        result = (
            "*Event Detail:*"
            + emoji_event_type.get(detail["eventType"], "")
            + emoji_event_name.get(detail["eventName"], "")
            + "\n"
            + "• "
            + detail["eventType"]
            + " - "
            + detail["eventName"]
        )
        if "capacityProviderArns" in detail:
            capacity_providers = ""
            for capacity_provider in detail["capacityProviderArns"]:
                try:
                    capacity_providers = (
                        capacity_providers
                        + capacity_provider.split(":")[5].split("/")[1]
                        + ", "
                    )
                except Exception:
                    log.error(
                        "Error parsing clusterArn: `{}`".format(capacity_provider)
                    )
                    capacity_providers = capacity_providers + capacity_provider + ", "
            if capacity_providers != "":
                result = result + "\n" + "• Capacity Providers: " + capacity_providers
        return result

    if detail_type == "ECS Task State Change":
        container_instance_id = "UNKNOWN"
        if "containerInstanceArn" in detail:
            try:
                container_instance_id = (
                    detail["containerInstanceArn"].split(":")[5].split("/")[2]
                )
            except Exception:
                log.error(
                    "Error parsing containerInstanceArn: `{}`".format(
                        detail["containerInstanceArn"]
                    )
                )
                container_instance_id = detail["containerInstanceArn"]
        try:
            task_definition = (
                detail["taskDefinitionArn"].split(":")[5].split("/")[1]
                + ":"
                + detail["taskDefinitionArn"].split(":")[6]
            )
        except Exception:
            log.error(
                "Error parsing taskDefinitionArn: `{}`".format(
                    detail["taskDefinitionArn"]
                )
            )
            task_definition = detail["taskDefinitionArn"]
        try:
            detail["taskArn"].split(":")[5].split("/")[2]
        except Exception:
            log.error("Error parsing taskArn: `{}`".format(detail["taskArn"]))
            detail["taskArn"]
        result = (
            "*Event Detail:* "
            + "\n"
            + "• Task Definition: "
            + task_definition
            + "\n"
            + "• Last: "
            + detail["lastStatus"]
            + " "
            + emoji_task_status.get(detail["lastStatus"], "")
            + "\n"
            + "• Desired: "
            + detail["desiredStatus"]
            + " "
            + emoji_task_status.get(detail["desiredStatus"], "")
        )
        if container_instance_id != "UNKNOWN":
            result = result + "\n" + "• Instance ID: " + container_instance_id
        if detail["lastStatus"] == "RUNNING":
            if "healthStatus" in detail:
                result = result + "\n" + "• HealthStatus: " + detail["healthStatus"]
        if detail["lastStatus"] == "STOPPED":
            if "stopCode" in detail:
                result = result + "\n" + ":bangbang: Stop Code: " + detail["stopCode"]
            if "stoppedReason" in detail:
                result = (
                    result + "\n" + ":bangbang: Stop Reason: " + detail["stoppedReason"]
                )
            if "containers" in detail:
                result = result + "\n" + "Task containers and their exit code:"
                for container in detail["containers"]:
                    result = (
                        result
                        + "\n"
                        + " - "
                        + container["name"]
                        + ": "
                        + str(container.get("exitCode", "unknown"))
                    )
        return result

    return f"*Event Detail:* ```{json.dumps(detail, indent=4)}```"


# Input: EventBridge Message
# Output: Slack Message
def event_to_amazon_q(event):
    event_id = event.get("id")
    detail_type = event.get("detail-type")
    account = event.get("account")
    time = event.get("time")
    region = event.get("region")
    detail = event.get("detail")

    # Parse resource ARNs
    resources = []
    for resource in event.get("resources", []):
        try:
            resources.append(":dart: " + resource.split(":")[5])
        except Exception:
            log.error(f"Error parsing the resource ARN: `{resource}`")
            resources.append(":dart: " + resource)

    known_detail = ecs_events_parser(detail_type, detail)

    # Format message for Amazon Q
    message = {
        "version": "1.0",
        "source": "custom",
        "id": event_id,
        "content": {
            "textType": "client-markdown",
            "title": detail_type,
            "description": known_detail if known_detail else f"```{json.dumps(detail, indent=4)}```" + f"\r\n• account: {account}" + f"\r\n• time: {time}", 
            "keywords": [region] if region else []
        },
        "metadata": {
            "threadId": event_id,
            "summary": detail_type,
            "eventType": detail_type,
            "relatedResources": resources,
            "additionalContext": {
                "account": account,
                "time": time
            }
        }
    }

    return message




# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA HANDLER
# ---------------------------------------------------------------------------------------------------------------------

def lambda_handler(event, context):
    if LOG_EVENTS:
        log.info("Event logging enabled: `{}`".format(json.dumps(event)))

    if event.get("source") != "aws.ecs":
        raise ValueError('The source of the incoming event is not "aws.ecs"')

    try:
 
        # Get region from environment variable or use current region
        region = os.getenv('AWS_REGION', 'us-east-1')
        sns_client = boto3.client('sns', region_name=region)

        # Get SNS topic ARN from environment variable
        amazon_q_sns_topic_arn = os.getenv('SNS_TOPIC_ARN')
        if not amazon_q_sns_topic_arn:
            raise ValueError("SNS_TOPIC_ARN environment variable is not set")

   

        response = sns_client.publish(
            TopicArn=amazon_q_sns_topic_arn,
            Message=json.dumps(event_to_amazon_q(event)),
        )

        log.info(f"Successfully published message to SNS: {response}")
        return json.dumps({"code": response})

    except Exception as e:
        log.error(f"Error processing event: {str(e)}")
        raise

# For local testing
if __name__ == "__main__":
    with open("./test/eventbridge_event.json") as f:
        test_event = json.load(f)
    lambda_handler(test_event, "default_context")
