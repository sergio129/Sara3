#!/usr/bin/env node
import { App } from 'aws-cdk-lib';
import { Sara3LoadTestStack } from '../lib/sara3-loadtest-stack';

const app = new App();
new Sara3LoadTestStack(app, 'Sara3LoadTestStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
