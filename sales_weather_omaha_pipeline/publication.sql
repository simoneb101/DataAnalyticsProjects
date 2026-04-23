SELECT * FROM pg_create_logical_replication_slot('airbyte_gis_weather', 'pgoutput');
DROP PUBLICATION IF EXISTS airbyte_gis_weather;
CREATE PUBLICATION airbyte_gis_weather FOR TABLE data.gis_weather;