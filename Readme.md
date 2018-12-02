# Run Mautic on Kubernetes

The goal of this project is to be able to run Mautic on Kubernetes in a way that is easy to configure and manage.

## Step 0: Set up Kubernetes

The obvious requisite step here is to set up Kubernetes. This can vary depending on your infrastructure. I have tested this both locally (using Docker for Mac), along with GKE (Googke Kubernetes Engine) and evertyhing works well.

If you are having platform specific issues, feel free to create an issue and I'll try to troubleshoot.

## Step 1: Get Volumes

## Step 2: Set up MySQL

Decrypt secrets

    mkdir secrets
    gpg -d encrypted_secrets/apache.crt > secrets/apache.crt
    gpg -d encrypted_secrets/apache.key > secrets/apache.key

Build and deploy docker image

    docker build . -t us.gcr.io/gigalixir-152404/mautic
    gcloud docker -- push us.gcr.io/gigalixir-152404/mautic

Create namespace

    kubectl create -f namespace.yaml

First, you want to create a [secret](https://kubernetes.io/docs/concepts/configuration/secret/) for the MySQL password:

    gpg -d mysql-literal-password.asc
    kubectl --namespace=mautic create secret generic mysql --from-literal=password=$(cat mysql-literal-password)

Then you'll want to use the `mysql.yaml` file to deploy the manifest:

    # TODO: persistent storage?! use Cloud SQL instead
    kubectl apply -f mysql.yaml

After that, use the `mysql-service.yaml` file to expose the service:

    kubectl apply -f mysql-service.yaml

## Step 3: Set up Mautic

First use the `mautic.yaml` file to deploy the manifest:

    kubectl apply -f mautic.yml

Then, expose the service:

    kubectl apply -f mautic-service.yml

Then, create an ingress:

    kubectl apply -f mautic-ing.yml

## Step 4: View your site!

After waiting a few minutes to create the containers, visit https://mautic.gigalixir.com/

Enable the API in the web interfacte. Then clear your cache, see https://github.com/mautic/api-library/issues/156

    rm -rf /var/www/html/app/cache

To use SendGrid's unsubscribe groups, set an smtp custom header for X-SMTPAPI as

    {"sub": { "%Unsubscribe%": ["<%asm_group_unsubscribe_url%>"], "%rawUnsubscribe%": ["<%asm_group_unsubscribe_raw_url%>"] }, "asm_group_id": 2987}

In the email, add something like this

    <a href="%rawUnsubscribe%">Unsubscribe</a>

See email queue

    local> kubectl --namespace=mautic exec -it mautic-3060776642-k14r8 /bin/bash
    root@container> su www-data -s /bin/bash
    www-data@container> ls /var/www/html/app/spool/default
    # force email send with: www-data@container> php /var/www/html/app/console mautic:emails:send

How campaigns work for me: 

1. Customers go through a linear progression of stages. No app yet -> No deploy yet -> Not upgraded yet
1. Each stage is defined by a segment
1. Each stage has a campaign that does the following
   1. Waits N days
   1. Double-checks that they are still in the right stage
   1. Sends an email
   1. Repeat M times
1. When someone progresses a stage, we update the contact field and mautic automatically moves them from one segment to another and moves them from one campaign to another. The old campaign is abandoned and the new campaign starts from the root.

Link tracking doesn't seem to work so we disabled it. Read tracking works fine though. Looks like our problem is here: https://github.com/mautic/mautic/pull/6441
Indeed, we are running 2.14.0. Perhaps we should upgrade to 2.14.1.

Also, do not set the general site url to https, leave it as http. You get infinite redirects otherwise. You won't notice the problem until you clear your cache though so it's hard to track down.

Strangely, sometimes cron jobs don't run. I just go into /etc/cron.d/mautic and add or remove a line at the end and save. Maybe the timestamp or the whitespace matters?
