# BOSH Release for elpaaso-sandbox

This is a Bosh Release, to help deploy the elpaaso sandbox components
* a UI component
* a Service Component

This release must be deployed with the route registrar release, to expose the 2 jars servers as cloudfoundry routes. 


## Prerequisites

* a dedicated org to hold sandbox spaces
* a default space in this org
* a sandbox admin user, with org admin right
* a UAA Oauth2 client id / and secret, configured in cloudfoundry
see the following cloudfoundry manifest snippet

``` yaml
---

...
uaa:
...
    clients:
...
      o-elpaaso-sandbox:
        secret: UAA-ELPAASO-SANDBOX-SECRET-ristiakDargonkorIa
        redirect-uri: http://elpaaso-sandbox-ui.cfy-api.preprod.paascfy.s0.p.fti.net
        scope: openid,cloud_controller.read
...
```


## Usage

To use this bosh release, first upload it to your bosh:

```
bosh target BOSH_HOST
git clone https://github.com/cloudfoundry-community/elpaaso-sandbox-boshrelease.git
cd elpaaso-sandbox-boshrelease
bosh upload release releases/elpaaso-sandbox-1.yml
```

Prepare a manifest

``` yaml
---

...

releases:
  - {name: elpaaso-sandbox, version: latest}
  - {name: route-registrar, version: latest}

..

jobs:

  - name: elpaaso-sandbox-service
    templates:
      - {release: elpaaso-sandbox, name: elpaaso-sandbox-service}
      - {name: route-registrar, release: route-registrar}

    instances: 1
...
    properties:
      elpaaso_sandbox_service:
        security_require_ssl: false
        elpaaso_sandbox_service.security_enable_csrf: true
        cloudfoundry_trust_self_signed_certs: true
        cloudfoundry_api_url: https://api.cloudfoundry.net
        cloudfoundry_credentials_user_id: <sandbox-user>
        cloudfoundry_credentials_password: <sandbox password>
        cloudfoundry_org: <sandbox org>
        cloudfoundry_space: <sandbox default-space>
        oauth2_resource_jwt_key: -----BEGIN PUBLIC KEY----- xxxx -----END PUBLIC KEY-----  #<-- must match UAA Oauth2 client
        security_oauth2_admin_scope: cloudcontroller.admin

      # this is a route to expose sandbox service via cf routers
      route_registrar:
        external_host: elpaaso-sandbox-service.cloudfoundry.net
        external_ip: 10.0.0.10 #<-- static ip of the job
        port: 8081  #<-- default for service
        message_bus_servers:
        - host:  <nats ip>:4222  # cf nats ip
          user: nats
          password: yyyyyy  #nats password
        health_checker:
          interval: 10
          name: healthchk


  - name: elpaaso-sandbox-ui
    templates:
      - {release: elpaaso-sandbox, name: elpaaso-sandbox-ui}
      - {name: route-registrar, release: route-registrar}
      - {release: logsearch-shipper, name: logsearch-shipper}


    properties:

      # ui properties
      elpaaso_sandbox_ui:
        admin_password: zzz
        enable_ssl_certificate_check: false
        sandbox_service_url: http://elpaaso-sandbox-service.cloudfoundry.net
        login_url: https://login.cloudfoundry.net
        oauth2_client_client_id: o-elpaaso-sandbox                                      #<-- must match UAA Oauth2 client 
        oauth2_client_client_secret: UAA-ELPAASO-SANDBOX-SECRET                         #<-- must match UAA Oauth2 client
        oauth2_resource_jwt_key: -----BEGIN PUBLIC KEY----- xxx -----END PUBLIC KEY---- #<-- must match UAA Oauth2 client



       # this is a route to expose sandbox ui via cf routers
      route_registrar:
        external_host: elpaaso-sandbox-ui.cloudfoundry.net
        external_ip: 10.0.0.11  #<-- static ip of the job
        port: 8080  # <-- spring boot default for ui
        message_bus_servers:
        - host:  <nats ip>:4222  # cf nats ip
          user: nats
          password: yyyyyy  #nats password
        health_checker:
          interval: 10
          name: healthchk

```



### Override security groups

For AWS & Openstack, the default deployment assumes there is a `default` security group. If you wish to use a different security group(s) then you can pass in additional configuration when running `make_manifest` above.

Create a file `my-networking.yml`:

``` yaml
---
networks:
  - name: elpaaso-sandbox1
    type: dynamic
    cloud_properties:
      security_groups:
        - elpaaso-sandbox
```

Where `- elpaaso-sandbox` means you wish to use an existing security group called `elpaaso-sandbox`.

You now suffix this file path to the `make_manifest` command:

```
templates/make_manifest openstack-nova my-networking.yml
bosh -n deploy
```

### Development

As a developer of this release, create new releases and upload them:

```
bosh create release --force && bosh -n upload release
```

### Final releases

To share final releases:

```
bosh create release --final
```

By default the version number will be bumped to the next major number. You can specify alternate versions:


```
bosh create release --final --version 2.1
```

After the first release you need to contact [Dmitriy Kalinin](mailto://dkalinin@pivotal.io) to request your project is added to https://bosh.io/releases (as mentioned in README above).
