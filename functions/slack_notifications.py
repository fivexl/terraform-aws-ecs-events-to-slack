import os
import json
import logging
import http.client


# ---------------------------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------------------------------------------------------------------


def read_env_variable_or_die(env_var_name):
    value = os.environ.get(env_var_name, '')
    if value == '':
        message = f'Required env variable {env_var_name} is not defined or set to empty string'
        raise EnvironmentError(message)
    return value


def is_sns_event(event):
    return event.get("Records") and event.get("Records")[0].get("Sns")

# Input: EventBridge Message detail_type and detail
# Output: mrkdwn text


def ecs_events_parser(detail_type, detail):
    emoji_event_type = {
        'ERROR': ':exclamation:',
        'WARN': ':warning:',
        'INFO': ':information_source:'
    }
    emoji_event_name = {
        'SERVICE_DEPLOYMENT_IN_PROGRESS': ':arrows_counterclockwise:',
        'SERVICE_DEPLOYMENT_COMPLETED': ':white_check_mark:',
        'SERVICE_DEPLOYMENT_FAILED': ':x:'
    }
    emoji_task_status = {
        'PROVISIONING': ':clock1:',
        'PENDING': ':clock6:',
        'ACTIVATING': ':clock11:',
        'RUNNING': ':up:',
        'DEACTIVATING': ':arrow_backward:',
        'STOPPING': ':rewind:',
        'DEPROVISIONING': ':black_left_pointing_double_triangle_with_vertical_bar:',
        'STOPPED': ':black_square_for_stop:'
    }

    if detail_type == 'ECS Deployment State Change':
        result = f'*Event Detail:*' + emoji_event_type.get(detail['eventType'], "") + emoji_event_name.get(detail['eventName'], "") + '\n' + \
                 '• ' + detail['eventType'] + ' - ' + detail['eventName'] + '\n' + \
                 '• Deployment: ' + detail['deploymentId'] + '\n' + \
                 '• Reason: ' + detail['reason']
        return result

    if detail_type == 'ECS Service Action':
        result = f'*Event Detail:*' + emoji_event_type.get(detail['eventType'], "") + emoji_event_name.get(detail['eventName'], "") + '\n' + \
                 '• ' + detail['eventType'] + ' - ' + detail['eventName']
        if 'capacityProviderArns' in detail:
            capacity_providers = ""
            for capacity_provider in detail['capacityProviderArns']:
                try:
                    capacity_providers = capacity_providers + capacity_provider.split(':')[5].split('/')[1] + ", "
                except Exception:
                    logging.warning('Error parsing clusterArn: `{}`'.format(capacity_provider))
                    capacity_providers = capacity_providers + capacity_provider + ", "
            if capacity_providers != "":
                result = result + '\n' + '• Capacity Providers: ' + capacity_providers
        return result

    if detail_type == 'ECS Task State Change':
        container_instance_id = "UNKNOWN"
        if 'containerInstanceArn' in detail:
            try:
                container_instance_id = detail['containerInstanceArn'].split(':')[5].split('/')[2]
            except Exception:
                logging.warning('Error parsing containerInstanceArn: `{}`'.format(detail['containerInstanceArn']))
                container_instance_id = detail['containerInstanceArn']
        try:
            task_definition = detail['taskDefinitionArn'].split(':')[5].split(
                '/')[1] + ":" + detail['taskDefinitionArn'].split(':')[6]
        except Exception:
            logging.warning('Error parsing taskDefinitionArn: `{}`'.format(detail['taskDefinitionArn']))
            task_definition = detail['taskDefinitionArn']
        try:
            task = detail['taskArn'].split(':')[5].split('/')[2]
        except Exception:
            logging.warning('Error parsing taskArn: `{}`'.format(detail['taskArn']))
            task = detail['taskArn']
        result = f'*Event Detail:* ' + '\n' + \
                 '• Task Definition: ' + task_definition + '\n' + \
                 '• Last: ' + detail['lastStatus'] + ' ' + emoji_task_status.get(detail['lastStatus'], "") + '\n' + \
                 '• Desired: ' + detail['desiredStatus'] + ' ' + emoji_task_status.get(detail['desiredStatus'], "")
        if container_instance_id != "UNKNOWN":
            result = result + '\n' + '• Instance ID: ' + container_instance_id
        if detail['lastStatus'] == 'RUNNING':
            if 'healthStatus' in detail:
                result = result + '\n' + '• HealthStatus: ' + detail['healthStatus']
        if detail['lastStatus'] == 'STOPPED':
            if 'stopCode' in detail:
                # Skip Stop Codes for Task State Change
                if detail['stopCode'] in os.environ.get('SKIP_TASK_STOP_CODES', '').split(','):
                    return 'SKIP_EVENT'
                result = result + '\n' + ':bangbang: Stop Code: ' + detail['stopCode']
            if 'stoppedReason' in detail:
                # Skip Stopped Reasons for Task State Change
                for skip_task_stopped_reason in os.environ.get('SKIP_TASK_STOPPED_REASONS', '').split(','):
                    if detail['stoppedReason'].find(skip_task_stopped_reason) != -1:
                        return 'SKIP_EVENT'
                result = result + '\n' + ':bangbang: Stop Reason: ' + detail['stoppedReason']
        return result

    return f'*Event Detail:* ```{json.dumps(detail, indent=4)}```'


# Input: EventBridge Message
# Output: Slack Message
def event_to_slack_message(message):
    event_id = message['id'] if 'id' in message else None
    detail_type = message['detail-type']
    source = message['source'] if 'source' in message else None
    account = message['account'] if 'account' in message else None
    time = message['time'] if 'time' in message else None
    region = message['region'] if 'region' in message else None
    resources = ""
    for resource in message['resources']:
        try:
            resources = resources + ":dart: " + resource.split(':')[5] + "\n"
        except Exception:
            logging.warning('Error parsing resource: `{}`'.format(resource))
            resources = resources + ":dart: " + resource + "\n"
    detail = message['detail'] if 'detail' in message else None
    known_detail = ""
    if source == 'aws.ecs':
        known_detail = ecs_events_parser(detail_type, detail)
    if known_detail == 'SKIP_EVENT':
        return known_detail
    blocks = list()
    contexts = list()
    title = f'*{detail_type}* - *{source}*'
    blocks.append(
        {
            'type': 'section',
            'text': {
                'type': 'mrkdwn',
                'text': title
            }
        }
    )
    if resources != "":
        blocks.append(
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': "Involved resources \n" + resources
                }
            }
        )
    if detail is not None and known_detail == "":
        blocks.append(
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f'*Event Detail:* ```{json.dumps(detail, indent=4)}```'
                }
            }
        )
    if known_detail != "":
        blocks.append(
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': known_detail
                }
            }
        )
    contexts.append({
        'type': 'mrkdwn',
        'text': f'Account: {account} Region: {region}'
    })
    contexts.append({
        'type': 'mrkdwn',
        'text': f'Time: {time} UTC Id: {event_id}'
    })
    blocks.append({
        'type': 'context',
        'elements': contexts
    })
    blocks.append({'type': 'divider'})
    return {'blocks': blocks}


# Slack web hook example
# https://hooks.slack.com/services/XXXXXXX/XXXXXXX/XXXXXXXXXX
def post_slack_message(hook_url, message):
    logging.info(f'Sending message: {json.dumps(message)}')
    headers = {'Content-type': 'application/json'}
    connection = http.client.HTTPSConnection('hooks.slack.com')
    connection.request('POST',
                       hook_url.replace('https://hooks.slack.com', ''),
                       json.dumps(message),
                       headers)
    response = connection.getresponse()
    logging.info('Response: {}, message: {}'.format(response.status, response.read().decode()))
    return response.status


# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA HANDLER
# ---------------------------------------------------------------------------------------------------------------------


def lambda_handler(event, context):
    if 'LOG_EVENTS' in os.environ and os.environ['LOG_EVENTS'] == 'True':
        logging.warning('Event logging enabled: `{}`'.format(json.dumps(event)))
    hook_url = read_env_variable_or_die('HOOK_URL')
    if not is_sns_event(event):
        raise Exception('Incoming Event is not SNS message')
    event_message = event['Records'][0]['Sns']['Message']
    try:
        event_message_json = json.loads(event_message)
    except json.JSONDecodeError as err:
        logging.exception(f'JSON decode error: {err}')
        raise Exception('JSON decode error')
    slack_message = event_to_slack_message(event_message_json)
    if slack_message == 'SKIP_EVENT':
        logging.info('event skipped')
        return json.dumps({"code": 200, "info": "event_skipped"})
    response = post_slack_message(hook_url, slack_message)
    if response != 200:
        logging.error(
            "Error: received status `{}` using event `{}` and context `{}`".format(response, event,
                                                                                   context))
    return json.dumps({"code": response})


# For local testing
if __name__ == '__main__':
    with open('./test/sns_event.json') as f:
        test_event = json.load(f)
    lambda_handler(test_event, "default_context")
