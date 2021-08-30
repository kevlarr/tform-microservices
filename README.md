Sample repo including 3 services...

- A **front-end** server
- An API
- A scheduled background task

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
database_url     = "postgresql://<user>:<password>@<host>:<port>/<dbname>"
```

**Note:** If connecting to a Cloud SQL instance, you *must* make sure to be using the **private IP and default VPC**;
even using a public IP address, Cloud Run containers can't seem to access it.
They rely on having "VPC connectors" that provide access to the default VPC (and, thus, the private IP address).

With those variables supplied, now just run:

```
cd terraform
terraform apply
```
