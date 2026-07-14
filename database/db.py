import mysql.connector
from mysql.connector import Error


def get_db_connection():
    """Return a new connection to the World Cup MySQL database."""

    try:
        return mysql.connector.connect(
            host="127.0.0.1",
            port=3306,
            user="worldcup_app",
            password="ChooseYourOwnPassword123!",
            database="worldcup",
        )
    except Error as error:
        print(f"Database connection failed: {error}")
        raise