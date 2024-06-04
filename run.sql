use dfs;
-- Make sure blank strings become NULLs,
-- or the `cast`s will fail in the `create table` below.
alter system set `drill.exec.functions.cast_empty_string_to_null` = true;
create table `output`
as
    select 
        medallion,
        hack_license,
        vendor_id,
        rate_code,
        store_and_fwd_flag,
        cast(pickup_datetime as timestamp) as pickup_datetime,
        cast(dropoff_datetime as timestamp) as dropoff_datetime,
        cast(passenger_count as int) as passenger_count,
        cast(trip_time_in_secs as bigint) as trip_time_in_secs,
        cast(trip_distance as float) as trip_distance,
        cast(pickup_longitude as double) as pickup_longitude,
        cast(pickup_latitude as double) pickup_latitude,
        cast(dropoff_longitude as double) as dropoff_longitude,
        cast(dropoff_latitude as double) as dropoff_latitude
    from `trip/data` as t;
