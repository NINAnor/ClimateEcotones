g.region -p raster=temperature_seNorge_1km_months_max_2001_01@gt_Meteorology_Norway_seNorge_temperature_months 

for y in $(seq 2001 2010)
do
y_before=`expr $y - 1`
y_after=`expr $y + 1`

align=temperature_seNorge_1km_months_max_2001_01@gt_Meteorology_Norway_seNorge_temperature_months
temp_max=$(t.rast.list -s input=temperature_seNorge_1km_months_max@gt_Meteorology_Norway_seNorge_temperature_months columns=name,mapset where="start_time >= '${y_before}-12-31 0:00:00' AND end_time < '${y_after}-01-01 0:00:00'" method=comma)
temp_min=$(t.rast.list -s input=temperature_seNorge_1km_months_min@gt_Meteorology_Norway_seNorge_temperature_months columns=name,mapset where="start_time >= '${y_before}-12-31 0:00:00' AND end_time < '${y_after}-01-01 0:00:00'" method=comma)
temp_mean=$(t.rast.list -s input=temperature_seNorge_1km_months_mean@gt_Meteorology_Norway_seNorge_temperature_months columns=name,mapset where="start_time >= '${y_before}-12-31 0:00:00' AND end_time < '${y_after}-01-01 0:00:00'" method=comma)

# Generate yearly bioclim variables based on temperature
r.bioclim --o --v tmin=$temp_min tmax=$temp_max tavg=$temp_mean output=temperature_seNorge_1km_bioclim_$y workers=5
done

# Aggregate bioclim variables based on temperature like in EuroLST
for b in 01 02 03 04 05 06 07 10 11
do
input=$(g.list type=raster pattern=temperature_seNorge_1km_bioclim_*bio$b mapset='.' separator=',')
r.series --overwrite --verbose input=$input output=temperature_seNorge_1km_bioclim_bio${b}_2001_2010_mean,temperature_seNorge_1km_bioclim_bio${b}_2001_2010_median,temperature_seNorge_1km_bioclim_bio${b}_2001_2010_min,temperature_seNorge_1km_bioclim_bio${b}_2001_2010_max method=average,median,minimum,maximum
done

# Aggregate bioclim variables based on temperature like in EuroLST
for b in 01 02 03 04 05 06 07 10 11
do
# Compute within-pixel variation between 250m EuroLST and 1km SeNorge data
r.resamp.stats --o --v -w input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_min method=minimum
r.resamp.stats --o --v -w input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_max method=maximum
r.resamp.stats --o --v -w input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_mean method=average
r.resamp.stats --o --v -w input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_stddev method=stddev
r.resamp.stats --o --v -w input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_var method=variance
r.mapcalc --o --v expression="eurolst_clim.bio${b}_1km_range=eurolst_clim.bio${b}_1km_max - eurolst_clim.bio${b}_1km_min"
### Calculate differences between EuroLST and SeNorge for bioclim variables
# Compute difference between 250m EuroLST aggregated to 1km and 1km SeNorge data
r.mapcalc --o --v expression="eurolst_SeNorge_bio${b}_1km_difference=float(float(eurolst_clim.bio${b}_1km_mean) - float(temperature_seNorge_1km_bioclim_bio${b}_2001_2010_mean))/10.0"
# Compute differen1km SeNorge data and 1km WorldClim
#r.mapcalc --o --v expression="SeNorge_WorldClim_bio${b}_1km_difference=temperature_seNorge_1km_bioclim_bio${b}_2001_2010_mean - WorldClim_current_bio05_1975@g_Meteorology_Fenoscandia_WorldClim_current"

# Set color table to "differences"
r.colors map=eurolst_SeNorge_bio${b}_1km_difference color=differences

# Get title of bioclim variable
if [ "bio${b}" == "bio01" ] ; then 
var="Annual Mean Temperature"
elif [ "bio${b}" == "bio02" ] ; then 
var="Mean Diurnal Range (Mean of monthly (max temp - min temp))"
elif [ "bio${b}" == "bio03" ] ; then 
var="Isothermality (BIO2/BIO7) (* 100)"
elif [ "bio${b}" == "bio04" ] ; then 
var="Temperature Seasonality (standard deviation *100)"
elif [ "bio${b}" == "bio05" ] ; then 
var="Max Temperature of Warmest Month"
elif [ "bio${b}" == "bio06" ] ; then 
var="Min Temperature of Coldest Month"
elif [ "bio${b}" == "bio07" ] ; then 
var="Temperature Annual Range (BIO5-BIO6)"
elif [ "bio${b}" == "bio08" ] ; then 
var="Mean Temperature of Wettest Quarter"
elif [ "bio${b}" == "bio09" ] ; then 
var="Mean Temperature of Driest Quarter"
elif [ "bio${b}" == "bio10" ] ; then 
var="Mean Temperature of Warmest Quarter"
elif [ "bio${b}" == "bio11" ] ; then 
var="Mean Temperature of Coldest Quarter"
fi

# Make a simple plot for each variable
d.mon --o start=cairo output=$HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/eurolst_SeNorge_bio${b}_1km_difference.png
d.rast map=eurolst_SeNorge_bio${b}_1km_difference
d.text -p -s text="Difference between EuroLST (E) and SeNorge (S) (E-S)" color=black linespacing=1 at=5,25 font=arialbd size=12
d.text -p -s text="BIO${b}: $var" color=black linespacing=1 at=5,45 font=arialbd size=12
d.legend -d raster=eurolst_SeNorge_bio${b}_1km_difference title="Temperature difference" title_fontsize=14 lines=1 units=" C" at=5,50,10,12.5 font=Arial fontsize=12
d.barscale at=50.0,10.0 length=500 units=kilometers segment=9
d.northarrow at=85.0,15.0 fontsize=12
d.mon stop=cairo
done

### Extract relevant coordinates for raw measurement data comparison
coords=$(psql -q -t -A -F ' ' -d gisdata -c 'SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, stnr
  FROM "Meteorology"."metnoStations") AS x ORDER BY CAST(stnr AS integer);')
echo "$coords" | r.what --overwrite --verbose map=eurolst_clim.bio01@EuroLST_BIOCLIM | grep -v '\*' | cut -f1-3 -d'|' | tr '|' ' ' > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/metno_stations.csv

psql -q -t -A -F ' ' -d gisdata -c "SELECT * FROM (SELECT DISTINCT ON (x,y) * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('temp_' || gid AS varchar(15)) AS id
  FROM sentinel4nature.\"temperaturelogger_locations_Nina_Eide\") AS a
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('ce_gps_' || gid AS varchar(15)) AS id
  FROM ecotones.ce_gps_waypoints_2016) AS b
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('hjerk_gps_' || gid AS varchar(15)) AS id
  FROM ecotones.hjerkin_sip_gps_waypoints_2016) AS c
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, \"ID\" AS id
  FROM ecotones.veipunkter) AS d 
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('trans_' || id AS varchar(15)) AS id
  FROM ecotones.transekter) AS e 
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('bil_squ_' || id AS varchar(15)) AS id
  FROM ecotones.bilberry_squares_2016) AS f 
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 3035)) AS X, ST_Y(ST_Transform(geom, 3035)) AS Y, CAST('bil_sept_' || id AS varchar(15)) AS id
  FROM ecotones.bilberry_sept_2016) AS g
) AS x ORDER BY id;" > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/templogger.csv


g.region -p raster=EuroLST_2010_01_avg@gt_Meteorology_Fenoscandia_EuroLST_month align=EuroLST_2010_01_avg@gt_Meteorology_Fenoscandia_EuroLST_month
### Extract relevant coordinates for raw measurement data comparison
coords=$(psql -q -t -A -F ' ' -d gisdata -c 'SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, stnr
  FROM "Meteorology"."metnoStations") AS x ORDER BY CAST(stnr AS integer);')
echo "$coords" | r.what --overwrite --verbose map=EuroLST_2010_01_avg@gt_Meteorology_Fenoscandia_EuroLST_month | grep -v '\*' | cut -f1-3 -d'|' | tr '|' ' ' > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/metno_stations_utm33.csv

psql -q -t -A -F ' ' -d gisdata -c "SELECT * FROM (SELECT DISTINCT ON (x,y) * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, CAST('temp_' || gid AS varchar(15)) AS id
  FROM sentinel4nature.\"temperaturelogger_locations_Nina_Eide\") AS a
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, CAST('ce_gps_' || gid AS varchar(15)) AS id
  FROM ecotones.ce_gps_waypoints_2016) AS b
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, CAST('hjerk_gps_' || gid AS varchar(15)) AS id
  FROM ecotones.hjerkin_sip_gps_waypoints_2016) AS c
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, \"ID\" AS id
  FROM ecotones.veipunkter) AS d 
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, CAST('trans_' || id AS varchar(15)) AS id
  FROM ecotones.transekter) AS e 
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, CAST('bil_squ_' || id AS varchar(15)) AS id
  FROM ecotones.bilberry_squares_2016) AS f 
UNION ALL 
SELECT * FROM (SELECT DISTINCT ON (geom) ST_X(ST_Transform(geom, 25833)) AS X, ST_Y(ST_Transform(geom, 25833)) AS Y, CAST('bil_sept_' || id AS varchar(15)) AS id
  FROM ecotones.bilberry_sept_2016) AS g
) AS x ORDER BY id;" > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/templogger_utm33.csv

cat $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/templogger_utm33.csv | t.rast.what -i strds=Fenoscandia_EuroLST_months_avg@gt_Meteorology_Fenoscandia_EuroLST_month > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/templogger_utm33_EuroLST_month.csv

cat $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/metno_stations_utm33.csv | t.rast.what -i strds=Fenoscandia_EuroLST_months_avg@gt_Meteorology_Fenoscandia_EuroLST_month > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/metno_stations_utm33_EuroLST_month.csv

g.region -p raster=temperature_seNorge_1km_months_mean_2013_11@gt_Meteorology_Norway_seNorge_temperature_months align=temperature_seNorge_1km_months_mean_2013_11@gt_Meteorology_Norway_seNorge_temperature_months

cat $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/templogger_utm33.csv | t.rast.what -i strds=temperature_seNorge_1km_months_mean@gt_Meteorology_Norway_seNorge_temperature_months > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/templogger_utm33_SeNorge_month.csv

cat $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/metno_stations_utm33.csv | t.rast.what -i strds=temperature_seNorge_1km_months_mean@gt_Meteorology_Norway_seNorge_temperature_months > $HOME/Prosjekter/Climate\ Ecotones/WP1/ClimateDataComparison/metno_stations_utm33_SeNorge_month.csv

Blacklist species
Acer pseudoplatanus - Platanlønn
Arion vulgaris - Brunskogsnegl
Impatiens glandulifera - Kjempespringfrø
varmeskye arter
Viola biflora  Fjellfiol
Veronica alpina - snøveronika
Vanlige arter og skoggrense
Vaccinium myrtillus - Blåbær

v.in.pygbif -i taxa="Acer pseudoplatanus,Arion vulgaris,Impatiens glandulifera,Viola biflora,Veronica alpina,Vaccinium myrtillus" output=ClimateEcotones

