SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, stnr
  FROM "Meteorology"."metnoStations") AS x ORDER BY stnr;
