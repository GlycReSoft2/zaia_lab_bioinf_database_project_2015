#!python
# From the main library, import the module for working with the
# results data structure
from glycresoft_ms2_classification import prediction_tools

n = 10

# Results storage class
PredictionResults = prediction_tools.PredictionResults

# Read in results
data = prediction_tools.prepare_model_file("../data/AGP.json")

# Get the list of column names from the data frame
columns = data.columns

complex_columns = []

# Find out if a column is non-scalar
for col_name in columns:
    if isinstance(data[col_name].ix[0], (tuple, list, dict)):
        complex_columns.append(col_name)

# Get the first n rows
print(data.ix[:n])

# Select by absolute position, not index number
print(data.sort(['MS2_Score'], ascending=False).iloc[:n])

# Print the metadata key-value store. Don't worry about this for now, but it
# could be associated with the Sample table.
print(data.metadata)

# Importing database connector library
import sqlite3
import cPickle
conn = sqlite3.connect("test.db")
# Use a nicer row object type that acts like a dictionary
conn.row_factory = sqlite3.Row

def write_to_db(frame):
    prepared_frame = data.predictions.copy()
    for col in complex_columns:
        prepared_frame[col] = prepared_frame[col].apply(cPickle.dumps)
    prepared_frame.to_sql("ms2_matches", # Database Table Name
                          conn, # Connection Object
                          ) # See http://pandas.pydata.org/pandas-docs/dev/generated/pandas.DataFrame.to_sql.html

def read_from_db(query=None):
    if query is None:
        query = "select * from ms2_matches order by MS2_Score desc limit {n};".format(**globals())
    cur = conn.execute(query)
    rows= list(map(dict, cur))
    try:
        frame = PredictionResults.prepare({}, rows)
        for col in complex_columns:
            frame[col] = frame[col].apply(lambda x: cPickle.loads(str(x)))
        return frame
    except IOError, e:
        print(e)
        return rows
try:
    write_to_db(data)
    print(read_from_db())
except:
    pass
