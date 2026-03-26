from flask import Flask
from markupsafe import Markup

app = Flask(__name__)


@app.route("/")
def hello():
    greeting = Markup("<strong>Hello, World!</strong>")
    return f"<html><body>{greeting}</body></html>"


if __name__ == "__main__":
    app.run(debug=True)
