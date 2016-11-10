SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('temp_' || gid AS varchar(15)) AS id
  FROM sentinel4nature."temperaturelogger_locations_Nina_Eide") AS x
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('ce_gps_' || gid AS varchar(15)) AS id
  FROM climateecotones.ce_gps_waypoints_2016) AS y
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('hjerk_gps_' || gid AS varchar(15)) AS id
  FROM climateecotones.hjerkin_sip_gps_waypoints_2016) AS z ORDER BY id;
