#!/usr/bin/env python3
"""
CARTO Selfhosted Architecture Diagram Generator

Uses Mingrammer Diagrams library to generate architecture diagrams
for the CARTO Selfhosted Helm deployment.

Usage:
    python generate_architecture.py

Output:
    carto_selfhosted.png - Complete selfhosted architecture
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.k8s.compute import Deployment, Pod, Job
from diagrams.k8s.network import Ingress, Service
from diagrams.k8s.storage import PersistentVolumeClaim
from diagrams.k8s.infra import Node
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.client import Users
from diagrams.onprem.network import Nginx
from diagrams.gcp.analytics import BigQuery
from diagrams.aws.analytics import Redshift
from diagrams.custom import Custom


def generate_selfhosted_architecture():
    """Generate CARTO Selfhosted architecture diagram."""

    graph_attr = {
        "fontsize": "18",
        "bgcolor": "white",
        "pad": "0.5",
        "splines": "spline",
    }

    with Diagram(
        "CARTO Selfhosted Architecture",
        show=False,
        direction="TB",
        filename="carto_selfhosted",
        graph_attr=graph_attr,
    ):
        users = Users("Users")

        with Cluster("Kubernetes Cluster"):

            with Cluster("Ingress Layer"):
                router = Deployment("router")
                ingress = Ingress("Ingress Controller")

            with Cluster("Frontend"):
                workspace_www = Deployment("workspace-www")
                accounts_www = Deployment("accounts-www")

            with Cluster("API Services"):
                workspace_api = Deployment("workspace-api")
                accounts_api = Deployment("accounts-api")
                maps_api = Deployment("maps-api")
                import_api = Deployment("import-api")
                lds_api = Deployment("lds-api")
                sql_worker = Deployment("sql-worker")

            with Cluster("Background Services"):
                notifier = Deployment("notifier")
                workflows = Deployment("workflows-api")
                cdn_invalidator = Deployment("cdn-invalidator-sub")

            with Cluster("Data Layer"):
                with Cluster("PostgreSQL"):
                    postgres = PostgreSQL("PostgreSQL")
                    accounts_db = Pod("accounts-db")
                    workspace_db = Pod("workspace-db")

                redis = Redis("Redis")

            with Cluster("Storage"):
                gcs_proxy = Deployment("gcs-proxy")
                http_cache = Deployment("http-cache")
                pvc = PersistentVolumeClaim("imports-pvc")

        with Cluster("External Data Warehouses"):
            bq = BigQuery("BigQuery")
            # Placeholder for other warehouses
            redshift = Redshift("Redshift")

        # Connections - User flow
        users >> ingress >> router

        # Router to frontends
        router >> workspace_www
        router >> accounts_www

        # Router to APIs
        router >> workspace_api
        router >> accounts_api
        router >> maps_api
        router >> import_api
        router >> lds_api

        # Frontend to API
        workspace_www >> workspace_api
        accounts_www >> accounts_api

        # API to databases
        accounts_api >> postgres
        workspace_api >> postgres
        workspace_api >> redis

        # Maps flow
        maps_api >> redis
        maps_api >> http_cache

        # Import flow
        import_api >> pvc
        import_api >> gcs_proxy

        # SQL Worker
        sql_worker >> postgres
        sql_worker >> Edge(label="query") >> bq

        # Background services
        workspace_api >> notifier
        workspace_api >> workflows


if __name__ == "__main__":
    print("Generating CARTO Selfhosted architecture diagram...")
    generate_selfhosted_architecture()
    print("Done!")
