# dmerkuriev_microservices
dmerkuriev microservices repository

# HomeWork 12 (Docker-2)
---

**В рамках задания было сделано:**
---
1. Настроили интеграцию репозитория с Travis CI. 
2. Установили docker, docker-machine, docker-compose.
3. Запустили первый контейнер hello-world.
4. Отработали различные команды по работе с docker.
5. Создали образ из запущенного контейнера.
6. Посмотрели параметры контейнера и образа. На их основе определили различия между контейнером и образом.
7. Все контейнеры остановили, удалили все остановленные контейнеры, удалили все образы.
8. Создали новый проект в GCP.
9. Сконфигурировали gcloud для нового проекта.
10. Создали docker-host через gcloud.
11. Повторили практику из лекции, пощупали изоляцию неймспейсов (PID, network).
12. Запустили докер-в-докере.
13. Создали Dockerfile с установкой mongodb, ruby и т.д. для приложения reddit.
14. Собрали образ, запустили его на docker-host, опубликовали в docker hub, запустили локально.
15. Посмотрели логи, проверили, что kill pid 1 уничтожает контейнер.
16. Запустили, удалили, создали, проверили процессы.
17. Вывели инфу о контейнере.
18. Посоздавали папки и файлы, удалили контейнер, создали, проверили, что папки отсутствуют.

**Задание с** *
---
Объяснение чем отличается контейнер от образа записано в файл docker-1.log.

**Задание с** **
---
Место под задание с двумя *

# HomeWork 13 (Docker-3)
---

**В рамках задания было сделано:**
---
1. Установил linter для docker.
		
		$ brew install hadolint
		
2. Развернул docker-host на gcloud.

		$ export GOOGLE_PROJECT=docker-263919
		$ docker-machine create --driver google  \
		--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts  \
		--google-machine-type n1-standard-1  \
		--google-zone europe-west1-b  \
		docker-host
		
3. Проверил что docker-host создан и переключил окружение на него.
		
		$ $ docker-machine ls
		NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER     ERRORS
		docker-host   -        google   Running   tcp://34.77.211.45:2376           v19.03.5
		$ eval $(docker-machine env docker-host)

4. Скачал и распаковал архив с приложением. Переименовал каталог **redditmicroservices** в **src**.
5. **src** - основной каталог текущего задания.  

	Теперь наше приложение состоит из трех компонентов:  
	**post-py** - сервис отвечающий за написание постов  
	**comment** - сервис отвечающий за написание комментариев  
	**ui** - веб-интерфейс, работающий с другими сервисами
	
6. Создал **Dockerfile** для каждого из трех компонентов.
7. Проверил с помощью **hadolint** **Dockerfile** и внес изменения в соотвествии с рекомендациями.

		$ hadolint post-py/Dockerfile
		post-py/Dockerfile:4 DL3020 Use COPY instead of ADD for files and folders
		
		$ hadolint comment/Dockerfile
		comment/Dockerfile:2 DL3008 Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`
		comment/Dockerfile:2 DL3009 Delete the apt-get lists after installing something
		comment/Dockerfile:2 DL3015 Avoid additional packages by specifying `--no-install-recommends`
		comment/Dockerfile:8 DL3020 Use COPY instead of ADD for files and folders
		comment/Dockerfile:10 DL3020 Use COPY instead of ADD for files and folders
		
		$ hadolint ui/Dockerfile
		ui/Dockerfile:2 DL3008 Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`
		ui/Dockerfile:2 DL3009 Delete the apt-get lists after installing something
		ui/Dockerfile:2 DL3015 Avoid additional packages by specifying `--no-install-recommends`
		ui/Dockerfile:8 DL3020 Use COPY instead of ADD for files and folders
		ui/Dockerfile:10 DL3020 Use COPY instead of ADD for files and folders
		
8. Скачал последний образ MongoDB:

		$ docker pull mongo:latest

9. Собрал образы. При этом сборка **ui** началась не с первого шага, так как часть шагов была взята из кеша, который был создан при сборке **comment**.

		$ docker build -t dmerkuriev/post:1.0 ./post-py 
		$ docker build -t dmerkuriev/comment:1.0 ./comment
		$ docker build -t dmerkuriev/ui:1.0 ./ui

10. Создал сеть для приложения.

		$ docker network create reddit

 Запустил приложение:

		$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
		$ docker run -d --network=reddit --network-alias=post dmerkuriev/post:1.0
		$ docker run -d --network=reddit --network-alias=comment dmerkuriev/comment:1.0
		$ docker run -d --network=reddit -p 9292:9292 dmerkuriev/ui:1.0

	Что было сделано?  
Создана bridge-сеть для контейнеров, так как сетевые алиасы не
работают в сети по умолчанию.  
Запустили наши контейнеры в этой сети.  
Добавили сетевые алиасы контейнерам.  
(Сетевые алиасы могут быть использованы для сетевых
соединений, как доменные имена).

11. Для проверки открываем в браузере http://34.77.211.45:9292 и пишем пост.
12. Посмотрим размеры образов. Слишком большие образы, для такого маленького приложения.

		$ docker images
		REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
		dmerkuriev/ui        1.0                 6b960a468ba3        27 minutes ago      784MB
		dmerkuriev/comment   1.0                 1b6eb232d384        28 minutes ago      781MB
		dmerkuriev/post      1.0                 6b239567455c        34 minutes ago      109MB
		mongo                latest              a0e2e64ac939        2 weeks ago         364MB
		ruby                 2.2                 6c8e6f9667b2        20 months ago       715MB
		python               3.6.0-alpine        cb178ebbf0f2        2 years ago         88.6MB

13. Уменьшим размер образа **ui** переписав Dockerfile.

		$ cat ui/Dockerfile
		FROM ubuntu:16.04
		ENV APP_HOME /app
		ENV POST_SERVICE_HOST post
		ENV POST_SERVICE_PORT 5000
		ENV COMMENT_SERVICE_HOST comment
		ENV COMMENT_SERVICE_PORT 9292
		
		RUN apt-get update \
    		&& apt-get install -y ruby-full ruby-dev build-essential \
    		&& gem install bundler --no-ri --no-rdoc
		RUN mkdir $APP_HOME
		
		WORKDIR $APP_HOME
		COPY Gemfile* $APP_HOME/
		RUN bundle install
		COPY . $APP_HOME
		
		CMD ["puma"]

14. Пересоберем ui и проверим сколько теперь размер образа.

		$ docker build -t dmerkuriev/ui:2.0 ./ui
		$ docker images
		REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
		dmerkuriev/ui        2.0                 e2d7df785d7c        8 seconds ago       458MB
		dmerkuriev/ui        1.0                 6b960a468ba3        53 minutes ago      784MB
		dmerkuriev/comment   1.0                 1b6eb232d384        54 minutes ago      781MB
		dmerkuriev/post      1.0                 6b239567455c        About an hour ago   109MB
		mongo                latest              a0e2e64ac939        2 weeks ago         364MB
		ubuntu               16.04               c6a43cd4801e        2 weeks ago         123MB
		ruby                 2.2                 6c8e6f9667b2        20 months ago       715MB
		python               3.6.0-alpine        cb178ebbf0f2        2 years ago         88.6MB

15. Выключим старые копии контенеров и запустим новые. Откроем в браузере приложение - пост пропал. Так как контейнер с монгой пересоздался.

		$ docker kill $(docker ps -q)
		$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
		$ docker run -d --network=reddit --network-alias=post dmerkuriev/post:1.0
		$ docker run -d --network=reddit --network-alias=comment dmerkuriev/comment:1.0
		$ docker run -d --network=reddit -p 9292:9292 dmerkuriev/ui:2.0

16. Создал Docker volume и подключил его к контейнеру с MongoDB, запустив новые копии контейнеров. Предварительно удалив старые контейнеры. 

		$ docker volume create reddit_db
		$ docker kill $(docker ps -q)
		$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
		$ docker run -d --network=reddit --network-alias=post dmerkuriev/post:1.0
		$ docker run -d --network=reddit --network-alias=comment dmerkuriev/comment:1.0
		$ docker run -d --network=reddit -p 9292:9292 dmerkuriev/ui:2.0

17. Заходим на сайт http://34.77.211.45:9292 и пишем пост.
18. Перезапускаем контейнеры, заходим на сайт и проверяем, что пост остался на месте.

**Задание с** *
---
Остановите контейнеры: docker kill $(docker ps -q)  
Запустите контейнеры с другими сетевыми алиасами.  
Адреса для взаимодействия контейнеров задаются через ENV-переменные внутри Dockerfile'ов.  
При запуске контейнеров (docker run) задайте им переменные окружения соответствующие новым сетевым алиасам, не пересоздавая образ.  
Проверьте работоспособность сервиса.

Передадим адреса взаимодейтвия контейнеров через переменные, передаваемые через командную строку с помощью ключа **-е**. Тогда решение будет выглядеть следующим образом:
		
	$ docker run -d --network=reddit --network-alias=post_db1 --network-alias=comment_db1 -v reddit_db:/data/db mongo:latest
	$ docker run -d -e POST_DATABASE_HOST=post_db1 --network=reddit --network-alias=post1 dmerkuriev/post:1.0
	$ docker run -d -e COMMENT_DATABASE_HOST=comment_db1 --network=reddit --network-alias=comment1 dmerkuriev/comment:1.0
	$ docker run -d -e POST_SERVICE_HOST=post1 -e COMMENT_SERVICE_HOST=comment1 --network=reddit -p 9292:9292 dmerkuriev/ui:2.0

Открываем в браузере http://34.77.211.45:9292 и видим ранее созданный пост.

**Задание с** *
---
Попробуйте собрать образ на основе Alpine Linux.
Придумайте еще способы уменьшить размер образа.  
Можете реализовать как только для UI сервиса, так и для остальных (post, comment)  
Все оптимизации проводите в Dockerfile сервиса.  
Дополнительные варианты решения уменьшения размера образов можете оформить в виде файла Dockerfile.<цифра> в папке сервиса.

Для начала посмотрим текущий размер образов.

	$ docker images
	REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
	dmerkuriev/ui        2.0                 e2d7df785d7c        9 hours ago         458MB
	dmerkuriev/ui        1.0                 6b960a468ba3        10 hours ago        784MB
	dmerkuriev/comment   1.0                 1b6eb232d384        10 hours ago        781MB
	dmerkuriev/post      1.0                 6b239567455c        10 hours ago        109MB
	
Перепишем Dockerfile для сборки образа **ui** на основе Alpine.
	
	$ cat ui/Dockerfile
	FROM ruby:2.2-alpine
	
	ENV POST_SERVICE_HOST post
	ENV POST_SERVICE_PORT 5000
	ENV COMMENT_SERVICE_HOST comment
	ENV COMMENT_SERVICE_PORT 9292
	ENV APP_HOME /app
	
	RUN mkdir $APP_HOME
	WORKDIR $APP_HOME
	ADD Gemfile* $APP_HOME/
	
	RUN apk add --no-cache --virtual .build-deps build-base \
    	&& bundle install \
    	&& bundle clean \
    	&& apk del .build-deps
	
	ADD . $APP_HOME
	
	CMD ["puma"]
	
Перепишем Dockerfile для сборки образа **comment** на основе Alpine.

	$ cat comment/Dockerfile
	FROM ruby:2.2-alpine
	
	ENV COMMENT_DATABASE_HOST comment_db
	ENV COMMENT_DATABASE comments
	ENV APP_HOME /app
	
	RUN mkdir $APP_HOME
	WORKDIR $APP_HOME
	ADD Gemfile* $APP_HOME/
	
	RUN apk add --no-cache --virtual .build-deps build-base \
    	&& bundle install \
    	&& bundle clean \
    	&& apk del .build-deps
	
	ADD . $APP_HOME
	
	CMD ["puma"]
	
Собираем образы и смотрим результат:

	$ docker build -t dmerkuriev/ui:3.0 ./ui
	$ docker build -t dmerkuriev/comment:2.0 ./comment
	$ docker images
	REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
	dmerkuriev/comment   2.0                 7dccd39e3dcd        5 minutes ago       156MB
	dmerkuriev/ui        3.0                 942892698d00        12 minutes ago      159MB
	dmerkuriev/ui        2.0                 e2d7df785d7c        9 hours ago         458MB
	dmerkuriev/ui        1.0                 6b960a468ba3        10 hours ago        784MB
	dmerkuriev/comment   1.0                 1b6eb232d384        10 hours ago        781MB
	dmerkuriev/post      1.0                 6b239567455c        10 hours ago        109MB
	
Запускаем контейнеры и проверяем работу приложения перейдя по адресу http://34.77.211.45:9292

	$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
	$ docker run -d --network=reddit --network-alias=post dmerkuriev/post:1.0
	$ docker run -d --network=reddit --network-alias=comment dmerkuriev/comment:2.0
	$ docker run -d --network=reddit -p 9292:9292 dmerkuriev/ui:3.0
	
Убедившись, что все работает как надо, убиваем контейнеры и даляем **docker-host** на gcloud и выходим из окружения.

	$ docker kill $(docker ps -q)
	$ docker-machine rm docker-host
	$ eval $(docker-machine env --unset)

