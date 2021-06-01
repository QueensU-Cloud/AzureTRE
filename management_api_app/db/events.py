import json
import logging
from pathlib import Path

from azure.cosmos import CosmosClient, PartitionKey, DatabaseProxy
from fastapi import FastAPI

from core import config


async def connect_to_db(app: FastAPI) -> None:
    logging.debug(f"Connecting to {config.STATE_STORE_ENDPOINT}")

    try:
        cosmos_client = CosmosClient(config.STATE_STORE_ENDPOINT, config.STATE_STORE_KEY)
        app.state.cosmos_client = cosmos_client
        logging.debug("Connection established")
    except Exception as e:
        logging.debug(f"Connection to state store could not be established: {e}")

# Bootstrapping is temporary while the API does not have a register spec api implemented.


async def create_resource_specs(database: DatabaseProxy):
    """
    Creates a resource spec container if one does not exist and populate it with a canonical spec.
    :param database: DatabaseProxy for STATE_STORE_DATABASE
    :returns: None
    """
    resource_spec_file = Path('db') / "bootstrapping_data" / "resource_specs.json"
    with open(str(resource_spec_file.resolve())) as f:
        resource_specs = json.load(f)
        container_name = config.STATE_STORE_BUNDLE_SPECS_CONTAINER

        containers = list(database.query_containers(
            {
                "query": "SELECT * FROM r WHERE r.id=@id",
                "parameters": [
                    {"name": "@id", "value": container_name}
                ]
            }
        ))

        if not len(containers):
            container = database.create_container_if_not_exists(
                id=container_name,
                partition_key=PartitionKey(path="/id"),
                offer_throughput=400
            )
            for spec in resource_specs["specs"]:
                container.create_item(body=spec)


async def bootstrap_database(app: FastAPI) -> None:
    client: CosmosClient = app.state.cosmos_client
    if client:
        database_proxy = client.create_database_if_not_exists(id=config.STATE_STORE_DATABASE)
        await create_resource_specs(database_proxy)