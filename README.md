Sample repo including 2 services...

- A **front-end** server that calls an API for some message
- An **API** that interacts with database and spawns a periodic background task to update records

... that are containerized for local development and shippable to GCP, including...

- script to build images & push to GCR
- terraform templates for setting up services

## Local setup

Run `./up` to start all services & migrate the database.

Visit `http://localhost:8001` and refresh after 5 seconds to see all pieces at work.

## Deploy

### Database

This doesn't set up the database; setting up "stateful" things alongside stateless services seems
like a bad idea, so it relies on a Cloud SQL instance already being set up in the same project and default VPC,
or some other publicly-accessible database.

### Build and ship images

First, the docker images need to be built and deployed to Google Container Registry.

For that, we'll need 2 things:

- A "credentials" file (the service account JSON that has permissions for things)
- The GCP "project id"

After that, just run via...

```
GCR_KEY_FILE="kevin-credentials.json" GCR_PROJECT_ID="kevlarr-terraform-test" ./gcr
```

### Set up services

Now that images are pushed to GCR, it's a 'simple' matter of creating the GCP services via terraform.

Populate a `terraform/terraform.tfvars` file with the following variables:

```yaml
project          = "<project-id>"
credentials_file = "<path-to-JSON-file>"
database_username = "<generic username>"
database_password = "<some random password>"
docker_tag = "<tag for the images shipped to GCR>"
```

With those variables supplied, now just run:

```
cd terraform
terraform apply
```

Ignoring the connective tissue, this creates:

- A VPC
- Cloud SQL database
- Cloud Run API that contacts the database
- Cloud Run front-end server that contacts the API
- Cloud Scheduler task to ping API every minute (to keep it un-idled as much as possible)
