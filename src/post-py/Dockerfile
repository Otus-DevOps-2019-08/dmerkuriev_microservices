FROM python:3.6.0-alpine

WORKDIR /app
COPY . /app

# установим gcc, которого нет в alpine и без которого вылетает ошибка "unable to execute 'gcc': No such file or directory"
# Почистим за собой, для экономии места.
RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
    && pip install -r /app/requirements.txt \
    && apk del .build-deps gcc musl-dev

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]

