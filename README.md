# Intention

* To play around with Apache Drill on a non-toy dataset.
* Specifically looking at file conversion from CSV to Parquet.
* Using the old 2013 NYC Taxi dataset, as I had it around.
* We will read a directory of `.csv.gz` files and write a directory of Parquet files.


# Prerequisites

* Docker
* 7zip (the `7z` command line executable)
* gzip
* Internet access working for `docker pull`s and `curl`


# Approach

* Use the published [apache/drill docker image](https://hub.docker.com/r/apache/drill),
  with some minimal modifications.
* Use a Makefile to capture that various steps.


# Data Acquisition

1. Decide where you want you data files to be (both input and output).
2. Create an empty folder there.
3. Update `NY_TAXI_DATA` in the `Makefile` to use this new empty folder.
4. Run `make data`.  This will download and un-/re-compress the data from
   [https://ia802202.us.archive.org/1/items/nycTaxiTripData2013/](https://ia802202.us.archive.org/1/items/nycTaxiTripData2013/)


NB: The Docker image will create a user with a `uid` of 999.  In order that the data folder
is readable, I typically just change the "all" permissions using `chmod a+...`.  If you have 
issues after the fact, try:

```bash
DATA=/data # Or wherever you've defined your data folder
chmod a+r -R "$DATA" # make everything readable by everybody
find "$DATA" -type d -exec chmod a+x "{}" + # make directories readable ("executable" [sic])
chmod a+rwx "$DATA" # So container can create the `output` folder.
```

# Dockerfile

Builds two images, `ow-drill` and `ow-drill-1`.  The "`1`" version builds on the base version
by using a `run.sql` script as the single-shot script for Drill to run when it's launched.

The custom docker file installs some useful command line utilities and copies over two 
custom configuration files.

## `drill-override.conf`

Essentially the file contains the following.

```json
{
    "drill.exec.options": {
        "store": {
            "format": "parquet",
            "parquet" {
                "compression": "zstd",
                "block-size": 536870912
            }
        }
    }
}
```

The files format is actually [HOCON](https://github.com/lightbend/config/blob/master/HOCON.md)
format, so the committed file includes some comments and some looser formatting.

The contents here sets the default output to Parquet, and adds compression and a "file-size".
If the files being outputted exceed this size, they will be output as multiple files.

## `storage-plugins-override.conf`

This file is really about overriding two things.

### 1. Default `dfs` definition, where files will be read from

```json
{
    "storage": {
        "dfs": {
            "type" : "file",
            "connection" : "file:///",
            "workspaces" : {
                "default": {
                    "location": "/data", # <== New location
                    "writable": true, # <== Make default writeable
                    "defaultInputFormat": null
                } 
            }  
        } 
    }    
}
```

### 2. Customize the `csv` file format

```json
{
      "csv" : {
        # Many need to change these up!
        "type" : "text",
        "extensions" : [ "csv" ],
        "lineDelimiter": "\r\n", # <== Windows-style line endings
        "fieldDelimiter": ",",
        "quote": "\"",
        "escape": "\"",
        "comment": "#",
        "extractHeader": true # <== Header row has column names, get them 
      }
}      
```

# Build & Execute Process

1. `make build` - builds docker _image_, using the `Dockerfile`, named `ow-drill-1`.
2. `make create` - build the docker _container_, named `ow-drill-1` (or modify `CONTAINER_NAME`)
3. `make run` - actually run the container.  It will run the `run.sql` script and then exit.

The steps in the `Makefile` actually cascade on top of each other, so you can actually just run
`make run` and the image will be rebuilt if required and container rebuilt (always - but this is
very quick in comparison to building the image).

## Memory usage

The `create:` step in the Makefile allow us to specify the amount of memory given to the 
running container.  You'll want to customize this to better reflect the capabilities of your
own machine.

```bash
	docker create --name $(CONTAINER_NAME) -it \
		--memory=54G \
		--cpus=12.0 \
		--cpu-shares=1024 \
		-p 8047:8047 -p 31010:31010 \
		-v "$(NY_TAXI_DATA)":/data \
		$(CONTAINER_NAME)

```

# Drill SQLLine CLI

If you want to experiment with Drill, rather than run a single-shot, change
the line `CONTAINER_NAME := ow-drill-1` in the Makefile to `CONTAINER_NAME := ow-drill`
and run `make run`.  This will prevent the script from being passed in
resulting in an Drill SQLLine prompt being presented.

Some quick things to try from there:

```sql
use dfs;
show files in dfs;
show files in dfs.`trip/data`;
select * from `trip/data` limit 10;
```
