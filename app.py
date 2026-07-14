from flask import Flask, render_template, request, redirect, url_for
import pandas as pd
import plotly.express as px

from database.db import get_db_connection


app = Flask(__name__)


def fetch_all(query, params=None):
    """Run a SELECT query and return every row as a dictionary."""

    connection = get_db_connection()

    if connection is None:
        raise ConnectionError("Unable to connect to the MySQL database.")

    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(query, params or ())
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


def fetch_one(query, params=None):
    """Run a SELECT query and return one row as a dictionary."""

    connection = get_db_connection()

    if connection is None:
        raise ConnectionError("Unable to connect to the MySQL database.")

    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(query, params or ())
        return cursor.fetchone()
    finally:
        cursor.close()
        connection.close()


def execute_change(query, params=None):
    """Run an INSERT, UPDATE, or DELETE query."""

    connection = get_db_connection()

    if connection is None:
        raise ConnectionError("Unable to connect to the MySQL database.")

    cursor = connection.cursor()

    try:
        cursor.execute(query, params or ())
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


@app.route("/")
def home():
    # Get dashboard totals
    totals = fetch_one(
        """
        SELECT
            (SELECT COUNT(*) FROM players) AS total_players,
            (SELECT COUNT(*) FROM teams) AS total_teams,
            (SELECT COUNT(*) FROM matches) AS total_matches
        """
    )

    # Top 10 teams by total goals
    top_goals = fetch_all(
        """
        SELECT
            t.team_name AS team,
            SUM(pms.goals) AS goals
        FROM player_match_stats AS pms
        JOIN players AS p
            ON pms.player_id = p.player_id
        JOIN teams AS t
            ON p.team_id = t.team_id
        GROUP BY
            t.team_id,
            t.team_name
        ORDER BY
            goals DESC
        LIMIT 10
        """
    )

    top_goals_df = pd.DataFrame(top_goals)

    goals_fig = px.bar(
        top_goals_df,
        x="team",
        y="goals",
        title="Top 10 Teams by Total Goals",
        labels={
            "team": "Team",
            "goals": "Total Goals",
        },
    )

    goals_fig.update_layout(
        height=500,
        margin=dict(l=20, r=20, t=60, b=40),
    )

    goals_chart = goals_fig.to_html(
        full_html=False,
        include_plotlyjs="cdn",
    )

    # Average player rating by position
    rating_by_position = fetch_all(
        """
        SELECT
            p.position,
            ROUND(AVG(pms.player_rating), 2) AS player_rating
        FROM player_match_stats AS pms
        JOIN players AS p
            ON pms.player_id = p.player_id
        GROUP BY
            p.position
        ORDER BY
            player_rating DESC
        """
    )

    rating_by_position_df = pd.DataFrame(rating_by_position)

    position_fig = px.bar(
        rating_by_position_df,
        x="position",
        y="player_rating",
        title="Average Player Rating by Position",
        labels={
            "position": "Position",
            "player_rating": "Average Rating",
        },
    )

    position_fig.update_layout(
        height=500,
        margin=dict(l=20, r=20, t=60, b=40),
    )

    position_chart = position_fig.to_html(
        full_html=False,
        include_plotlyjs=False,
    )

    # Market value compared with tournament rating
    market_ratings = fetch_all(
        """
        SELECT
            p.player_name,
            t.team_name AS team,
            p.position,
            p.market_value_eur / 1000000.0 AS market_value_millions,
            pts.tournament_rating
        FROM players AS p
        JOIN teams AS t
            ON p.team_id = t.team_id
        JOIN player_tournament_stats AS pts
            ON p.player_id = pts.player_id
        WHERE
            pts.tournament_rating > 0
        """
    )

    market_ratings_df = pd.DataFrame(market_ratings)

    market_fig = px.scatter(
        market_ratings_df,
        x="market_value_millions",
        y="tournament_rating",
        title="Market Value vs Tournament Rating",
        labels={
            "market_value_millions": "Market Value in Millions of Euros",
            "tournament_rating": "Tournament Rating",
        },
        hover_data=[
            "player_name",
            "team",
            "position",
        ],
    )

    market_fig.update_layout(
        height=500,
        margin=dict(l=20, r=20, t=60, b=40),
    )

    market_chart = market_fig.to_html(
        full_html=False,
        include_plotlyjs=False,
    )

    return render_template(
        "home.html",
        total_players=totals["total_players"],
        total_teams=totals["total_teams"],
        total_matches=totals["total_matches"],
        goals_chart=goals_chart,
        position_chart=position_chart,
        market_chart=market_chart,
    )


@app.route("/players")
def players():
    search = request.args.get("search", "").strip()
    position = request.args.get("position", "").strip()

    query = """
        SELECT
            p.player_id,
            p.player_name,
            t.team_name AS team,
            p.position,
            p.age,
            pts.tournament_rating
        FROM players AS p
        JOIN teams AS t
            ON p.team_id = t.team_id
        LEFT JOIN player_tournament_stats AS pts
            ON p.player_id = pts.player_id
        WHERE 1 = 1
    """

    params = []

    if search:
        query += " AND p.player_name LIKE %s"
        params.append(f"%{search}%")

    if position:
        query += " AND p.position = %s"
        params.append(position)

    query += """
        ORDER BY
            pts.tournament_rating DESC,
            p.player_name
        LIMIT 50
    """

    players_table = fetch_all(query, tuple(params))

    position_rows = fetch_all(
        """
        SELECT DISTINCT position
        FROM players
        WHERE position IS NOT NULL
        ORDER BY position
        """
    )

    positions = [
        row["position"]
        for row in position_rows
    ]

    return render_template(
        "players.html",
        players=players_table,
        positions=positions,
        search=search,
        selected_position=position,
    )


@app.route("/player/<player_id>")
def player_detail(player_id):
    # Basic player information
    player = fetch_one(
        """
        SELECT
            p.player_id,
            p.player_name,
            p.age,
            p.nationality,
            t.team_name AS team,
            p.jersey_number,
            p.position,
            p.height_cm,
            p.weight_kg,
            p.preferred_foot,
            p.club_name,
            p.market_value_eur,
            pts.tournament_rating
        FROM players AS p
        JOIN teams AS t
            ON p.team_id = t.team_id
        LEFT JOIN player_tournament_stats AS pts
            ON p.player_id = pts.player_id
        WHERE
            p.player_id = %s
        """,
        (player_id,),
    )

    if player is None:
        return "Player not found", 404

    # Summary statistics
    summary = fetch_one(
        """
        SELECT
            COUNT(DISTINCT match_id) AS total_matches,
            COALESCE(SUM(goals), 0) AS total_goals,
            COALESCE(SUM(assists), 0) AS total_assists,
            COALESCE(SUM(minutes_played), 0) AS total_minutes,
            COALESCE(AVG(player_rating), 0) AS avg_rating
        FROM player_match_stats
        WHERE
            player_id = %s
        """,
        (player_id,),
    )

    # Match history
    match_history = fetch_all(
        """
        SELECT
            pms.match_id,
            m.match_date,
            pms.opponent_team,
            pms.minutes_played,
            pms.goals,
            pms.assists,
            pms.player_rating
        FROM player_match_stats AS pms
        JOIN matches AS m
            ON pms.match_id = m.match_id
        WHERE
            pms.player_id = %s
        ORDER BY
            m.match_date,
            pms.match_id
        """,
        (player_id,),
    )

    # Prepare the rating chart
    rating_history = pd.DataFrame(match_history)

    if not rating_history.empty:
        rating_history["match_number"] = range(
            1,
            len(rating_history) + 1,
        )

        rating_fig = px.line(
            rating_history,
            x="match_number",
            y="player_rating",
            markers=True,
            title="Player Rating by Match",
            labels={
                "match_number": "Match Number",
                "player_rating": "Player Rating",
            },
            hover_data=[
                "match_date",
                "match_id",
                "opponent_team",
            ],
        )

        rating_fig.update_layout(
            height=450,
            margin=dict(l=20, r=20, t=60, b=40),
        )

        rating_chart = rating_fig.to_html(
            full_html=False,
            include_plotlyjs="cdn",
        )
    else:
        rating_chart = "<p>No match data is available for this player.</p>"

    return render_template(
        "player_detail.html",
        player=player,
        summary=summary,
        match_history=match_history,
        rating_chart=rating_chart,
    )


@app.route("/notes")
def notes():
    # Players used in the Add Note dropdown
    player_options = fetch_all(
        """
        SELECT
            p.player_id,
            p.player_name,
            t.team_name AS team,
            p.position
        FROM players AS p
        JOIN teams AS t
            ON p.team_id = t.team_id
        ORDER BY
            p.player_name
        """
    )

    # Existing scouting notes
    saved_notes = fetch_all(
        """
        SELECT
            sn.note_id,
            sn.player_id,
            p.player_name,
            t.team_name AS team,
            p.position,
            sn.priority,
            sn.note_text,
            sn.created_date AS created_at
        FROM scouting_notes AS sn
        JOIN players AS p
            ON sn.player_id = p.player_id
        JOIN teams AS t
            ON p.team_id = t.team_id
        ORDER BY
            sn.created_date DESC,
            sn.note_id DESC
        """
    )

    return render_template(
        "notes.html",
        players=player_options,
        notes=saved_notes,
    )


@app.route("/notes/add", methods=["POST"])
def add_note():
    player_id = request.form["player_id"]
    priority = request.form["priority"]
    note_text = request.form["note_text"].strip()

    if note_text:
        execute_change(
            """
            INSERT INTO scouting_notes (
                player_id,
                note_text,
                priority
            )
            VALUES (%s, %s, %s)
            """,
            (
                player_id,
                note_text,
                priority,
            ),
        )

    return redirect(url_for("notes"))


@app.route("/notes/update/<int:note_id>", methods=["POST"])
def update_note(note_id):
    execute_change(
        """
        UPDATE scouting_notes
        SET
            priority = %s,
            note_text = %s
        WHERE
            note_id = %s
        """,
        (
            request.form["priority"],
            request.form["note_text"].strip(),
            note_id,
        ),
    )

    return redirect(url_for("notes"))


@app.route("/notes/delete/<int:note_id>", methods=["POST"])
def delete_note(note_id):
    execute_change(
        """
        DELETE FROM scouting_notes
        WHERE note_id = %s
        """,
        (note_id,),
    )

    return redirect(url_for("notes"))


if __name__ == "__main__":
    app.run(debug=True)