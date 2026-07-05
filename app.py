from flask import Flask, render_template, request, redirect, url_for
import pandas as pd
import plotly.express as px
import sqlite3
from datetime import datetime

app = Flask(__name__)

# Load dataset for prototype
df = pd.read_csv("fifa.csv")

# Create a local SQLite database for scouting notes
conn = sqlite3.connect("notes.db", check_same_thread=False)
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS scouting_notes (
    note_id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT,
    player_name TEXT,
    team TEXT,
    position TEXT,
    priority TEXT,
    note_text TEXT,
    created_at TEXT
)
""")

conn.commit()


@app.route("/")
def home():
    # Dashboard summary counts
    total_players = df["player_id"].nunique()
    total_teams = df["team"].nunique()
    total_matches = df["match_id"].nunique()

    # Chart 1: Top 10 teams by goals
    top_goals = (
        df.groupby("team")["goals"]
        .sum()
        .sort_values(ascending=False)
        .head(10)
        .reset_index()
    )

    goals_fig = px.bar(
        top_goals,
        x="team",
        y="goals",
        title="Top 10 Teams by Total Goals",
        labels={"team": "Team", "goals": "Total Goals"}
    )

    goals_fig.update_layout(height=500, margin=dict(l=20, r=20, t=60, b=40))
    goals_chart = goals_fig.to_html(full_html=False)

    # Chart 2: Average rating by position
    rating_by_position = (
        df.groupby("position")["player_rating"]
        .mean()
        .sort_values(ascending=False)
        .reset_index()
    )

    position_fig = px.bar(
        rating_by_position,
        x="position",
        y="player_rating",
        title="Average Player Rating by Position",
        labels={"position": "Position", "player_rating": "Average Rating"}
    )

    position_fig.update_layout(height=500, margin=dict(l=20, r=20, t=60, b=40))
    position_chart = position_fig.to_html(full_html=False)

    # Chart 3: Market value vs tournament rating
    rating_df = df[df["tournament_rating"] > 0].copy()
    rating_df["market_value_millions"] = rating_df["market_value_eur"] / 1_000_000

    market_fig = px.scatter(
        rating_df,
        x="market_value_millions",
        y="tournament_rating",
        title="Market Value vs Tournament Rating",
        labels={
            "market_value_millions": "Market Value in Millions of Euros",
            "tournament_rating": "Tournament Rating"
        },
        hover_data=["player_name", "team", "position"]
    )

    market_fig.update_layout(height=500, margin=dict(l=20, r=20, t=60, b=40))
    market_chart = market_fig.to_html(full_html=False)

    return render_template(
        "home.html",
        total_players=total_players,
        total_teams=total_teams,
        total_matches=total_matches,
        goals_chart=goals_chart,
        position_chart=position_chart,
        market_chart=market_chart
    )


@app.route("/players")
def players():
    search = request.args.get("search", "")
    position = request.args.get("position", "")

    results = df.copy()

    # Filter by player name
    if search:
        results = results[results["player_name"].str.contains(search, case=False, na=False)]

    # Filter by position
    if position:
        results = results[results["position"] == position]

    # Create one row per player for the search results
    players_table = (
        results[["player_id", "player_name", "team", "position", "age", "tournament_rating"]]
        .drop_duplicates("player_id")
        .sort_values("tournament_rating", ascending=False)
        .head(50)
        .to_dict("records")
    )

    positions = sorted(df["position"].unique())

    return render_template(
        "players.html",
        players=players_table,
        positions=positions,
        search=search,
        selected_position=position
    )


@app.route("/player/<player_id>")
def player_detail(player_id):
    # Get all rows for selected player
    player_rows = df[df["player_id"] == player_id]

    if player_rows.empty:
        return "Player not found", 404

    # Use first row for basic player info
    player = player_rows.iloc[0].to_dict()

    # Calculate summary stats
    summary = {
        "total_matches": player_rows["match_id"].nunique(),
        "total_goals": player_rows["goals"].sum(),
        "total_assists": player_rows["assists"].sum(),
        "total_minutes": player_rows["minutes_played"].sum(),
        "avg_rating": player_rows["player_rating"].mean()
    }

    # Match history table
    match_history = (
        player_rows[[
            "match_id",
            "match_date",
            "opponent_team",
            "minutes_played",
            "goals",
            "assists",
            "player_rating"
        ]]
        .sort_values(["match_date", "match_id"])
        .to_dict("records")
    )

    # Player rating line chart
    rating_history = player_rows[
        ["match_date", "match_id", "player_rating", "opponent_team"]
    ].copy()

    # Sort matches by date, then match ID
    rating_history = rating_history.sort_values(["match_date", "match_id"])

    # Create a sequential match number because the dataset can have multiple matches on the same date
    rating_history["match_number"] = range(1, len(rating_history) + 1)

    rating_fig = px.line(
        rating_history,
        x="match_number",
        y="player_rating",
        markers=True,
        title="Player Rating by Match",
        labels={
            "match_number": "Match Number",
            "player_rating": "Player Rating"
        },
        hover_data=["match_date", "match_id", "opponent_team"]
    )

    rating_fig.update_layout(height=450, margin=dict(l=20, r=20, t=60, b=40))
    rating_chart = rating_fig.to_html(full_html=False)

    return render_template(
        "player_detail.html",
        player=player,
        summary=summary,
        match_history=match_history,
        rating_chart=rating_chart
    )


@app.route("/notes")
def notes():
    players = (
        df[["player_id", "player_name", "team", "position"]]
        .drop_duplicates("player_id")
        .sort_values("player_name")
        .to_dict("records")
    )

    cursor.execute("""
        SELECT *
        FROM scouting_notes
        ORDER BY created_at DESC
    """)

    columns = [column[0] for column in cursor.description]

    notes = [
        dict(zip(columns, row))
        for row in cursor.fetchall()
    ]

    return render_template(
        "notes.html",
        players=players,
        notes=notes
    )


@app.route("/notes/add", methods=["POST"])
def add_note():
    player_id = request.form["player_id"]
    priority = request.form["priority"]
    note_text = request.form["note_text"]

    player = df[df["player_id"] == player_id].iloc[0]

    cursor.execute("""
        INSERT INTO scouting_notes
        (
            player_id,
            player_name,
            team,
            position,
            priority,
            note_text,
            created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """,
    (
        player_id,
        player["player_name"],
        player["team"],
        player["position"],
        priority,
        note_text,
        datetime.now().strftime("%Y-%m-%d %H:%M")
    ))

    conn.commit()

    return redirect(url_for("notes"))


@app.route("/notes/update/<int:note_id>", methods=["POST"])
def update_note(note_id):
    cursor.execute("""
        UPDATE scouting_notes
        SET
            priority = ?,
            note_text = ?
        WHERE note_id = ?
    """,
    (
        request.form["priority"],
        request.form["note_text"],
        note_id
    ))

    conn.commit()

    return redirect(url_for("notes"))


@app.route("/notes/delete/<int:note_id>", methods=["POST"])
def delete_note(note_id):
    cursor.execute("""
        DELETE FROM scouting_notes
        WHERE note_id = ?
    """, (note_id,))

    conn.commit()

    return redirect(url_for("notes"))


if __name__ == "__main__":
    app.run(debug=True)