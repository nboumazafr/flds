#!/usr/bin/env bash

#
# Only for temp testing of a POC- Assumes you have added allUser to CloudRun Invoker role
# Copy KEY_VALUE from Services -> Credentials
#

export ENDPOINTS_HOST=gateway-ijzjfv7ydq-ue.a.run.app;
curl --request GET \
   --header "content-type:application/json" \
   "https://${ENDPOINTS_HOST}/health?key=KEY_VALUE"