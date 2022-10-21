import pytest


@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def receiver(accounts):
    return accounts[1]
@pytest.fixture(scope="session")
def asset(owner, project):
    return owner.deploy(...)
@pytest.fixture(scope="session")
def token(owner, project, asset):
    return owner.deploy(project.Token, asset)

