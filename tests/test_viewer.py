import pytest
from viewer.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index_returns_html(client):
    """Index page returns 200."""
    response = client.get("/")
    assert response.status_code == 200


def test_api_experiments_returns_json(client):
    """API endpoint returns JSON list."""
    response = client.get("/api/experiments")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
