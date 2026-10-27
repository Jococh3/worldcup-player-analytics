# World Cup Player Analytics

A Flask application for exploring player, team, and match performance data and maintaining scouting notes. The project combines a relational MySQL database, SQL analysis, Plotly charts, and a web interface.

## What the application supports

- Dashboard totals and team/player performance charts
- Player search and position filtering
- Player detail pages with tournament and match history
- Add, edit, and delete scouting notes
- Parameterized SQL queries against a normalized relational schema

## Data flow

```text
fifa.csv → MySQL staging table → normalized tables → Flask routes and SQL queries → Plotly/Bootstrap pages
```

The SQL setup script expects the imported CSV table `worldcup.fifa_world_cup_2026_player_performance` to exist before it runs. It drops and recreates the derived application tables, while leaving that staging table in place. Review the script before running it against any database containing data you need.

## Stack

Python, Flask, MySQL, mysql-connector-python, pandas, Plotly, and Bootstrap.

## Local setup

1. Create a MySQL database named `worldcup`.
2. Import `fifa.csv` into the staging table `fifa_world_cup_2026_player_performance`.
3. Review and run `database/project_fifa.sql` to create and populate the normalized tables.
4. Create a Python virtual environment and install the requirements:

   ```bash
   python -m venv .venv
   ```

   Activate it, then run:

   ```bash
   pip install -r requirements.txt
   ```

5. Set these environment variables in your local shell or operating system. Do not store the database password in source code:

   | Variable | Purpose |
   | --- | --- |
   | `DB_HOST` | MySQL host; defaults to `127.0.0.1` |
   | `DB_PORT` | MySQL port; defaults to `3306` |
   | `DB_USER` | MySQL username |
   | `DB_PASSWORD` | MySQL password |
   | `DB_NAME` | Database name; defaults to `worldcup` |

6. Start the application:

   ```bash
   python app.py
   ```

7. Open `http://127.0.0.1:5000`.

## Project structure

- `app.py` — Flask routes, SQL queries, and Plotly chart generation
- `database/db.py` — MySQL connection configuration
- `database/project_fifa.sql` — normalized schema and application tables
- `database/application_queries.sql` — SQL queries used by the application
- `fifa.csv` — source data file included in the repository
- `templates/` — HTML pages
- `screenshots/` — interface screenshots

## Screenshots

![Dashboard overview](screenshots/Dashboard%20Prototype%201.png)

![Player details](screenshots/Player%20Details%201.png)

![Scouting notes](screenshots/Scouting%20Notes%20CRUD.png)

## Attribution and limitations

This was a team project for DSCI-D532 Applied Database Technologies at Indiana University. Joshua Cochran contributed the Flask application, dashboard, visualizations, player search, scouting-notes CRUD, and MySQL integration. Jack Williams contributed the relational database design, normalization, SQL schema, data import scripts, and ER documentation.

The repository does not currently identify the original source or license for `fifa.csv`; add that citation before redistributing the dataset. This is a local project demo: the Flask app runs with debug mode enabled and does not include authentication or production deployment hardening.
