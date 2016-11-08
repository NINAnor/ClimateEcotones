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
r.resamp.stats --o --v input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_min method=minimum
r.resamp.stats --o --v input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_max method=maximum
r.resamp.stats --o --v input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_mean method=average
r.resamp.stats --o --v input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_stddev method=stddev
r.resamp.stats --o --v input=eurolst_clim.bio${b}@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM output=eurolst_clim.bio${b}_1km_var method=variance
r.mapcalc --o --v expression="eurolst_clim.bio${b}_1km_range=eurolst_clim.bio${b}_1km_max - eurolst_clim.bio${b}_1km_min"
done


# Calculate differences between EuroLST and SeNorge for bioclim variables
for b in 01 02 03 04 05 06 07 10 11
do
# Compute within-pixel variation between 250m EuroLST and 1km SeNorge data
r.mapcalc --o --v expression="eurolst_SeNorge_bio${b}_1km_difference=eurolst_clim.bio${b}_1km_mean - temperature_seNorge_1km_bioclim_bio${b}_2001_2010_mean"
done

