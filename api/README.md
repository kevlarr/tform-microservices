To build & run manually:

```
$ docker build . -t fs-tf-api:latest

$ docker run --rm \
    --publish 8000:8000 \
    -e SQLALCHEMY_URL=postgresql://user:password@localhost:5555/mydb \
    --network host \
    fs-tf-api:latest
```
