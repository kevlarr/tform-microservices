To build & run manually:

```
$ docker build . -t fs-tf-web:latest

$ docker run --rm \
    --publish 8001:8001 \
    -e API_URL=http://localhost:8000 \
    --network host \
    fs-tf-web:latest
```
