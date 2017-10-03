"""
	aggregate2

Aggregate data to yearly, monthly, daily, hourly or ONE minute samples.
Simple aggregation = sum, mean, maximum or minimum can be applied during re-sampling.
Missing (NaN) data can be either kept or replaced during re-sampling.

**Input**
* data: DataFrame where at least one column contains DateTime
* timecol: column containing DateTime. Default column name = :datetime
* resol: output (date)time resolution, e.g. Dates.Hour(1) (default).
> Dates.Hour(2) is not allowed (only ONE hour|minute|...)

* fce: function to by applied = sum (default)| mean | maximum | minimum
> To remove NaNs use `x->sum(filter(!isnan,x))` function

**Output**
* resampled dataframe with all input columns
> **Warning** the output dataframe can be re-arranged!

**Example**
```
data = DataFrame(Temp=[10,11,12,14],
       datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
         DateTime(2010,1,1,2),DateTime(2010,1,1,4)]);
dataa = aggregate2(data,resol=Dates.Day(1),fce=x->minimum(dropna(x)));
```
"""
function aggregate2(data::DataFrame;
					timecol=:datetime,resol=Dates.Hour(1),
					fce=sum)
	# Create a copy of the DateFrame for manipulation
	dfc = deepcopy(data);
	# Convert input resolution to string pattern + apply
	datestringcol = time2pattern(resol);
	dfc[:datestringcol] = Dates.format.(dfc[timecol],datestringcol);
	# do not use datetime for aggregation (not supported)
	useonly = allexcept(names(dfc),timecol);
	dfc = aggregate(dfc[useonly],:datestringcol,fce)
	# Add back back datetime and remove date-string used for aggregation
	dfc[timecol] = DateTime.(dfc[:datestringcol],datestringcol);
	delete!(dfc,:datestringcol);
	return dfc
end

"""
	time2pattern(resol)

Convert DateTime hour, minute,... to string pattern, e.g. "yyyymmhh" or "yyyymmddhhmm"

**Input**
* resol: output (date)time resolution, e.g. Dates.Hour(1). (Dates.Hour(2) is not allowed)

**Output**
* datetime string

**Example**
```
s = time2pattern(Dates.Hour(1));
```
"""
function time2pattern(resol)
	if resol==Dates.Minute(1)
		return "yyyymmddHHMM"
	elseif resol==Dates.Hour(1)
		return "yyyymmddHH"
	elseif resol==Dates.Day(1)
		return "yyyymmdd"
	elseif resol==Dates.Month(1)
		return "yyyymm"
	elseif resol==Dates.Year(1)
		return "yyyy"
	end
end

"""
	time2regular(data,timecol,resol)

Resample data to regular time sampling (missing filled with NA values)

**Input**
* data: DataFrame where at least one column contains DateTime
* timecol: column containing DateTime. Default column name = :datetime
* resol: output (date)time resolution, e.g. Dates.Hour(1)

**Output**
* resampled dataframe with all input columns

**Example**
```
data = DataFrame(Temp=[10,11,12,14],
			datetime=[DateTime(2010,1,1,0),DateTime(2010,1,1,1),
			DateTime(2010,1,1,2),DateTime(2010,1,1,4)]);
reg_sample = time2regular(data,timecol=:datetime,resol=Dates.Hour(1))

```
"""
function time2regular(data::DataFrame;timecol=:datetime,resol=Dates.Hour(1))
	# create dataframe with regular sampling
	dfr = DataFrame(datetime=collect(data[timecol][1]:resol:data[timecol][end]));
	# joint original and regular sampled dataframe
	reg_sample = join(data,dfr,on=timecol,kind=:right);
	# Sort accoring to time
	return sort!(reg_sample, cols=timecol);
end


"""
	isregular(timevec)

Check if the data/time vector is regularly sampled

**Input**
`timevec`: DataArray with DateTime

**Output**
`true` for regularly sampled data

**Example**
```
timevec = @data([DateTime(2010,1,1,1,0,0),
				 DateTime(2010,1,1,2,0,0),
				 DateTime(2010,1,1,3,0,0),
				 DateTime(2010,1,1,5,0,0),# fourth hour is missing =>not regular
				 DateTime(2010,1,1,6,0,0)]);
out = isregular(timevec); # will return false
```
"""
function isregular(timevec::DataArray{DateTime,1})
	timediff = diff(Dates.value.(timevec));
	if all(timediff[1] .== timediff)
		return true;
	else
		return false;
	end
end


"""
	allexept(name)

Auxiliary function to return all column numbers except for input name

**Input**
* head: names collection (=names(dataframe))
* name: name/key to be excluded

**Output**
* list of indices
"""
function allexcept(head,name)
	index = Vector{Int64}(0);
	for (i,val) in enumerate(head)
		if val != name
			push!(index,i)
		end
	end
	return index;
end