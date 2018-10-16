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

    {"asm_group_id": 2987}
