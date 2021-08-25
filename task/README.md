To build & run manually:

```
$ docker build . -t fs-tf-task:latest

$ docker run --rm \
    -e SQLALCHEMY_URL=postgresql://user:password@localhost:5555/mydb \
    --network host \
    fs-tf-task:latest
```
