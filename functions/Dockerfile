# Use the AWS Lambda Python 3.10 base image (matching your .venv version)
FROM public.ecr.aws/lambda/python:3.10

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

# Copy the function code
# Assuming slack_notifications.py contains your handler
COPY slack_notifications.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (FileName.MethodName)
CMD [ "slack_notifications.lambda_handler" ]
