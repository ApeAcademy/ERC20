import pytest


@pytest.fixture
def owner(accounts):
    return accounts[0]


@pytest.fixture
def token(owner, project):
    return owner.deploy(project.{{cookiecutter.smart_contract_file_name}})
