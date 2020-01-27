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
	
	$ cat ui/Dockerfile.3
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

	$ cat comment/Dockerfile.2
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

# HomeWork 14 (Docker-4)
---

**В рамках задания было сделано:**
---		
1. Для выполнения ДЗ развернул docker-host на gcloud.

		$ export GOOGLE_PROJECT=docker-263919
		$ docker-machine create --driver google  \
		--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts  \
		--google-machine-type n1-standard-1  \
		--google-zone europe-west1-b  \
		docker-host
		
2. Проверил что docker-host создан и переключил окружение на него.

		$ docker-machine ls
		NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER     ERRORS
		docker-host   -        google   Running   tcp://35.241.248.120:2376           v19.03.5
		$ eval $(docker-machine env docker-host)

3. Запустим контейнер с использованием none-драйвера сети. В качестве образа используем joffotron/docker-net-tools.

		$ docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig

		lo        Link encap:Local Loopback
          		inet addr:127.0.0.1  Mask:255.0.0.0
          		...
          		
   В результате, видим:  
• что внутри контейнера из сетевых интерфейсов существует только loopback.  
• сетевой стек самого контейнера работает (ping localhost), но без возможности контактировать с внешним миром.  
• Значит, можно даже запускать сетевые сервисы внутри такого контейнера, но лишь для локальных экспериментов (тестирование, контейнеры для выполнения разовых задач и т.д.).

4. Запустим контейнер в сетевом пространстве docker-хоста.

		$  docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig
		docker0   Link encap:Ethernet  HWaddr 02:42:32:43:F4:E5
          		inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          		...

		ens4      Link encap:Ethernet  HWaddr 42:01:0A:84:00:05
          		inet addr:10.132.0.5  Bcast:10.132.0.5  Mask:255.255.255.255
          		inet6 addr: fe80::4001:aff:fe84:5%32542/64 Scope:Link
          		...

		lo        Link encap:Local Loopback
          		inet addr:127.0.0.1  Mask:255.0.0.0
          		inet6 addr: ::1%32542/128 Scope:Host
          		...
          	
   Сравним вывод с:
   
   		$ docker-machine ssh docker-host ifconfig
   		docker0   Link encap:Ethernet  HWaddr 02:42:32:43:F4:E5
          		inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0
          		...

		ens4      Link encap:Ethernet  HWaddr 42:01:0A:84:00:05
          		inet addr:10.132.0.5  Bcast:10.132.0.5  Mask:255.255.255.255
          		inet6 addr: fe80::4001:aff:fe84:5%32542/64 Scope:Link
          		...

		lo        Link encap:Local Loopback
          		inet addr:127.0.0.1  Mask:255.0.0.0
          		inet6 addr: ::1%32542/128 Scope:Host
          		...
     
     Вывод команд одинаковый, так как используется сеть docker-хоста.

5. Запустим несколько раз (4).  docker run --network host -d nginx

		$ docker ps -a
		CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      		PORTS               NAMES
		bb531f60d0f4        nginx               "nginx -g 'daemon of…"   22 seconds ago      Exited (1) 18 seconds ago                       pensive_goodall
		7d0036c34226        nginx               "nginx -g 'daemon of…"   24 seconds ago      Exited (1) 20 seconds ago                       awesome_poitras
		4f6ada17cbcc        nginx               "nginx -g 'daemon of…"   28 seconds ago      Exited (1) 24 seconds ago                       blissful_hodgkin
		4c838b35e080        nginx               "nginx -g 'daemon of…"   33 seconds ago      Up 30 seconds                                   eager_pasteur

  У трех первых контейнеров статус **Exited**. Четвертый экземпляр работает. Каждый следующий запуск контейнера, убивает прошлый. Происходит это из-за того, что мы запускаем несколько контейнеров на одном интерфейсе по умолчанию слушающий один и тот же порт.

6. Остановим контейнеры.

		$ docker kill $(docker ps -q)

7. Подключился к docker-host.

		$ docker-machine ssh docker-host
	
	На docker-host создал символьную ссылку на 
		
		docker-user@docker-host:~$ sudo ln -s /var/run/docker/netns /var/run/netns

	Теперь можно просматривать существующие в данный момент net-namespaces с помощью команды: 

		docker-user@docker-host:~$ sudo ip netns
		default
	
	Запустим 2 контейнера с использованием none-драйвера сети.
	
		$ docker run --network none -d nginx
		6616a58905f73fc5d007307ec7d440271893d6fddd8ec578880ce5d279fbeb38
		$ docker run --network none -d nginx
		8c88faeacce695944aea9370ab150df537aa7ea9d51072c0f41b36e3890f5c41

		$ docker ps -a
		CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                           		PORTS               NAMES
		8c88faeacce6        nginx               "nginx -g 'daemon of…"   5 seconds ago       Up 4 seconds                                         peaceful_pike
		6616a58905f7        nginx               "nginx -g 'daemon of…"   2 minutes ago       Up 2 minutes                                         goofy_lovelace

	Посмотрим на docker-host какие net-namespaces на сейчас. Видим что добавились 2 новых.
		
		docker-user@docker-host:~$ sudo ip netns
		e16500db935e
		4b5b6d390e44
		default

	Запустим 2 контейнера с использованием host-драйвера сети.

		$ docker run --network host -d nginx
		f1c00a81a9f001a7b1c345aa2fab571681f7fb4dbab45297a87e8408c86ec556
		$ docker run --network host -d nginx
		1b09fb23a077a2b17dd62318b8b695afc27ee192bcf4a6b6a7e32954bfbf2c76

		$ docker ps -a
		CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                           		PORTS               NAMES
		1b09fb23a077        nginx               "nginx -g 'daemon of…"   23 seconds ago      Exited (1) 19 seconds ago                            nice_gauss
		f1c00a81a9f0        nginx               "nginx -g 'daemon of…"   5 minutes ago       Up 5 minutes                                         awesome_chandrasekhar
		8c88faeacce6        nginx               "nginx -g 'daemon of…"   14 minutes ago      Up 14 minutes                                        peaceful_pike
		6616a58905f7        nginx               "nginx -g 'daemon of…"   16 minutes ago      Up 16 minutes                                        goofy_lovelace

	Посмотрим на docker-host какие net-namespaces на сейчас. Видим что новые net-namespace не добавились, так как используется default namespace.
	
		$ sudo ip netns
		e16500db935e
		4b5b6d390e44
		default

8. Создадим bridge-сеть в docker (флаг --driver указывать не обязательно, т.к. по-умолчанию используется bridge.

		$  docker network create reddit --driver bridge

9. Запустим наш проект reddit с использованием bridge-сети.

		$ docker run -d --network=reddit mongo:latest
		$ docker run -d --network=reddit dmerkuriev/post:1.0
		$ docker run -d --network=reddit dmerkuriev/comment:1.0
		$ docker run -d --network=reddit -p 9292:9292 dmerkuriev/ui:1.0
		
	Открываем в браузере страницу http://35.241.248.120:9292/ и видим сообщение об ошибке:   
	**Can't show blog posts, some problems with the post service. Refresh?**  
	Наши сервисы ссылаются друг на друга по dnsименам, прописанным в ENV-переменных (см Dockerfile).
	В текущей инсталляции встроенный DNS docker не знает ничего об этих именах.  
	Решением проблемы будет присвоение контейнерам имен или сетевых алиасов при старте:  
			
		--name <name> (можно задать только 1 имя)  
		--network-alias <alias-name> (можно задать множество алиасов)

10. Остановим контейнеры и создадим их заново присвоим им --network-alias'ы.

		$ docker kill $(docker ps -q)
		$ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
		$ docker run -d --network=reddit --network-alias=post dmerkuriev/post:1.0
		$ docker run -d --network=reddit --network-alias=comment dmerkuriev/comment:1.0
		$ docker run -d --network=reddit -p 9292:9292 dmerkuriev/ui:1.0
	
	Открываем в браузере страницу http://35.241.248.120:9292/ и видим, что все в порядке.

11. Запустим проект в 2-х bridge сетях. Так, что бы сервис ui не имел доступа к базе данных.

		$ docker kill $(docker ps -q)
		
	создадим 2 докер сети
		
		$ docker network create back_net --subnet=10.0.2.0/24
		$ docker network create front_net --subnet=10.0.1.0/24
	
	запустим контейнеры
	
		$ docker run -d --network=front_net -p 9292:9292 --name ui dmerkuriev/ui:1.0
		$ docker run -d --network=back_net --name comment dmerkuriev/comment:1.0
		$ docker run -d --network=back_net --name post dmerkuriev/post:1.0
		$ docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest

	Открываем в браузере страницу http://35.241.248.120:9292/ и видим сообщение об ошибке:   
	**Can't show blog posts, some problems with the post service. Refresh?**
	
	Docker при инициализации контейнера может подключить к нему только 1 сеть.  
	При этом контейнеры из соседних сетей не будут доступны как в DNS, так и для взаимодействия по сети.  
	Поэтому нужно поместить контейнеры post и comment в обе сети.  
	Дополнительные сети подключаются командой:

		docker network connect <network> <container>

	Подключим контейнеры ко второй сети:
	
		$ docker network connect front_net post
		$ docker network connect front_net comment

	Открываем в браузере страницу http://35.241.248.120:9292/ и видим, что все в порядке.

12. Посмотрим как выглядит сетевой стек Linux в текущий момент.

	Зайдем по ssh на docker-host и установите пакет bridge-utils

		$ docker-machine ssh docker-host
		docker-user@docker-host:~$ sudo apt-get update && sudo apt-get install bridge-utils
		
	Посмотрим список сетей
	
		docker-user@docker-host:~$ sudo docker network ls
		NETWORK ID          NAME                DRIVER              SCOPE
		60b06bb84f1d        back_net            bridge              local
		2bc9eb385fa1        bridge              bridge              local
		f276ef7e103b        front_net           bridge              local
		5a264c3c56e8        host                host                local
		54e4f4d57d11        none                null                local
		78362379bdf5        reddit              bridge              local

	Посмотрим список бриджей
	
		docker-user@docker-host:~$ sudo  ifconfig | grep br
		br-60b06bb84f1d Link encap:Ethernet  HWaddr 02:42:d7:79:82:ff
		br-78362379bdf5 Link encap:Ethernet  HWaddr 02:42:92:db:5e:48
		br-f276ef7e103b Link encap:Ethernet  HWaddr 02:42:2f:70:aa:2f
		
	Для просмотра информации о bridge-интерфейсах воспользуемся следующими командами:
	
		docker-user@docker-host:~$ ifconfig br-60b06bb84f1d
		br-60b06bb84f1d Link encap:Ethernet  HWaddr 02:42:d7:79:82:ff
          inet addr:10.0.2.1  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::42:d7ff:fe79:82ff/64 Scope:Link
          ...
          
 		docker-user@docker-host:~$ sudo docker inspect 60b06bb84f1d
		[
    		{
        		"Name": "back_net",
        		"Id": "60b06bb84f1dc473200d90374c2255f76477dca2f8bc7c82fe137c79bd846daa",
        		"Created": "2020-01-07T18:52:09.42482209Z",
        		"Scope": "local",
        		"Driver": "bridge",
        		"EnableIPv6": false,
        		"IPAM": {
            		"Driver": "default",
            		"Options": {},
            		"Config": [
                		{
                    		"Subnet": "10.0.2.0/24"
                    		...

		docker-user@docker-host:~$ sudo brctl show br-60b06bb84f1d
		bridge name			bridge id			STP enabled interfaces
		br-60b06bb84f1d		8000.0242d77982ff		no		veth0ae29fc
															veth5807d86
															veth6cf11ae
															
	Посмотрим iptables:
	
		docker-user@docker-host:~$ sudo iptables -nL -t nat
		Chain PREROUTING (policy ACCEPT)
		target     prot opt source               destination
		DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
		
		Chain INPUT (policy ACCEPT)
		target     prot opt source               destination
		
		Chain OUTPUT (policy ACCEPT)
		target     prot opt source               destination
		DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
		
		# Обратите внимание на цепочку POSTROUTING. Отмеченные звездочкой правила отвечают за выпуск во внешнюю сеть контейнеров из bridge-сетей
		Chain POSTROUTING (policy ACCEPT)
		target     prot opt source               destination
		*MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0
		*MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0
		*MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
		MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0
		MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292
		
		Chain DOCKER (2 references)
		target     prot opt source               destination
		RETURN     all  --  0.0.0.0/0            0.0.0.0/0
		RETURN     all  --  0.0.0.0/0            0.0.0.0/0
		RETURN     all  --  0.0.0.0/0            0.0.0.0/0
		RETURN     all  --  0.0.0.0/0            0.0.0.0/0
		# Правило DNAT в цепочке Docker отвечают за перенаправление трафика на адреса уже конкретных контейнеров.
		DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292	
	В спиcке процессов мы можем найти процесс docker-proxy который слушает 9292 порт
	
		docker-user@docker-host:~$ sudo  ps ax | grep docker-proxy
		3772 pts/0    S+     0:00 grep --color=auto docker-proxy
 		5978 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
					
13. Docker-compose.

	Проблемы:  
	• Одно приложение состоит из множества контейнеров/сервисов  
	• Один контейнер зависит от другого  
	• Порядок запуска имеет значение  
	• docker build/run/create … (долго и много)
	
	docker-compose  
	• Отдельная утилита  
	• Декларативное описание docker-инфраструктуры в YAMLформате  
	• Управление многоконтейнерными приложениями

14. В директории src Напишем docker-compose.yml файл.

		version: '3.3'
		services:
  		  post_db:
    	    image: mongo:3.2
    	    volumes:
              - post_db:/data/db
    	    networks:
      	      - reddit
          ui:
            build: ./ui
            image: ${USERNAME}/ui:1.0
            ports:
              - 9292:9292/tcp
            networks:
              - reddit
          post:
            build: ./post-py
            image: ${USERNAME}/post:1.0
            networks:
              - reddit
          comment:
            build: ./comment
            image: ${USERNAME}/comment:1.0
            networks:
              - reddit

        volumes:
          post_db:

        networks:
          reddit:

	Удалим все прошлые контейнеры
		
		$ docker kill $(docker ps -q)
	
	Перед запуском необходимо экспортировать значения данных переменных окружения
	
		$ export USERNAME=dmerkuriev
	
	Выполним запуск контейнеров с помощью docker-compose.
	
		$ docker-compose up -d
		
	Проверим
	
		$ docker-compose ps
    	Name                  Command             State           Ports
		----------------------------------------------------------------------------
		src_comment_1   puma                          Up
		src_post_1      python3 post_app.py           Up
		src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
		src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp
		
	Открываем в браузере страницу http://35.241.248.120:9292/ и видим, что все в порядке.
	
**Задание 1**
---
1) Изменить docker-compose под кейс с множеством сетей, сетевых алиасов (стр 18).  
2) Параметризуйте с помощью переменных окружений:  
• порт публикации сервиса ui. 
• версии сервисов  
• возможно что-либо еще на ваше усмотрение  
3) Параметризованные параметры запишите в отдельный файл c расширением .env  
4) Без использования команд source и export docker-compose должен подхватить переменные из этого файла. Проверьте  
P.S. Файл .env должен быть в .gitignore, в репозитории закоммичен .env.example, из которого создается .env  
  
Переписал docker-compose.yml под кейс с несколькими сетями и параметризировал его с помощью переменных окружения, которые вынес в .env файл.

	$ cat docker-compose.yml
	version: '3.3'
	services:
  	  post_db:
    	image: mongo:${VERSION_MONGO}
    	volumes:
          - post_db:${DB_DATA}
    	networks:
      	  back_net:
        	 aliases:
             - post_db
      ui:
        build: ./ui
        image: ${USERNAME}/ui:${UI_VERSION}
        ports:
          - ${PORT_EXT}:${PORT_INT}/tcp
        networks:
          front_net:
            aliases:
              - ui
      post:
        build: ./post-py
        image: ${USERNAME}/post:${POST_VERSION}
        networks:
          back_net:
            aliases:
              - post
          front_net:
            aliases:
              - post
      comment:
        build: ./comment
        image: ${USERNAME}/comment:${COMMENT_VERSION}
        networks:
          back_net:
            aliases:
              - post
          front_net:
            aliases:
              - post

    volumes:
      post_db:

    networks:
      front_net:
      back_net:
	
В .env вынесенны следующие перменные:

	$ cat .env
	USERNAME=your_usernme
	VERSION_MONGO=3.2
	DB_DATA=/data/db
	UI_VERSION=1.0
	PORT_EXT=9292
	PORT_INT=9292
	POST_VERSION=1.0
	COMMENT_VERSION=1.0
	COMPOSE_PROJECT_NAME=docker_compose_app

Проверяем:
	
	$ docker kill $(docker ps -q)
	$ docker-compose up -d
	$ docker-compose ps
    Name                  Command             State           Ports
	----------------------------------------------------------------------------
	docker_compose_app_comment_1   puma                          Up
	docker_compose_app_post_1      python3 post_app.py           Up
	docker_compose_app_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
	docker_compose_app_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp

Открываем в браузере страницу http://35.241.248.120:9292/ и видим, что все в порядке.

**Задание 2**
---
Узнайте как образуется базовое имя проекта. Можно ли его задать? Если можно то как?  
Базовое имя проекта, берется из имени директории в которой запускается docker-compose. Его можно задать прописав в ENV файл переменную COMPOSE\_PROJECT_NAME=\<name> или передать через консоль при запуске docker-compose с ключом -p \<name>.

**Задание с** *
---
Создайте docker-compose.override.yml для reddit проекта, который позволит.  
• Изменять код каждого из приложений, не выполняя сборку образа  
• Запускать puma для руби приложений в дебаг режиме с двумя воркерами (флаги --debug и -w 2)

Docker Compose по умолчанию читает два файла: docker-compose.yml и docker-compose.override.yml. В файле docker-compose-override.yml можно хранить переопределения для существующих сервисов или определять новые. Чтобы использовать несколько файлов (или файл переопределения с другим именем), необходимо передать -f в docker-compose up (порядок имеет значение):  
$ docker-compose up -f my-override-1.yml my-overide-2.yml

Для того, что бы можно было изменять код приложений и не выполнять сборку образа будем использовать volume и прокинем в контейнер каталог с приложением. Для запуска puma в дебаг режиме с двумя воркерами воспользуемся entrypoint.

Напишем docker-compose.override.yml

	$ cat docker-compose.override.yml
	version: '3.3'
	services:
  	  ui:
        volumes:
          - ui:/app
        entrypoint:
          - puma
          - --debug
          - -w 2
      post:
        volumes:
          - post-py:/app
      comment:
        volumes:
          - comment:/app
        entrypoint:
          - puma
          - --debug
          - -w 2

	volumes:
      ui:
      post-py:
      comment:

Запустим docker-compose и проверим результат

	$ docker-compose up -d
	$ docker-compose ps
            Name                         Command             State           Ports
	-------------------------------------------------------------------------------------------
	docker_compose_app_comment_1   puma --debug -w 2             Up
	docker_compose_app_post_1      python3 post_app.py           Up
	docker_compose_app_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
	docker_compose_app_ui_1        puma --debug -w 2             Up      0.0.0.0:9292->9292/tcp

Подключимся к контейнеру и посмотрим

	$ docker ps -a
	CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS              PORTS                    NAMES
	32209e8cc409        dmerkuriev/post:1.0      "python3 post_app.py"    5 minutes ago       Up 5 minutes                                 docker_compose_app_post_1
	191dc7dd6a42        dmerkuriev/ui:1.0        "puma --debug '-w 2'"    5 minutes ago       Up 5 minutes        0.0.0.0:9292->9292/tcp   docker_compose_app_ui_1
	d3b1f96f1df7        dmerkuriev/comment:1.0   "puma --debug '-w 2'"    5 minutes ago       Up 5 minutes                                 docker_compose_app_comment_1
	161401e5f5cf        mongo:3.2                "docker-entrypoint.s…"   22 minutes ago      Up 5 minutes        27017/tcp                docker_compose_app_post_db_1
	$ docker exec -it 191dc7dd6a42 bash
	root@191dc7dd6a42:/app#
	root@191dc7dd6a42:/app# ps aux
	USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
	root         1  0.0  0.4  69272 16080 ?        Ssl  10:57   0:00 puma 3.12.0 (tcp://0.0.0.0:9292) [app]
	root         7  0.2  1.0 670716 40892 ?        Sl   10:57   0:00 puma: cluster worker 0: 1 [app]
	root         9  0.2  1.1 674976 42268 ?        Sl   10:57   0:00 puma: cluster worker 1: 1 [app]
	root       307  2.5  0.0  18240  3192 pts/0    Ss   11:03   0:00 bash
	root       324  0.0  0.0  34424  2868 pts/0    R+   11:03   0:00 ps aux

# HomeWork 15 (Gitlab-ci-1)
---

**В рамках задания было сделано:**
---
1. Развернул новую ВМ на gcloud под gitab-ci.

		$ export GOOGLE_PROJECT=docker-263919
		$ docker-machine create --driver google \
		--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
		--google-zone europe-west1-b \
		--google-machine-type n1-standard-1 \
		--google-disk-size 50 \
		gitlab-ci
		
2. Проверил что ВМ создана и подключимся к ней.

		$ docker-machine ls
		NAME        ACTIVE   DRIVER   STATE     URL                        SWARM   DOCKER     ERRORS
		gitlab-ci   -        google   Running   tcp://35.195.52.232:2376           v19.03.5
		
		$ eval $(docker-machine env gitlab-ci)
		$ docker-machine ssh gitlab-ci

3. Ставим docker-compose.

		$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
		$ add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
		$ apt-get update
		$ apt-get install docker-compose

4. Cоздаем необходимые директории и подготавливаем docker-compose.yml.

		$ sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
		$ cd /srv/gitlab/
		$ sudo wget https://gist.githubusercontent.com/Nklya/c2ca40a128758e2dc2244beb09caebe1/raw/e9ba646b06a597734f8dfc0789aae79bc43a7242/docker-compose.yml
		$ cat docker-compose.yml
		web:
  		  image: 'gitlab/gitlab-ce:latest'
  		  restart: always
  		  hostname: 'gitlab.example.com'
  		  environment:
    	    GITLAB_OMNIBUS_CONFIG: |
      	      external_url 'http://35.195.52.232'
  		  ports:
    	    - '80:80'
    	    - '443:443'
    	    - '2222:22'
  		  volumes:
    	    - '/srv/gitlab/config:/etc/gitlab'
    	    - '/srv/gitlab/logs:/var/log/gitlab'
    	    - '/srv/gitlab/data:/var/opt/gitlab'

5. Прописываем в docker-compose.yml IP адрес ВМ и запускаем docker-compose.yml

		$ sudo docker-compose up -d
	
	содержимое файла docker-compose.yml взято по ссылке:  
	https://docs.gitlab.com/omnibus/docker/README.html#install-gitlab-using-docker-compose

6. Откроем в браузере http://35.195.52.232.  
	Установим пароль пользователя root.  
	Залогинемся в Gitlab.  
	Выключаем регистрацию новых пользователей.  
	Создаем новую группу homework.

7. Добавляем remote в dmerkuriev_microservices

		$ git checkout -b gitlab-ci-1
		$ git remote add gitlab http://35.195.52.232/homework/example.git
		$ git push gitlab gitlab-ci-1

8. Для того, что бы определить CI/CD Pipeline для проекта, добавим в репозиторий файл .gitlab-ci.yml

		$ cat .gitlab-ci.yml
		stages:
  		  - build
  		  - test
  		  - deploy
		build_job:
  		  stage: build
  		  script:
    	    - echo 'Building'
		test_unit_job:
  		  stage: test
  		  script:
    	    - echo 'Testing 1'
		test_integration_job:
  		  stage: test
  		  script:
    	    - echo 'Testing 2'
		deploy_job:
  		  stage: deploy
  		  script:
    	    - echo 'Deploy'

		$ git add .gitlab-ci.yml
		$ git commit -m "add pipeline definition"
		$ git push gitlab gitlab-ci-1

9. Запустим Runner и зарегистрируем его в интерактивном режиме.  
	Перед тем, как запускать и регистрировать runner нужно получить токен. Переходим на страницу:  
	homework > example > CI/CD Settings > Runner и нажимаем expand.  
	Скопируем токен, он пригодится позднее.
	На сервере, где работает Gitlab CI выполним команду:
		
		$ sudo docker run -d --name gitlab-runner --restart always \
		-v /srv/gitlab-runner/config:/etc/gitlab-runner \
		-v /var/run/docker.sock:/var/run/docker.sock \
		gitlab/gitlab-runner:latest
		
		$ sudo  docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false
		Runtime platform     arch=amd64 os=linux pid=13 revision=ac8e767a version=12.6.0
		Running in system-mode.
		
		Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
		http://35.195.52.232/
		Please enter the gitlab-ci token for this runner:
		XXXXXXXXXXXXXXXX
		Please enter the gitlab-ci description for this runner:
		[f14c01a7883d]: my-runner
		Please enter the gitlab-ci tags for this runner (comma separated):
		linux,xenial,ubuntu,docker
		Registering runner... succeeded                     runner=6uSaQgNq
		Please enter the executor: docker, docker-ssh, parallels, shell, virtualbox, kubernetes, custom, docker+machine, docker-ssh+machine, ssh:
		docker
		Please enter the default Docker image (e.g. ruby:2.6):
		alpine:latest
		Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
		
	Переходим в веб-интерфейс и видим:  
	Runners activated for this project  
	zpA_nBAr  
	my-runner

10. Идем в вэб-интерфейс смотрим, что пайаплайн запустился и отработал. Нажимаем иконки, смотрим.
11. Добавим тестирование приложения reddit в pipeline.

	Добавим исходный код reddit в репозиторий
	
		$ git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
		$ git add reddit/
		$ git commit -m "Add reddit app"
		$ git push gitlab gitlab-ci-1
		
	Изменим описание пайплайна в .gitlab-ci.yml
	
		$ cat .gitlab-ci.yml
		image: ruby:2.4.2
		
		stages:
  		  - build
  		  - test
  		  - deploy
		
		variables:
  		  DATABASE_URL: 'mongodb://mongo/user_posts'
		
		before_script:
  		  - cd reddit
  		  - bundle install
		
		build_job:
  		  stage: build
  		  script:
    	    - echo 'Building'
		
		test_unit_job:
  		  stage: test
  		  services:
    	    - mongo:latest
  		  script:
    	    - ruby simpletest.rb

		test_integration_job:
  		  stage: test
  		  script:
    	    - echo 'Testing 2'
		
		deploy_job:
  		  stage: deploy
  		  script:
    	    - echo 'Deploy'

    В описании pipeline мы добавили вызов теста в файле simpletest.rb, нужно создать его в папке reddit:
    
    	$ cat reddit/simpletest.rb
		require_relative './app'
		require 'test/unit'
		require 'rack/test'
		
		set :environment, :test
		
		class MyAppTest < Test::Unit::TestCase
  		  include Rack::Test::Methods
		
  		  def app
    	    Sinatra::Application
  		  end
		  
  		  def test_get_request
    	    get '/'
            assert last_response.ok?
          end
        end

	Последним шагом нам нужно добавить библиотеку для тестирования в reddit/Gemfile приложения.
	
		$ cat reddit/Gemfile
		...
		gem 'rack-test'
		...

	Теперь на каждое изменение в коде приложения будет запущен тест

12. Изменим пайплайн таким образом, чтобы job deploy стал определением окружения dev, на которое условно будет выкатываться каждое изменение в коде проекта.  
Перепишем .gitlab-ci.yml  
Переименуем deploy stage в review  
deploy_job заменим на deploy\_dev\_job  
Добавим environment
		
		$ cat .gitlab-ci.yml
		image: ruby:2.4.2
		
		stages:
  		  ...
  		  - review
		...
		
		
		deploy_dev_job:
  		  stage: review
  		  script:
    	    - echo 'Deploy'
    	  environment:
    	    name: dev
    	    url: http://dev.example.com

13. Если на dev мы можем выкатывать последнюю версию кода, то к production окружению это может быть неприменимо, если, конечно, вы не стремитесь к continuous deployment.  
Определим два новых этапа: stage и production, первый будет содержать job имитирующий выкатку на staging окружение, второй на production окружение.  
Определим эти job таким образом, чтобы они запускались с кнопки.

		$ cat .gitlab-ci.yml
		image: ruby:2.4.2

		stages:
 		  ...
  		  - stage
  		  - production
  		...
  		
  		staging:
  		  stage: stage
  		  when: manual
  		  script:
    	    - echo 'Deploy'
  		  environment:
    	    name: stage
    	    url: https://beta.example.com

		production:
  		  stage: production
  		  when: manual
  		  script:
    	    - echo 'Deploy'
  		  environment:
    	    name: production
    	    url: https://example.com

14. Обычно, на production окружение выводится приложение с явно зафиксированной версией (например, 2.4.10).  
Добавим в описание pipeline директиву, которая не позволит нам выкатить на staging и production код,
не помеченный с помощью тэга в git.  
Директива only описывает список условий, которые должны быть истинны, чтобы job мог запуститься.
Регулярное выражение слева означает, что должен стоять semver тэг в git, например, 2.4.10.

		$ cat .gitlab-ci.yml
		...
		staging:
  		  stage: stage
  		  when: manual
  		  only:
    	    - /^\d+\.\d+\.\d+/
  		  script:
    	    - echo 'Deploy'
  		  environment:
    	    name: stage
    	    url: https://beta.example.com

		production:
  		  stage: production
  		  when: manual
  		  only:
    	    - /^\d+\.\d+\.\d+/
  		  script:
    	    - echo 'Deploy'
  		  environment:
    	    name: production
    	    url: https://example.com

	Теперь при внесении изменений без тега запустится пайплайн без job staging и production.  
	Изменение, помеченное тэгом в git запустит полный пайплайн.
	
		$ git add .gitlab-ci.yml
		$ git commit -m "Add tag for stage and prod"
		$ git tag 2.4.10
		$ git push gitlab gitlab-ci-1 --tags

15. Динамическое окружение.  
	Gitlab CI позволяет определить динамические окружения, это мощная функциональность позволяет вам иметь выделенный стенд для, например, каждой feature-ветки в git.  
Определяются динамические окружения с помощью переменных, доступных в .gitlab-ci.yml.  
Этот job (branch review) определяет динамическое окружение для каждой ветки в репозитории, кроме ветки master.

		$ cat .gitlab-ci.yml
		image: ruby:2.4.2
		...

		deploy_dev_job:
  		  stage: review
  		  script:
    	    - echo 'Deploy'
  		  environment:
    	    name: dev
    	    url: http://dev.example.com

		branch review:
  		  stage: review
  		  script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
  		  environment:
    	    name: branch/$CI_COMMIT_REF_NAME
   		    url: http://$CI_ENVIRONMENT_SLUG.example.com
  		  only:
    	    - branches
  		  except:
    	    - master

		staging:
  		  stage: stage
  		  when: manual
  		  only:
    	    - /^\d+\.\d+\.\d+/
  		...
  Теперь, на каждую ветку в git отличную от master Gitlab CI будет определять новое окружение.  
  Eсли создать ветки new-feature и bugfix, то на странице окружений они будут в review ветке.

16. Задание со *.  
	* В шаг build добавить сборку контейнера с приложением reddit.  
	Деплойте контейнер с reddit на созданный для ветки сервер.  
	
		Задание показалось довольно объемным, с наскока решить не получилось. Отложил до будущих времен.


17. Задание со *.  
	* Продумайте автоматизацию развертывания и регистрации Gitlab CI Runner. В больших организациях количество Runners может превышать 50 и более, сетапить их руками становится проблематично.  
	Реализацию функционала добавьте в репозиторий в папку gitlab-ci.  
	
		Для автоматизации напишем простой скрипт gitlab_runner_install.sh  
		Ключи для установки gitlab-runner возьмем из документации:  
		https://docs.gitlab.com/runner/register/index.html
		Запустить скрипт можно коммандой:
		
			$ sudo docker_runner_install.sh <gitlab-url> <project-registration-token>

	* Настройте интеграцию вашего Pipeline с тестовым Slack-чатом, который вы использовали ранее. Для этого перейдите в Project > Settings > Integrations > Slack notifications.  
	Нужно установить active, выбрать события и заполнить поля с URL вашего Slack webhook.  
	Добавьте ссылку на канал в слаке, в котором можно проверить работу оповещений, в файл README.md.

		Настроил интеграцию gitlab с slack-чатом:  
		https://devops-team-otus.slack.com/archives/CN8E22PU1
	


# HomeWork 16 (Monitoring-1)
--

**План работы:**  
• Prometheus: запуск, конфигурация, знакомство с Web UI  
• Мониторинг состояния микросервисов  
• Сбор метрик хоста с использованием экспортера
 
##Подготовка окружения
Создадим правило фаервола для Prometheus и Puma:

	$ gcloud compute firewall-rules create prometheus-default --allow tcp:9090
	$ gcloud compute firewall-rules create puma-default --allow tcp:9292


Создадим Docker хост в GCE и настроим локальное окружение на работу с ним

	$ export GOOGLE_PROJECT=docker-263919
	$ docker-machine create --driver google \
	--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
	--google-machine-type n1-standard-1 \
	--google-zone europe-west1-b \
	docker-host
	$ eval $(docker-machine env docker-host)
	
Систему мониторинга Prometheus будем запускать внутри Docker контейнера. Для начального знакомства воспользуемся готовым образом с DockerHub.

	$ docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0
	$ docker ps
	CONTAINER ID        IMAGE                    COMMAND                  CREATED              STATUS              PORTS                    NAMES
	abd3f710f3a9        prom/prometheus:v2.1.0   "/bin/prometheus --c…"   About a minute ago   Up About a minute   0.0.0.0:9090->9090/tcp   prometheus
	
Откроем веб интерфейс http://35.205.200.140:9090/  
По умолчанию сервер слушает на порту 9090, а IP адрес созданной VM можно узнать, используя команду: 

	$ docker-machine ip docker-host
	35.205.200.140
	
Посмотрим метрики которые prometheus собирает сам с себя.

Остановим контейнер

	$ docker stop prometheus
	
##Переупорядочим структуру директорий

До перехода к следующему шагу приведем структуру каталогов в более четкий/удобный вид:  
1. Создадим директорию docker в корне репозитория и перенесем в нее директорию docker-monolith и файлы docker-compose.* и все .env (.env должен быть в .gitgnore), в репозиторий закоммичен .env.example, из которого создается .env.  
2. Создадим в корне репозитория директорию monitoring. В ней будет хранится все, что относится к мониторингу.  
3. Не забываем про .gitgnore и актуализируем записи при необходимости.  

С этого момента сборка сервисов отделена от docker-compose, поэтому инструкции build можно удалить из docker-compose.yml.

##Создание Docker образа

Создадим директорию monitoring/prometheus. Затем в этой директории создим простой Dockerfile, который будет копировать файл конфигурации с нашей машины внутрь контейнера:

	$ mkdir monitoring/prometheus
	$ cat monitoring/prometheus/Dokerfile
	FROM prom/prometheus:v2.1.0
	ADD prometheus.yml /etc/prometheus/
	
##Конфигурация	

Определим простой конфигурационный файл для сбора метрик с наших микросервисов. В директории monitoring/prometheus создадим файл prometheus.yml
	
	$ cat monitoring/prometheus/prometheus.yml
	---
	global:
	  scrape_interval: '5s'
	
	  scrape_configs:
	    - job_name: 'prometheus'
	      static_configs:
	        - targets:
	          - 'localhost:9090'

  	    - job_name: 'ui'
          static_configs:
            - targets:
              - 'ui:9292'

       - job_name: 'comment'
         static_configs:
           - targets:
             - 'comment:9292'


##Создаем образ
В директории prometheus собираем Docker образ:

	$ export USER_NAME=username
	$ docker build -t $USER_NAME/prometheus .

##Образы микросервисов

В коде микросервисов есть healthcheck-и для проверки работоспособности приложения.  
Сборку образов теперь необходимо производить при помощи скриптов docker\_build.sh, которые есть в директории каждого сервиса. С его помощью мы добавим информацию из Git в наш healthcheck.
Выполним сборку образов при помощи скриптов docker\_build.sh в директории каждого сервиса.
	
	/src/ui $ bash docker_build.sh
	/src/post-py $ bash docker_build.sh
	/src/comment $ bash docker_build.sh

Или сразу все из корня репозитория:
	
	for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done

Будем поднимать наш Prometheus совместно с микросервисами. Определите в вашем docker/docker-compose.yml файле новый сервис.

	$ cat docker/docker-compose.yml
	services:
	...
    prometheus:
      image: ${USERNAME}/prometheus
      ports:
        - '9090:9090'
      networks:
        - front_net
        - back_net
      volumes:
        - prometheus_data:/prometheus
      command:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--storage.tsdb.retention=1d'

	volumes:
      prometheus_data:

Поднимем сервисы, определенные в docker/docker-compose.yml

	$ docker-compose up -d
	
Подключимся к веб-интерфейсу http://35.195.96.243:9090/ и посмотрим список endpoint-ов, с которых собирает информацию Prometheus.  
Healthcheck-и представляют собой проверки того, что наш сервис здоров и работает в ожидаемом режиме. В нашем случае healthcheck выполняется внутри кода микросервиса и выполняет проверку того, что все
сервисы, от которых зависит его работа, ему доступны.  
Если требуемые для его работы сервисы здоровы, то healthcheck проверка возвращает status = 1, что
соответсвует тому, что сам сервис здоров.  
Если один из нужных ему сервисов нездоров или недоступен, то проверка вернет status = 0. 

Построили график того, как менялось значение метрики ui_health со временем.  
Остановили и подняли сервис post и посмотрели как это отразилось на графике.

##Exporters
Экспортер похож на вспомогательного агента для сбора метрик.  
В ситуациях, когда мы не можем реализовать отдачу метрик Prometheus в коде приложения, мы можем использовать экспортер, который будет транслировать метрики приложения или системы в формате доступном для чтения Prometheus.

Exporters  
• Программа, которая делает метрики доступными для сбора Prometheus  
• Дает возможность конвертировать метрики в нужный для Prometheus формат  
• Используется когда нельзя поменять код приложения  
• Примеры: PostgreSQL, RabbitMQ, Nginx, Node, exporter, cAdvisor

Воспользуемся Node экспортер для сбора информации о работе Docker хоста (виртуалки, где у
нас запущены контейнеры) и предоставлению этой информации в Prometheus. 

Node экспортер будем запускать также в контейнере. Определим еще один сервис в docker/docker-compose.yml файле. Не забудьте также добавить определение сетей для сервиса node-exporter,
чтобы обеспечить доступ Prometheus к экспортеру. 

Расширим файл docker-compose.yml контейнером для node-exporter

	$ cat docker/docker-compose.yml
	services:
	...
	node-exporter:
	  image: prom/node-exporter:v0.15.2
      user: root
      volumes:
        - /proc:/host/proc:ro
        - /sys:/host/sys:ro
        - /:/rootfs:ro
      command:
        - '--path.procfs=/host/proc'
        - '--path.sysfs=/host/sys'
        - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
      networks:
        - back_net
        - front_net
    ...
 
Чтобы сказать Prometheus следить за еще одним сервисом, нам нужно добавить информацию о нем в конфиг. Добавим еще один job:

	$ cat ../monitoring/prometheus/prometheus.yml
	scrape_configs:
	...
	  - job_name: 'node'
	    static_configs:
         - targets:
           - 'node-exporter:9100'
        
 Не забудем собрать новый Docker для Prometheus:
 
 	monitoring/prometheus $ docker build -t $USER_NAME/prometheus .

Пересоздадим наши сервисы:

	$ docker-compose down
	$ docker-compose up -d
	
Посмотрим, список endpoint-ов Prometheus http://35.195.96.243:9090/targets  
Появился еще один endpoint.  
	
	node (1/1 up)  
	Endpoint						  State	Labels 						  Last Scrape	Error  
	http://node-exporter:9100/metrics UP	instance="node-exporter:9100" 4.656s ago

Получим информацию об использовании CPU.  
Проверим мониторинг:  
• Зайдем на хост: docker-machine ssh docker-host  
• Добавим нагрузки: yes > /dev/null  
нагрузка выросла, мониторинг отображает повышение загруженности CPU.


• Запушим собранные вами образы на DockerHub: 
	
	$ docker login
	Authenticating with existing credentials...
	Login Succeeded
	$ docker push $USER_NAME/ui
	$ docker push $USER_NAME/comment
	$ docker push $USER_NAME/post
	$ docker push $USER_NAME/prometheus 

Удалим виртуалку:
	
	$ docker-machine rm docker-host
	
Ссылка на docker hub: https://hub.docker.com/u/dmerkuriev

##Задание со *
Добавьте в Prometheus мониторинг MongoDB с использованием необходимого экспортера.  
• Версию образа экспортера нужно фиксировать на последнюю стабильную.  
• Если будете добавлять для него Dockerfile, он должен быть в директории monitoring, а не в корне репозитория.  
P.S. Проект dcu/mongodb_exporter не самый лучший вариант, т.к. у него есть проблемы с поддержкой (не обновляется).

В качестве рабочего варианта возьмем percona/mongo_exporter.
https://github.com/percona/mongodb\_exporter/blob/master/README.md
Собираем образ и пушим его в DockerHub:

	$ git clone https://github.com/percona/mongodb_exporter.git
	$ cd mongodb_exporter/
	$ make docker
	Successfully built aa2622f55044
	Successfully tagged mongodb-exporter:master
	$ docker tag mongodb-exporter:master dmerkuriev/mongodb-exporter:0.10.0
	$ docker login
	Authenticating with existing credentials...
	Login Succeeded
	$ docker push dmerkuriev/mongodb-exporter:0.10.0
	
Добавим в конфиг prometheus новую джобу.

	$ cat prometheus/prometheus.yml
	---
	global:
  	scrape_interval: '5s'
	
	scrape_configs:
	...
	
  	  - job_name: 'mongodb-exporter'
  	    static_configs:
  	      - targets:
  	        - 'mongodb-exporter:9216'

Пропишем в наш docker-compose

	$ cat docker-compose.yml
	version: '3.3'
	services:
	  ...
	  mongodb-exporter:
	    image: ${USERNAME}/mongodb-exporter:${MONGODB_EXPORTER_VERSION}
	    networks:
	      - back_net
	    environment:
	      MONGODB_URI: "mongodb://post_db:27017"
	...

Пересобираем образ промитея, поднимаем окружение и проверяем метрики mongodb.

##Задание со *
Добавьте в Prometheus мониторинг сервисов comment, post, ui с помощью blackbox экспортера.  
Blackbox exporter позволяет реализовать для Prometheus мониторинг по принципу черного ящика. Т.е. например мы можем проверить отвечает ли сервис по http, или принимает ли соединения порт.  
• Версию образа экспортера нужно фиксировать на последнюю стабильную.  
• Если будете добавлять для него Dockerfile, он должен быть в директории monitoring, а не в корне репозитория.  
Вместо blackbox_exporter можете попробовать использовать Cloudprober от Google.

Задание отложил на будущее.

##Задание со *
Как вы могли заметить, количество компонент, для которых необходимо делать билд образов, растет. И уже сейчас делать это вручную не очень удобно.  
Можно было бы конечно написать скрипт для автоматизации таких действий.  
Но гораздо лучше для этого использовать Makefile.  
Задание: Напишите Makefile, который в минимальном варианте умеет:  
1. Билдить любой или все образы, которые сейчас используются.  
2. Умеет пушить их в докер хаб.  
Дополнительно можете реализовать любый сценарии, которые вам кажутся
полезными. 

Задание отложил на будущее.


