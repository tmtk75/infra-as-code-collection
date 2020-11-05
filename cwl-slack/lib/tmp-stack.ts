import * as cdk from "@aws-cdk/core";
import * as sns from "@aws-cdk/aws-sns";
import * as cloudwatch from "@aws-cdk/aws-cloudwatch";
import * as cwactions from "@aws-cdk/aws-cloudwatch-actions";
import * as iam from "@aws-cdk/aws-iam";
import * as chatbot from "@aws-cdk/aws-chatbot";
import * as logs from "@aws-cdk/aws-logs";
import { RemovalPolicy } from "@aws-cdk/core";

export class ChatbotSampleStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const PROJECT_NAME = process.env.PROJECT_NAME;
    if (!PROJECT_NAME) {
      throw new Error(`No PROJECT_NAME. Ensure it.`);
    }

    const topic = new sns.Topic(this, PROJECT_NAME, {
      displayName: PROJECT_NAME,
      topicName: PROJECT_NAME,
    });

    // Chatbot Role & Policy
    const chatbotRole = new iam.Role(this, "chatbot-role", {
      roleName: `${PROJECT_NAME}-chatbot-role`,
      assumedBy: new iam.ServicePrincipal("sns.amazonaws.com"),
    });

    chatbotRole.addToPolicy(
      new iam.PolicyStatement({
        resources: ["*"],
        actions: [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
        ],
      })
    );

    // Chatbot Slack Notification Integration
    const bot = new chatbot.CfnSlackChannelConfiguration(
      this,
      `${PROJECT_NAME}-slack-notification`,
      {
        configurationName: "sample-slack-notification",
        iamRoleArn: chatbotRole.roleArn,
        slackChannelId: process.env.CHANNEL_ID as string,
        slackWorkspaceId: process.env.WORKSPACE_ID as string,
        snsTopicArns: [topic.topicArn],
      }
    );

    const logGroup = new logs.LogGroup(this, "sample-source-log-group", {
      logGroupName: `${PROJECT_NAME}-source`,
      removalPolicy: RemovalPolicy.DESTROY,
      retention: logs.RetentionDays.ONE_DAY,
    });
    new logs.LogStream(this, "sample-source-log-stream", {
      logGroup: logGroup,
      logStreamName: "test1",
      removalPolicy: RemovalPolicy.DESTROY,
    });

    const metricName = "ErrorCount";

    const mf = new logs.MetricFilter(this, `ErrorCount`, {
      // filterPattern: { logPatternString: '{ $.level = "WARN" }' },
      filterPattern: { logPatternString: "ERROR" },
      logGroup,
      metricName,
      metricNamespace: PROJECT_NAME,
    });

    const alarm = new cloudwatch.Alarm(this, "Alarm", {
      metric: new cloudwatch.Metric({
        namespace: PROJECT_NAME,
        metricName,
        statistic: "SampleCount",
      }).with({ period: cdk.Duration.minutes(1) }),
      actionsEnabled: true,
      threshold: 0,
      evaluationPeriods: 1,
      datapointsToAlarm: 1,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
    });

    const action = new cwactions.SnsAction(topic);
    alarm.addAlarmAction(action);
  }
}

const app = new cdk.App();
new ChatbotSampleStack(app, "ChatbotSampleStack");
app.synth();
