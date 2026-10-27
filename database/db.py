import os

import mysql.connector
from mysql.connector import Error


def get_db_connection():
    """Return a new connection to the World Cup MySQL database."""

    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")

    if not user or not password:
        raise RuntimeError(
            "Set the DB_USER and DB_PASSWORD environment variables before "
            "connecting to the World Cup database."
        )

    try:
        return mysql.connector.connect(
            host=os.getenv("DB_HOST", "127.0.0.1"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=user,
            password=password,
            database=os.getenv("DB_NAME", "worldcup"),
        )
    except Error as error:
        print(f"Database connection failed: {error}")
        raise
