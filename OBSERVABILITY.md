# Observability Guide (Metrics & Logging)

This guide explains how to access and use the centralized logging and metrics stack deployed in the Courtmate Kubernetes cluster.

## 1. Overview

The observability stack consists of:
- **Fluentd**: Collects logs from all services (User, Court, Booking) and standardizes them into JSON.
- **Prometheus**: Scrapes metrics (`/metrics`) from services.
- **Grafana**: Visualizes metrics with pre-configured dashboards.

## 2. Accessing Dashboards (Grafana)

Grafana provides visual dashboards for service health and performance.

- **URL**: [http://localhost:30092](http://localhost:30092)
- **Default Credentials**: `admin` / `admin`

### Available Dashboards
Navigate to **Dashboards** > **Courtmate Services**. Key metrics include:
- **Request Rate**: Requests per second per service.
- **Response Time (p95)**: 95th percentile latency (performance indicator).
- **Error Rate**: Percentage of failed requests (HTTP 5xx).

## 3. Querying Raw Metrics (Prometheus)

Prometheus allows you to run PromQL queries on raw data.

- **URL**: [http://localhost:30091](http://localhost:30091)

### Useful Queries
- **Request Rate per Service (last 5m)**:
  ```promql
  sum(rate(http_requests_total[5m])) by (service)
  ```
- **Error Rate per Service**:
  ```promql
  sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
  ```

## 4. Viewing Logs (Fluentd)

We use a lightweight Fluentd setup that aggregates logs from all pods. Logs are formatted as structured JSON.

### View Aggregated Logs
To see logs from **all services** in one stream:
```bash
kubectl logs -n monitoring -l app=fluentd -f
```

### View Individual Service Logs
You can still view logs for specific services using standard kubectl commands. They will now be in JSON format:

```bash
# User Service
kubectl logs -l app=user-service -f

# Court Service
kubectl logs -l app=court-service -f

# Booking Service
kubectl logs -l app=booking-service -f
```

## 5. Troubleshooting through Observability

1. **Check Grafana** "Error Rate" panel to see if any service is spiking in errors.
2. **Check "Response Time"** to see if a service is slow.
3. If errors are found, open a terminal and **tail the Fluentd logs** to see the specific error messages and stack traces in real-time.
