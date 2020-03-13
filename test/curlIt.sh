#!/usr/bin/env bash

#
# Only for temp testing of a POC- Assumes you have added allUser to CloudRun Invoker role
#

export ENDPOINTS_HOST=gateway-ijzjfv7ydq-ue.a.run.app;
curl --request GET \
   --header "content-type:application/json" \
   "https://${ENDPOINTS_HOST}/health?key=AIzaSyCTvf5BAsaRYADEOXE0MhC9jGu6d56M9cg"