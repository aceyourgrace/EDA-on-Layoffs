
libname layoff "/home/u63116985/LayoffsProject";
run;

PROC IMPORT DATAFILE="/home/u63116985/LayoffsProject/layoffs_data.csv"
	DBMS=csv
	OUT=layoff.LayoffData0;
	GETNAMES=YES;
RUN;

proc print data = layoff.LayoffData0;
run;

PROC CONTENTS DATA=layoff.LayoffData0;
run;

/* There are 7 char variables and 5 num variables */

/* Data Cleaning and Preprocessing */

/* Determining the categorical variables and the frequency of their missing values */

proc freq data = layoff.LayoffData0;
tables Company Country Industry List_of_Employees_Laid_Off Location_HQ Source Stage;
run;

/* Just 1 or 2 missing in all categorical */

/* Deleting the rows with entire values missing */
data layoff.LayoffData1;
set layoff.LayoffData0;
if cmiss(of Company -- List_of_Employees_Laid_Off) < 12;
run;

proc print data = layoff.LayoffData1;
run;

/* Creating a new dataset with only the required columns, i.e. Company, Country, Location_HQ, Industry, Laid Off Count, Percentage, Date, Funds Raised, Stage,
and dropping off other variables */

data layoff.LayoffData2;
set layoff.LayoffData1(keep = Company Location_HQ Date Industry Laid_Off_Count Funds_Raised Percentage Stage Country);
run;

proc print data = layoff.LayoffData2;
run;

/* EDA */
/* 1. Layoffs based on countries*/

proc sql;
	title 'Countries with the most layoffs';
	select Country, sum(Laid_Off_Count) as TotalCountCountry
	from layoff.LayoffData2
	group by Country
	order by TotalCountCountry desc;
quit;

proc sql;
	title 'Country with the least layoffs';
	select Country, sum(Laid_Off_Count) as TotalCountCountry
	from layoff.LayoffData2
	group by Country
	having sum(Laid_Off_Count) is not null
	order by TotalCountCountry;
quit;

/* 2. Layoffs based on industries */

proc sql;
	title "Industries with the most layoffs";
	select Industry, sum(Laid_Off_Count) as TotalCountIndustry
	from layoff.LayoffData2
	where Industry ne 'Other' and Industry ne 'Unknown'
	group by Industry
	order by TotalCountIndustry desc;
quit;

proc sql;
	title "Industries with the least layoffs";
	select Industry, sum(Laid_Off_Count) as TotalCountIndustry
	from layoff.LayoffData2
	where Industry ne 'Other' and Industry ne 'Unknown'
	group by Industry
	order by TotalCountIndustry;
quit;

/*3. Layoffs based on companies*/

proc sql;
	title "Companies with the most layoffs";
	select Company, sum(Laid_Off_Count) as TotalCountCompany
	from layoff.LayoffData2
	group by Company
	order by TotalCountCompany desc;
quit;


proc sql;
	title "Companies with the least layoffs";
	select Company, sum(Laid_Off_Count) as TotalCountCompany
	from layoff.LayoffData2
	group by Company
	having sum(Laid_Off_Count) is not NULL
	order by TotalCountCompany;
quit;

/* Finding the relation between lay off count and stage of the industry */

/* First of all, finding all the unique values */
proc freq data = layoff.LayoffData2;
tables Stage / out = unique_values;
run;

/* Using the ANOVA test to determine if there is relationship between the two variables */

proc glm data=layoff.LayoffData2;
  class Stage;
  model Laid_Off_Count = Stage;
run;

/* Since the p-value < 0.0001, on a 0.05 level of significance, I rejected the Null Hypothesis that suggests that the lay off counts of all the stages
is the same. And I accepted the Alternative Hypothesis that there is difference in laid off count with respect to
the stages of the company */

/* Digging deeper into this */

proc sql;
	title "Stages with the most layoffs";
	select Stage, sum(Laid_Off_Count) as TotalCountStage
	from layoff.LayoffData2
	where Stage ne 'Unknown'
	group by Stage
	order by TotalCountStage desc;
quit;

proc sql;
	title "Stages with the least layoffs";
	select Stage, sum(Laid_Off_Count) as TotalCountStage
	from layoff.LayoffData2
	where Stage ne 'Unknown'
	group by Stage
	order by TotalCountStage;
quit;

/* Finding relation between Funds Raised and the laid off counts */
/* First, taking only these two columns and only those values that aren't null in both */

data layoff.LayoffData4;
	set layoff.LayoffData2 (keep=Laid_Off_Count Funds_Raised where=(not missing(Laid_Off_Count) and not missing(Funds_Raised)));
run;
	
/* Stating hypothesis */
/* Null Hypothesis which suggests Funds Raised is not associated with Layoff Count
and Alternate Hypothesis which suggests Funds Raised is associated with Layoff Count */

/* Using Scatter Plot to find clearer relationship between the variables */
PROC SGPLOT data = layoff.LayoffData4;
scatter x = Funds_Raised y = Laid_Off_Count;
run;

/* Points seem to slightly clustered upward */
/* Using Pearson Corelation to determine correlation */

PROC CORR Data = layoff.LayoffData4;
VAR Funds_Raised Laid_Off_Count;
RUN;

/* Since the correlation coefficient is just 0.095, we can say that there is a very weak correlation between fund raised and the laid off counts.*/

/* Determining the month with the most layoffs */

/* First, extracting the months */

data layoff.LayoffData3;
  set layoff.LayoffData2;
  Month = put (Date, MONNAME.);
run;

proc print data = layoff.Layoffdata3;
run;

proc sql;
	title "Layoffs based on months";
	select Month, sum(Laid_Off_Count) as TotalCountMonth
	from layoff.LayoffData3
	where Month is not null
	group by Month
	order by TotalCountMonth desc;
quit;




