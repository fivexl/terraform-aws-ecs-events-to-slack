import http.client
import json
import logging
import os

import boto3

# Clients 
client_logs = boto3.client('logs')
client_ecs = boto3.client("ecs")

# Boolean flag, which determins if the incoming even should be printed to the output.
LOG_EVENTS = os.getenv("LOG_EVENTS", "False").lower() in ("true", "1", "t", "yes", "y")

# Set the log level
logging.basicConfig()
log = logging.getLogger()
log.setLevel(os.environ.get("LOG_LEVEL", "INFO"))


SLACK_WEBHOOK_URL_SOURCE_TYPE = os.getenv(
    "SLACK_WEBHOOK_URL_SOURCE_TYPE", "text"
).lower()
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")


def get_slack_credentials(value: str, source_type: str) -> str:
    if not value:
        raise RuntimeError(
            "The required env variable SLACK_WEBHOOK_URL is not set or empty!"
        )
    try:
        if source_type == "text":
            log.info("Getting slack credentials as plain text")
            return value

        elif source_type == "secretsmanager":
            log.info("Getting slack credentials from secretsmanager")
            secretsmanager = boto3.client("secretsmanager")
            secretsmanagerResponse = secretsmanager.get_secret_value(
                SecretId=value,
            )
            return secretsmanagerResponse["SecretString"]

        elif source_type == "ssm":
            log.info("Getting slack credentials from ssm")
            ssm = boto3.client("ssm")
            ssmResponse = ssm.get_parameter(
                Name=value,
                WithDecryption=True,
            )
            return ssmResponse["Parameter"]["Value"]
        else:
            raise RuntimeError(
                "SLACK_WEBHOOK_URL_SOURCE_TYPE is not valid, it should be one of: text, secretsmanager, ssm"
            )

    except Exception as e:
        raise RuntimeError(
            f"Error getting slack credentials from {source_type} `{value}`: {e}"
        ) from e


if SLACK_WEBHOOK_URL_SOURCE_TYPE not in ("text", "secretsmanager", "ssm"):
    raise RuntimeError(
        "SLACK_WEBHOOK_URL_SOURCE_TYPE is not valid, it should be one of: text, secretsmanager, ssm"
    )

SLACK_WEBHOOK_URL = get_slack_credentials(
    SLACK_WEBHOOK_URL, SLACK_WEBHOOK_URL_SOURCE_TYPE
)

# Enable or disable trying to get the logs from the ECS task
GET_ECS_TASK_LOGS = os.getenv("LOG_EVENTS", "False").lower() in ("true", "1", "t", "yes", "y")

# ---------------------------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------------------------------------------------------------------

# Input: CloudWatch Log Group Name and Log Stream Name
# Output: Last 10 logs from the log stream { 'timestamp': 123, 'message': 'string', 'ingestionTime': 123 },
def get_last_logs_cw(log_group_name, log_stream_name):
    response = client_logs.get_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        limit=10,
        startFromHead=False  # Get the most recent events
    )
    return response['events']


# Input: ECS TaskDefinition ARN and Task ID
# Output: Logs from the task
def get_logs(task_definition, task_id):
    result = ""

    if task_id is None:
        log.error("Task ID is not defined for taskDefinition: `{}`".format(task_definition))
        return result
    
    # get the task definition without tags
    task_definition = client_ecs.describe_task_definition(taskDefinition=task_definition)
    for container in task_definition["taskDefinition"]["containerDefinitions"]:
        # Skip non-essential containers
        if container.get("essential", False) is False:
            continue
        log_driver = container.get("logConfiguration", {}).get("logDriver", "")
        container_name = container.get("name", "")
        # Skip unsupported log drivers
        if log_driver != "awslogs":
            continue

        log_group = container.get("logConfiguration", {}).get("options", {}).get("awslogs-group", "")
        log_stream_prefix = container.get("logConfiguration", {}).get("options", {}).get("awslogs-stream-prefix", "")
        log_region = container.get("logConfiguration", {}).get("options", {}).get("awslogs-region", "")
        if not log_group or not log_stream_prefix or not log_region:
            log.error("Log group or stream or log_region is not defined for container: `{}`".format(container))
            continue
        # Fix the log group and stream
        log_group = log_group.replace("/", "%2F")
        log_stream_prefix = log_stream_prefix.replace("/", "%2F")
        logs_link = f"https://{log_region}.console.aws.amazon.com/cloudwatch/home?region={log_region}#logsV2:log-groups/log-group/{log_group}/log-events/{log_stream_prefix}%2{container_name}%2{task_id}"  
        # transform and fix the logs link
        result = result + f"\n [Logs {container_name}]({logs_link})"
        # get the last logs
        last_logs = get_last_logs_cw(log_group, f"{log_stream_prefix}/{container_name}/{task_id}")
        if last_logs:
            result = result + "\n" + "```"
            for log in last_logs:
                result = result + log["message"] + "\n"
            result = result + "```"   
            
    return result


# Input: EventBridge Message detail_type and detail
# Output: mrkdwn text
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
            task_id = detail["taskArn"].split(":")[5].split("/")[2]
        except Exception:
            log.error("Error parsing taskArn: `{}`".format(detail["taskArn"]))
            task_id = None
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
        if GET_ECS_TASK_LOGS and "taskDefinitionArn" in detail:
            result = result + get_logs(detail["taskDefinitionArn"], task_id)
                
        return result

    return f"*Event Detail:* ```{json.dumps(detail, indent=4)}```"


# Input: EventBridge Message
# Output: Slack Message
def event_to_slack_message(event):
    event_id = event.get("id")
    detail_type = event.get("detail-type")
    account = event.get("account")
    time = event.get("time")
    region = event.get("region")
    resources = []
    for resource in event["resources"]:
        try:
            resources.append(":dart: " + resource.split(":")[5])
        except Exception:
            log.error("Error parsing the resource ARN: `{}`".format(resource))
            resources.append(":dart: " + resource)
    detail = event.get("detail")
    known_detail = ecs_events_parser(detail_type, detail)
    blocks = []
    contexts = []
    title = f"*{detail_type}*"
    blocks.append({"type": "section", "text": {"type": "mrkdwn", "text": title}})
    if resources:
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*Resources*:\n" + "\n".join(resources),
                },
            }
        )
    if detail and not known_detail:
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Event Detail:* ```{json.dumps(detail, indent=4)}```",
                },
            }
        )
    if known_detail:
        blocks.append(
            {"type": "section", "text": {"type": "mrkdwn", "text": known_detail}}
        )
    contexts.append({"type": "mrkdwn", "text": f"Account: {account} Region: {region}"})
    contexts.append({"type": "mrkdwn", "text": f"Time: {time} UTC Id: {event_id}"})
    blocks.append({"type": "context", "elements": contexts})
    blocks.append({"type": "divider"})
    return {"blocks": blocks}


# Slack web hook example
# https://hooks.slack.com/services/XXXXXXX/XXXXXXX/XXXXXXXXXX
def post_slack_message(hook_url, message):
    log.debug(f"Sending message: {json.dumps(message, indent=4)}")
    headers = {"Content-type": "application/json"}
    connection = http.client.HTTPSConnection("hooks.slack.com")
    connection.request(
        "POST",
        hook_url.replace("https://hooks.slack.com", ""),
        json.dumps(message),
        headers,
    )
    response = connection.getresponse()
    log.debug(
        "Response: {}, message: {}".format(response.status, response.read().decode())
    )
    return response.status


# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA HANDLER
# ---------------------------------------------------------------------------------------------------------------------


def lambda_handler(event, context):
    if LOG_EVENTS:
        log.info("Event logging enabled: `{}`".format(json.dumps(event)))

    if event.get("source") != "aws.ecs":
        raise ValueError('The source of the incoming event is not "aws.ecs"')

    slack_message = event_to_slack_message(event)
    response = post_slack_message(SLACK_WEBHOOK_URL, slack_message)
    if response != 200:
        log.error(
            "Error: received status `{}` using event `{}` and context `{}`".format(
                response, event, context
            )
        )
    return json.dumps({"code": response})


# For local testing
if __name__ == "__main__":
    with open("./test/eventbridge_event.json") as f:
        test_event = json.load(f)
    lambda_handler(test_event, "default_context")
