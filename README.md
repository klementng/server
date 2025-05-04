# Self-Hosted Server Docker Setup

This repository contains my personal single system self-hosted server setup managed using Docker. It uses a modular folder structure, containing a collection of self-contained app configs and a custom script (compose.sh) to manage docker compose workflows.

## Overview

* **`app/`** – Standalone apps stack, each in its own YAML file.
* **`arr/`** – The *Arr Stack* and related media management utilities.
* **`sys/`** – System-level services for monitoring, backups, networking, security, and web services.
* **`.env`** – configure en
* **`app.yaml`** – Central configuration for app stack
* **`arr.yaml`** – Central configuration for arr stack
* **`sys.yaml`** – Central configuration for sys stack
* **`compose.sh`** – Custom script to manage Docker Compose deployments.

---

## Folder Structure

The server is structured with a root docker folder and 3 subfolder: compose, data and storage as follows:
```
├── /                  
│   ├── /docker/          
│   │   ├── /docker/compose <-- this repo
│   │   ├── /docker/data    <-- databases, configurations
│   │   ├── /docker/storage <-- media
```

## Disclaimer
This configuration is designed for myself and hobby use. Use with caution and edit configuration as needed for your use cases.