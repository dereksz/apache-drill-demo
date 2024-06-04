.PHONEY: build run stop start create remove exec up attach batch rm data

# NY_TAXI_DATA := /media/12Tb-mirror/Shared/BigData/Data/ia802501.us.archive.org/1/items/nycTaxiTripData2013
NY_TAXI_DATA := /data/ny-taxi
NT_TAXI_HTTP=https://ia902202.us.archive.org/28/items/nycTaxiTripData2013
CONTAINER_NAME := ow-drill-1

# Targets for fetching and de-/re-compressing
$(NY_TAXI_DATA)/trip_%.7z:
	curl -o "$@" "$(NT_TAXI_HTTP)/$(@F)" 

$(NY_TAXI_DATA)/trip/%: $(NY_TAXI_DATA)/trip_%.7z
	mkdir -p "$@"
	for F in `7z l "$<" | grep -o -E 'trip_[a-z]+_[0-9]+\.csv'`; \
	do \
		7z e -so "$<" "$$F" | gzip -c > "$@/$$F.gz" & \
	done; \
	wait
	du -sch "$@/*.gz"

data: $(NY_TAXI_DATA)/data # $(NY_TAXI_DATA)/fare - we don't currently use the fare data
	# op-op


build:
	docker buildx build --tag $(CONTAINER_NAME) --target $(CONTAINER_NAME) .

remove: stop
	docker container rm -f $(CONTAINER_NAME) > /dev/null

create: build remove
	docker create --name $(CONTAINER_NAME) -it \
		--memory=54G \
		--cpus="12.0" \
		--cpu-shares=1024 \
		-p 8047:8047 -p 31010:31010 \
		-v "$(NY_TAXI_DATA)":/data \
		$(CONTAINER_NAME)

rm:
	[ ! -d "$(NY_TAXI_DATA)/output" ] || sudo rm -rf "$(NY_TAXI_DATA)/output/"

run: create rm
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