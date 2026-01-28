"""
CARTO Selfhosted Architecture Diagram
"""

import os
from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.client import Users
from diagrams.k8s.compute import Pod
from diagrams.gcp.analytics import BigQuery, PubSub
from diagrams.programming.framework import React
from diagrams.saas.identity import Auth0
from diagrams.gcp.ml import AIHub
from diagrams.custom import Custom

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "output")
ICONS_DIR = os.path.join(SCRIPT_DIR, "icons")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def icon_path(name):
    for ext in [".png", ".svg"]:
        path = os.path.join(ICONS_DIR, name + ext)
        if os.path.exists(path):
            return path
    return None


def create_selfhosted_diagram():
    with Diagram(
        "CARTO Selfhosted Architecture",
        filename=os.path.join(OUTPUT_DIR, "carto_selfhosted_diagrams"),
        outformat="png",
        show=False,
        direction="TB",
        graph_attr={
            "splines": "polyline",
            "nodesep": "0.8",
            "ranksep": "1.0",
        },
    ):
        users = Users("Users")

        # CARTO Cloud
        with Cluster("CARTO Cloud "):
            auth0 = Auth0("Auth0")
            accounts_api = Pod("Accounts API")
            event_bus = PubSub("Event Bus")

        # Wrapper to keep K8s and AI Providers side by side
        with Cluster(" ", graph_attr={"style": "invis", "margin": "20"}):
            # K8s Cluster
            with Cluster("Kubernetes Cluster"):
                with Cluster("Edge"):
                    router = Pod("Router")

                with Cluster("Services"):
                    accounts_www = React("Accounts WWW")
                    workspace_www = React("Workspace WWW")
                    workspace_api = Pod("Workspace API")
                    maps_api = Pod("Maps API")
                    import_api = Pod("Import API")

                with Cluster("Workers"):
                    workspace_sub = Pod("Workspace Sub")
                    sql_worker = Pod("SQL Worker")

                with Cluster("AI Features"):
                    ai_api = Pod("AI API")
                    aiProxy = Pod("aiProxy")

            # AI Providers - external but near aiProxy
            with Cluster("AI Providers"):
                openai = Custom("OpenAI", icon_path("openai")) if icon_path("openai") else Pod("OpenAI")
                gemini = Custom("Gemini", icon_path("gemini")) if icon_path("gemini") else Pod("Gemini")
                anthropic = Custom("Anthropic", icon_path("anthropic")) if icon_path("anthropic") else Pod("Anthropic")

        # External - bottom row
        with Cluster("Data Layer"):
            postgres = PostgreSQL("PostgreSQL")
            redis = Redis("Redis")

        with Cluster("Data Warehouses"):
            bigquery = BigQuery("BigQuery")
            snowflake = Custom("Snowflake", icon_path("snowflake")) if icon_path("snowflake") else Pod("Snowflake")

        # Main flow
        users >> router >> workspace_www >> workspace_api >> postgres

        # AI connection (pulls AI Providers near aiProxy)
        aiProxy >> Edge(color="#880E4F", label="API") >> [openai, gemini, anthropic]

        # Cross connections
        accounts_www >> Edge(style="dashed", color="#4A148C") >> auth0
        accounts_www >> Edge(style="dashed", color="#0D47A1") >> accounts_api
        workspace_api >> Edge(style="dashed", color="#E65100") >> event_bus
        workspace_api >> bigquery


def main():
    print("Generating CARTO Selfhosted Architecture diagram...")
    create_selfhosted_diagram()
    print(f"Diagram generated: {OUTPUT_DIR}/carto_selfhosted_diagrams.png")


if __name__ == "__main__":
    main()
