# --- Part E: Populate Database --- 
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---

pacman::p_load(DBI, RMariaDB, RSQLite)


# Load CSV data into a data frame
df.data <-  read.csv("small-restaurant-visits-209874.csv")

# Load SQLite data into data frames
conn <- dbConnect(SQLite(), "restaurants-db-02102026.sqlitedb")
df.restaurants <- dbReadTable(conn, 'restaurants')
df.servers <- dbReadTable(conn, 'servers')
