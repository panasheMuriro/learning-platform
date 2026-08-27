# Lab 2: Cross-Model Relations & Offers

## Overview
In this lab, you will create two separate models (`lab-cmr-provider` and `lab-cmr-consumer`), offer an application endpoint from the provider model, and consume and integrate it in the consumer model.

## Objectives
1. Create models `lab-cmr-provider` and `lab-cmr-consumer`.
2. In `lab-cmr-provider`, deploy `haproxy` as `provider-app` and create an offer named `proxy-offer` for endpoint `reverseproxy`.
3. In `lab-cmr-consumer`, deploy `haproxy` as `consumer-app`, consume the offer `lab-cmr-provider.proxy-offer`, and integrate `consumer-app:website` with `proxy-offer`.
