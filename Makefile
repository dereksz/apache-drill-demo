.PHONEY: build run stop start create remove exec up attach

CONTAINER_NAME := ow-drill-1

build:
	docker buildx build -t ow-drill .

remove: stop
	docker container rm -f $(CONTAINER_NAME) > /dev/null

create: build remove
	docker create --name $(CONTAINER_NAME) -it \
		-m 40G \
		-p 8047:8047 -p 31010:31010 \
		-v /media/12Tb-mirror/Shared/BigData/Data/ia802501.us.archive.org/1/items/nycTaxiTripData2013:/data \
		ow-drill		

run:
	docker start -ai $(CONTAINER_NAME)

stop:
	-docker stop $(CONTAINER_NAME)

start: # Start without interactive???  Not sure how.  (Try `docker compose up` instead)
	docker start $(CONTAINER_NAME) # exists immediately

exec:
	docker exec -it $(CONTAINER_NAME) /bin/bash

attach: # If we've used `compose` to bring it up
	docker attach $(CONTAINER_NAME)

up: remove # Brings it up nicely in the background ready for an attach
	docker compose up -d