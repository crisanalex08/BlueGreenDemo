
#### git: [BlueGreenDemo](https://dev.azure.com/virgilcrisan/CCIT-DevOps/_git/BlueGreenDemo.git)
## What this demonstrates


- Blue/Green deployment using Azure Container Apps revisions

- Zero downtime rollout (stable revision remains active during candidate validation

- Automated rollback when deployment health verification fails

- CI/CD on Azure DevOps Pipelines
## Tech Stack


- .NET 10 Minimal API

- Docker

- Azure Container Apps (multiple revisions mode)

- Azure Container Registry (ACR)

- Azure DevOps (Azure Repos + Azure Pipelines)

## Project Structure

- src/BlueGreenApi: Minimal API source code

- Dockerfile: Multi-stage container build

- .dockerignore: Docker context optimization

- azure-pipelines.yml: Build, deploy, verify, switch, rollback pipeline

- scripts/aca-traffic.ps1: Revision and traffic inspection helper (Windows)

## Application Endpoints

### GET /

Returns deployment metadata:


```json
{
  "version": "v1",
  "environment": "blue",
  "status": "healthy",
  "timestamp": "2026-05-15T10:20:30.0000000Z"
}
```
### GET /health

- Returns HTTP 200 with `Healthy` when `FAIL_HEALTHCHECK=false`
- Returns HTTP 500 with `Unhealthy` when `FAIL_HEALTHCHECK=true`

This endpoint is used for:
- deployment verification in CI/CD
- rollback simulation
## Architecture

1. Azure Pipelines builds and pushes a new image to ACR.
2. Pipeline deploys a new Azure Container Apps revision (green candidate).
3. Existing stable revision (blue) stays active while candidate is validated.
4. Pipeline calls candidate revision root endpoint `/` and validates JSON status.
5. If healthy: traffic switches to the new revision.
6. If unhealthy: traffic rolls back to previous stable revision and pipeline fails.


## Demo
I am using an windows agent that runs locally.
We have an active revision in container app.

``` powershell
PS D:\Masters\DevOps\BlueGreenDemo> .\scripts\aca-traffic.ps1 -ResourceGroup crisan-devops -ContainerAppName crisan-bluegreen-ca

Active revisions:
Name                      Active    Created
------------------------  --------  -------------------------
crisan-bluegreen-ca--r74  True      2026-05-15T21:48:26+00:00

Traffic weights:
RevisionName              Weight
------------------------  --------
crisan-bluegreen-ca--r74  100
```

Response from the app root endpoint:
``` json
{
  "version": "1.0.0",
  "environment": "blue",
  "status": "healthy",
  "timestamp": "2026-05-15T21:49:27.3426767Z"
}
```
### Scenario 1 : Successful deploy  (build nr: #20260515.45)
I will run the pipeline with version: 2.0.0 
![[Pasted image 20260516005057.png]]

After the deploy is done we can see that now we the container app has revisions and all the traffic is routed to 'crisan-bluegreen-ca--r75' which is the latest one

``` powershell
PS D:\Masters\DevOps\BlueGreenDemo> .\scripts\aca-traffic.ps1 -ResourceGroup crisan-devops -ContainerAppName crisan-bluegreen-ca

Active revisions:
Name                      Active    Created
------------------------  --------  -------------------------
crisan-bluegreen-ca--r74  True      2026-05-15T21:48:26+00:00
crisan-bluegreen-ca--r75  True      2026-05-15T21:52:04+00:00

Traffic weights:
RevisionName              Weight
------------------------  --------
crisan-bluegreen-ca--r75  100
```

Response from the app root endpoint:
```json
{
  "version": "2.0.0",
  "environment": "green",
  "status": "healthy",
  "timestamp": "2026-05-15T21:53:32.9982571Z"
}
```
### Scenario 2 : Failed deploy (build nr: #20260515.46)
![[Pasted image 20260516005434.png]]
```powershell
PS D:\Masters\DevOps\BlueGreenDemo> .\scripts\aca-traffic.ps1 -ResourceGroup crisan-devops -ContainerAppName crisan-bluegreen-ca

Active revisions:
Name                      Active    Created
------------------------  --------  -------------------------
crisan-bluegreen-ca--r74  True      2026-05-15T21:48:26+00:00
crisan-bluegreen-ca--r75  True      2026-05-15T21:52:04+00:00
crisan-bluegreen-ca--r76  True      2026-05-15T21:55:58+00:00

Traffic weights:
RevisionName              Weight
------------------------  --------
crisan-bluegreen-ca--r75  100
```

Response from the root endpoint:
``` json
{
  "version": "2.0.0",
  "environment": "green",
  "status": "healthy",
  "timestamp": "2026-05-15T21:57:27.9077262Z"
}
```

Response from  root endpoint (crisan-bluegreen-ca--r76):
``` json
{
  "version": "2.1.0",
  "environment": "blue",
  "status": "unhealthy",
  "timestamp": "2026-05-15T21:58:34.5033453Z"
}
```

Because the latest deploy was not healthy, the pipeline rolled back to the previous one (2.0.0). 
