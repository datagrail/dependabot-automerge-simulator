def test_arithmetic():
    assert 1 + 1 == 2


def test_string():
    assert "hello".upper() == "HELLO"


def test_hello_route():
    from app import app

    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert b"Hello" in response.data
