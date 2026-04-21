

import pandas as pd, glob, pyodbc,sqlalchemy;

path = r"D:\Git\SQL\SQL_PROJECTS\Brazilian E-Commerce Public Dataset by Olist\Raw_data\*.csv"

# Getting list of csv files in the folder.
csv_files = glob.glob(path)

# Loading each csv file into a dictionary.
dataframes = {file.split('\\')[-1]: pd.read_csv(file) for file in csv_files};

print(dataframes.keys());

# Loading into SQL server

from sqlalchemy import create_engine

# Inserting credentials
server = r'(localdb)\Local'
database = 'Olist_Ecommerce'

# Windows Authentication connection
engine = create_engine(
    f"mssql+pyodbc://@{server}/{database}"
    f"?driver=ODBC+Driver+17+for+SQL+Server"
    f"&Trusted_Connection=yes"
);

# Loading into SQL server

for table_name, df in dataframes.items():
    table_name_sql = table_name.replace('.csv', '').lower()
    df.to_sql(name=table_name_sql, con=engine, if_exists='replace', index=False)
    print(f"{table_name_sql} inserted successfully");