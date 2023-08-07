#!/usr/bin/env python
# coding: utf-8

# # Crime Analysis in Los Angeles

# ## Introduction

# This is a comprehensive Exploratory Data Analysis for the Crime in Los Angeles 2019-2023 
# 
# The purpose of this projects include:
# 
# 1. Exploring crime statistics that provide information about the dynamics of cities and the pattern of criminal activity.
# 2. Demonstrating the frequency of crimes in Los Angeles crime incidents over the years, months, and days to  identify  when or where crimes tend to occur most frequently.
# 3. Analyzing crime during the period to identify trends and patterns in criminal activity to understand crime rates increasing, decreasing, or stabilizing in different areas.
# 
#    
# 

# ## Data

# Datasouce: https://data.lacity.org/Public-Safety/Crime-Data-from-2020-to-Present/2nrs-mtv8
# 
# Records the data begin in January 1, 2019 and continue to May 6, 2023.

# ## Tool

# Jupyter Notebook and Python version3

# # 1. Data Acquisition

# ### Data Loading ##

# In[1]:


# import libraries
import pandas as pd 
import numpy as np 
import matplotlib.pyplot as plt 
import matplotlib as mpl
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')


# In[2]:


# read csv file
df = pd.read_csv("Crime_LA_2019_present.csv")


# ### Data Exploration

# In[3]:


df.head()


# In[4]:


df.shape


# In[5]:


df.columns


# In[6]:


df.info()


# In[7]:


df.describe()


# # 2. Data Preprocessing and Cleaning

# In[8]:


# Convert string 'DATE OCC' to datetime
df['DATE OCC'] = pd.to_datetime(df['DATE OCC'])

# Split 'DATE OCC' into YEAR OCC, MONTH OCC and DAY OCC
df['YEAR_OCC'] = df['DATE OCC'].dt.year
df['MONTH_OCC'] = df['DATE OCC'].dt.month
df['DAY_OCC'] = df['DATE OCC'].dt.day


# In[9]:


# Convert int 'TIME OCC' to datetime
df['TIME OCC'] = df['TIME OCC'].astype(str).str.zfill(4)
df['TIME OCC'] = pd.to_datetime(df['TIME OCC'], format = '%H%M').dt.strftime('%H:%M')


# In[10]:


# Drop column that we don't use
df.drop(['Date Rptd', 'Part 1-2', 'Mocodes', 'Crm Cd 1','Crm Cd 2', 'Crm Cd 3', 
         'Crm Cd 4', 'Cross Street', 'AREA', 'Status',  'Weapon Used Cd', 'Premis Cd', 
         'Rpt Dist No', 'Crm Cd'], axis= 1, inplace= True)


# In[11]:


# Rename the columns
df = df.rename(columns = {'DATE OCC': 'DATE_OCC', 'TIME OCC': 'TIME_OCC', 'AREA NAME': 'Area',
                          'Crm Cd Desc': 'CRM', 'Premis Desc': 'Premis','Weapon Desc': 'Weapon', 
                          'Status Desc': 'Status', 'LOCATION': 'Location','Vict Age': 'Vict_Age', 
                          'Vict Sex':'Vict_Sex','Vict Descent': 'Vict_Descent'})


# In[12]:


# Relocate the columns
df = df[['DR_NO', 'DATE_OCC', 'YEAR_OCC', 'MONTH_OCC', 'DAY_OCC', 'TIME_OCC', 'Area','CRM', 
         'Vict_Age', 'Vict_Sex', 'Vict_Descent','Premis', 'Weapon', 'Status', 'Location', 'LAT', 'LON']]
df.head()


# In[13]:


# Check the duplicates 
df.duplicated().sum()


# In[14]:


# Identify the duplicate rows
df.loc[df.duplicated()].head()


# In[15]:


# Drop duplicates
df.drop_duplicates(keep = "first" ,inplace = True)


# In[16]:


# Check the number of missing values
df.isnull().sum()


# In[17]:


# Replace missing values in columns (Vict Sex, Vict Descent, and Weapon) with the value 'Unknown'
df[['Vict_Sex', 'Vict_Descent', 'Weapon']].fillna('Unknown', inplace = True)


# In[18]:


# Check 0 and negative age values
df[df['Vict_Age'] <= 0]['Vict_Age'].value_counts()


# In[19]:


# Replace 0 and negative age values with NaN
df['Vict_Age'] = df['Vict_Age'].replace({0: np.nan, -1: np.nan, -2: np.nan, -3: np.nan, -4: np.nan})

# Replace NaN with the mean age
avg_age = df['Vict_Age'].mean()
df['Vict_Age'] = df['Vict_Age'].fillna(avg_age)


# # 3.Data Exploration and Visualization

# ### Data Exploration and Visualization

# In[20]:


# Heatmap of LA
crime_by_area_year = df.pivot_table(index='Area', columns = 'YEAR_OCC', values = 'DR_NO', aggfunc = 'count', fill_value = 0)

plt.figure(figsize = (9, 8))
sns.heatmap(crime_by_area_year, cmap = 'Blues', annot = True, fmt = 'd', cbar = True)
plt.xlabel('Year')
plt.ylabel('Neighborhood')
plt.title('Heatmap of LA Crimes')
plt.show()


# In[21]:


# Count crime in each area 
area_crime = df['Area'].value_counts()

plt.style.use('seaborn')
color = plt.cm.ocean(np.linspace(0, 2, 5))
area_crime.plot.bar(figsize = (11, 7))
plt.ylim(bottom = 20000)
plt.title('Crime by Neighborhood', fontsize = 18)
plt.xticks(rotation = 45)
plt.xlabel('')
plt.show()


# From the plot above, the top 5 neighborhoods with the most crime is Central, 77th Street, Pacific, Southwest and Hollywood.

# To summarize the crime trend for each year and area. We will examine the top 5 neighborhoods with the most crimes by filtering data that is in the top 5 neighborhoods and then grouping the data with the most crimes by YEAR OCC and Area.

# In[22]:


# Filter data that is in the top 5 areas
top5_areas = df['Area'].value_counts().nlargest(5).index
top5_areas_df = df[df['Area'].isin(top5_areas)]

# Group the data by year and area
group_df = top5_areas_df.groupby(['YEAR_OCC', 'Area']).size().reset_index(name ='Crime Count')

# Plot crimes in top 5 areas
plt.figure(figsize = (10, 6))
ax = sns.lineplot(data = group_df, x = 'YEAR_OCC', y = 'Crime Count', hue = 'Area')
ax.set_title('Trend of Crimes in Top 5 Neighborhoods', fontsize = 16)
ax.set_xlabel('Year')
ax.set_ylabel('')
plt.show()


# In[23]:


# Top 10 premise
top_premis = df['Premis'].value_counts().nlargest(10)

plt.style.use('seaborn')
color = plt.cm.ocean(np.linspace(0, 2, 5))
df['Premis'].value_counts().head(10).sort_values(ascending = True).plot.barh(figsize = (13, 8))
plt.title('10 Most Common Premis in LA', fontsize = 20)
plt.xticks()
plt.ylabel(' ')
plt.show()


# From the plots above, they show some of the most common crimes in LA and the percentage that indicate the proportion of each crime in relation to the total count of the top 5 crimes:
# 
#    1. Vehicle - Stolen 27%
#    2. Battery - Simple assault 22.1%
#    3. Burglary from vehicle 17.8%
#    4. Vandalism - Felony ($400 & over, all church vandalisms) 16.6%
#    5. Burglary 16.4%

# # 4. Temporal Analysis

# In[24]:


# Correlation Heatmap
numeric_columns = ['DR_NO', 'YEAR_OCC', 'MONTH_OCC', 'DAY_OCC', 'Vict_Age', 'LAT', 'LON']
correlation = df[numeric_columns].corr()

plt.figure(figsize=(10, 6))
sns.heatmap(correlation, annot= True, cmap = 'coolwarm')
plt.title('Correlation Heatmap', fontsize = 15)
plt.xticks(fontsize = 9)
plt.yticks(fontsize = 9)
plt.show()


# In[25]:


# Group the crime by crm and year occ
crime_counts_by_year = df.groupby(['CRM', 'YEAR_OCC']).size().reset_index(name = 'Count')

# Create a table with columns = 'CRM' and rows= 'YEAR OCC'
crime_pivot_table = crime_counts_by_year.pivot(index = 'YEAR_OCC', columns = 'CRM', values = 'Count')

# Calculate the difference for each crime
crime_diff = crime_pivot_table.diff(axis = 0)

# Show overall changes
overall_changes = crime_diff.sum(axis = 0).sort_values(ascending = False)
overall_changes.to_frame()


# The table above shows about the difference for each crime

# In[26]:


# Top increasing crimes
top_increasing_crimes = overall_changes.nlargest(5)

plt.figure(figsize=(12, 8))

# Plot the lines for increasing crimes
for col in top_increasing_crimes.index:
    plt.plot(crime_pivot_table.index.astype(int), crime_pivot_table[col], label=col)

plt.title('Trend of Top Increasing Crimes', fontsize = 18)
plt.xlabel('Year')
plt.ylabel('Number of Incidents')
plt.xticks(crime_pivot_table.index.astype(int))
plt.legend()
plt.show()


# From the plot above, we can see the trend of top increasing Crimes, it is evident that the crime of theft from motor vehicle - grand ($950.01 and over) has the highest rate of any other crime every year.

# In[27]:


# Top decreasing crimes
top_decreasing_crimes = overall_changes.nsmallest(5)

plt.figure(figsize=(10, 6))

# Plot the lines for decreasing crimes
for col in top_decreasing_crimes.index:
    plt.plot(crime_pivot_table.index.astype(int), crime_pivot_table[col], label=col)

# Set title and labels
plt.title('Trend of Top Decreasing Crimes', fontsize = 18)
plt.xlabel('Year')
plt.ylabel('Number of Incidents')
plt.xticks(crime_pivot_table.index.astype(int))
plt.legend()
plt.show()


# From the plot above, it shows the trend of top 5 decreasing crimes:
# 
#    1. Burglary from vehicle
#    2. Battery - simple assault
#    3. Theft plain - petty ($950 & under)
#    4. Intimate partner - simple assault
#    
#    5. Vadalism - felony ($400 & over, all church vandalisms)

# In[28]:


# Crime rate per year
crime_per_year = df['YEAR_OCC'].value_counts().sort_index()

plt.figure(figsize = (10, 6))
plt.plot(crime_per_year.index.astype(int), crime_per_year.values, marker = 'o', linestyle = '-', color = 'blue')
plt.title('Crime Rate Over the Years')
plt.xlabel('YEAR OCC')
plt.ylabel('Number of Incidents')
plt.xticks(crime_per_year.index.astype(int))
plt.show()


# From the above graph shows the trend of crime occurrences over the years that occur in each year. And the most common crimes were committed in 2022.

# In[29]:


# The average number of crimes per month for each year
avg_crime = df.groupby([df['YEAR_OCC'], df['MONTH_OCC']]).size()
avg_crime_per_month = avg_crime.groupby(level= 0).mean().round(2)

plt.figure(figsize = (10, 6))
plt.plot(avg_crime_per_month.index.astype(int), avg_crime_per_month.values, marker = 'o', linestyle = '-', color = 'blue')
plt.title('The Average Monthly Crime Rate for Each Year', size = 14)
plt.xlabel('YEAR')
plt.ylabel('Average of Incidents')
plt.xticks(avg_crime_per_month.index.astype(int))
plt.show()


# According to the graph showing the average monthly crimes of each year. By 2022, crimes per month were 19,454 times. And in 2023 is the lowest average monthly crime occurrence with 15,607 times (The 2023 data is calculated from January to May 6).

# In[30]:


# Extract the month from the 'DATE OCC' column
df['Month'] = pd.to_datetime(df['DATE_OCC']).dt.month

months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
df['Month'] = pd.Categorical(df['Month'], categories = range(1, 13), ordered = True).map(lambda x: months[x-1])

crimes_by_month = df['Month'].value_counts().sort_index()

# Create gradient colormap
cmap = plt.get_cmap('viridis')
colors = cmap(np.linspace(0, 1, len(crimes_by_month)))

plt.figure(figsize = (9, 7))
plt.bar(crimes_by_month.index, crimes_by_month.values, color = colors)
plt.title('Number of Crimes by Month')
plt.xlabel('Month')
plt.ylabel('Number of Crimes')
plt.ylim(bottom = 50000)
plt.show()


# The months with the highest crime are January, May, March and the months with the least crime are November, December and September.

# In[31]:


# Extract the month from the 'DATE OCC' column
df['Month'] = pd.to_datetime(df['DATE_OCC']).dt.month

df['Season'] = pd.cut(df['Month'], bins = [0, 3, 6, 9, 12], labels = ['Winter', 'Spring', 'Summer', 'Fall'])

crimes_by_season = df['Season'].value_counts().sort_index()

plt.bar(crimes_by_season.index, crimes_by_season.values)
plt.title('Crimes by Season')
plt.xlabel('Season')
plt.ylabel('Number of Crimes')
plt.ylim(bottom = 150000)
plt.show()


# From the graph above shows the peak crime season is winter.

# In[32]:


# KDE
col = sns.color_palette()

plt.figure(figsize = (10, 6))
data = df.groupby('DATE_OCC').count().iloc[ :, 0]
sns.kdeplot(data = data, shade = True)
plt.axvline(x = data.median(), ymax = 0.95, linestyle = '--', color = col[1])
plt.annotate(
    'Median: ' + str(data.median()),
    xy = (data.median(), 0.004),
    xytext = (200, 0.005),
    arrowprops = dict(arrowstyle = '->', color = col[1], shrinkB = 10))
plt.title(
    'Distribution of number of crimes per day', fontdict = {'fontsize': 16})
plt.xlabel('Crimes')
plt.ylabel('Density')
plt.show()


# The "Distribution of number of crimes per day" indicates that there are 579 crimes committed in Los Angeles on average per day.

# In[33]:


# Extract the weekday from the 'DATE OCC' column
df['Weekday'] = pd.to_datetime(df['DATE_OCC']).dt.weekday

weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
df['Weekday'] = pd.Categorical(df['Weekday'], categories = range(7), ordered = True).map(lambda x: weekdays[x])

crimes_by_weekday = df['Weekday'].value_counts().sort_index()

# Create gradient colormap
cmap = plt.get_cmap('viridis')
colors = cmap(np.linspace(0, 1, len(crimes_by_weekday)))

plt.figure(figsize = (9, 7))
plt.bar(crimes_by_weekday.index, crimes_by_weekday.values, color = colors)
plt.title('Number of Crimes by Weekday')
plt.xlabel('Weekday')
plt.ylabel('Number of Crimes')
plt.ylim(bottom = 100000)
plt.show()


# According to the plot, it shows the top 3 days with the most crimes are Friday, Saturday and Wednesday

# In[34]:


df['Hour'] = pd.to_datetime(df['TIME_OCC']).dt.hour


# In[35]:


plt.figure(figsize=(16,8))
plt.subplot(1,2,1)
sns.distplot(df['Hour'])
plt.show()


# In[36]:


# Count the number of crimes by hour
crime_counts_by_hour = df['Hour'].value_counts().sort_index()

plt.plot(crime_counts_by_hour.index, crime_counts_by_hour.values)
plt.title('Trend of Crime by Hour')
plt.xlabel('Hour')
plt.ylabel('Number of Incidents')
plt.xticks(range(24))
plt.show()


# From the plot, the time when crime is most often committed is 12:00 noon.
