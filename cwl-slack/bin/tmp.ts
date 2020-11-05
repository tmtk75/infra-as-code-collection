#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "@aws-cdk/core";
import { ChatbotSampleStack } from "../lib/tmp-stack";

const app = new cdk.App();
new ChatbotSampleStack(app, "ChatbotSampleStack");
