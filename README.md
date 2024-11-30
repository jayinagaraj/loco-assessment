
# Loco Company Assessment - Docker and Kubernetes Setup

## Overview
This repository demonstrates how to build and deploy a Python Flask application using Docker and Kubernetes. The app will be containerized using Docker, pushed to Docker Hub, and deployed on a Kubernetes cluster using **ClusterIP** service type, with local access via **port-forwarding**.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Docker Setup](#docker-setup)
   - [Build Docker Image](#build-docker-image)
   - [Push Docker Image to Docker Hub](#push-docker-image-to-docker-hub)
3. [Kubernetes Setup](#kubernetes-setup)
   - [Create Deployment](#create-deployment)
   - [Create Horizontal Pod Autoscaler (HPA)](#create-horizontal-pod-autoscaler-hpa)
   - [Scaling Pods](#scaling-pods)
4. [Expose Application Using `kubectl port-forward`](#expose-application-using-kubectl-port-forward)
5. [Testing the Application](#testing-the-application)
6. [Conclusion](#conclusion)

---

## Prerequisites

1. **Docker**: Ensure Docker is installed and running on your machine.  
   Install Docker: [Docker Installation](https://docs.docker.com/get-docker/)
   
2. **Kubernetes**: Install Minikube, kubectl, or another Kubernetes tool.  
   Minikube Installation: [Minikube Docs](https://minikube.sigs.k8s.io/docs/)

3. **Docker Hub Account**: A Docker Hub account to push and pull Docker images.  
   Sign up: [Docker Hub](https://hub.docker.com/)

---

## Docker Setup

### **1. Build Docker Image**

To build the Docker image for the Python Flask application, follow these steps:

1. Clone the repository to your local machine.
2. Navigate to the project folder where the `Dockerfile` is located.
3. Run the following command to build the Docker image:

```bash
docker build -t nagarajjayitech/loco-assessment:latest .
```

This command builds the Docker image from the `Dockerfile` in the current directory and tags it with your Docker Hub username.

### **2. Push Docker Image to Docker Hub**

1. **Login to Docker Hub**:
   
   If you are not logged in, run:

   ```bash
   docker login
   ```

2. **Push the Image to Docker Hub**:

   After building the image, push it to Docker Hub using the following command:

   ```bash
   docker push nagarajjayitech/loco-assessment:latest
   ```

This makes the image available for pulling from any Kubernetes cluster or other Docker environments.

---

## Kubernetes Setup

### **1. Create Deployment**

1. **Create the deployment configuration file**:

   In the root of your project, navigate to the `deployment/crds/development/deployment.yaml` file for deploying the app on Kubernetes. Here's an example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loco-python-app-deployment
  namespace: loco-assessment
  labels:
    app: loco-python-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: loco-python-app
  template:
    metadata:
      labels:
        app: loco-python-app
    spec:
      containers:
        - name: loco-python-app
          image: nagarajjayitech/loco-assessment:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "200m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```

This configuration specifies that the app will run in **3 replicas** (pods) under the `loco-assessment` namespace, with a container running on port 80.

2. **Apply the deployment**:

   Run the following command to create the deployment in Kubernetes:

```bash
kubectl apply -f deployment/crds/development/deployment.yaml
```

This will deploy the Python app on your Kubernetes cluster.

### **2. Create Horizontal Pod Autoscaler (HPA)**

1. **Create the Horizontal Pod Autoscaler (HPA)** configuration file `hpa.yaml` located at `deployment/crds/hpa/hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: loco-python-app-hpa
  namespace: loco-assessment
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: loco-python-app-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

This configuration will scale the number of pods between **3 and 10** based on CPU utilization, targeting an average CPU utilization of **60%**.

2. **Apply the HPA**:

```bash
kubectl apply -f deployment/crds/hpa/hpa.yaml
```

### **3. Create Service**

1. **Create the Service configuration file** `service.yaml` located at `deployment/crds/services/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: loco-python-app-service
  namespace: loco-assessment
  labels:
    app: loco-python-app
spec:
  type: clusterIP
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: loco-python-app
  type: ClusterIP
```

This service configuration exposes the app on port 80, and the type `ClusterIP` ensures the app is only available within the Kubernetes cluster.

2. **Apply the Service**:

Run the following command to apply the service configuration:

```bash
kubectl apply -f deployment/crds/services/service.yaml
```

### **4. Scaling Pods**

To check the status of the Horizontal Pod Autoscaler and the current pod scaling, run the following command:

```bash
kubectl get hpa --namespace=loco-assessment
```

This will show the current number of replicas and the CPU utilization.

---

## Expose Application Using `kubectl port-forward`

To access the application locally on **port 80**, we will use **`kubectl port-forward`** instead of a NodePort or LoadBalancer.

1. **Expose the Service Using `ClusterIP`**:

We already defined the service in the previous step. This service is of type `ClusterIP`, and we will port-forward to access the application from the local machine.

2. **Port-Forward the Service to Localhost:80**:

Run the following command to forward the application from Kubernetes port 80 to your local port 80:

```bash
kubectl port-forward service/loco-python-app-service 80:80 --namespace=loco-assessment
```

Now, the application will be available at `http://localhost:80`.

---

## Testing the Application

1. **Access the Application**:
   - After port-forwarding, open your browser and go to `http://localhost:80`.
   - You should see the Python Flask app running.

2. **Verify Pods and Scaling**:
   - You can check the status of your pods with:

```bash
kubectl get pods --namespace=loco-assessment
```

- Check the current Horizontal Pod Autoscaler status with:

```bash
kubectl get hpa --namespace=loco-assessment
```

This will display how the pods are scaling based on CPU utilization.

---

## Conclusion

By following these steps, you have:

- Built and pushed a Docker image for your Python Flask app.
- Deployed the app on a Kubernetes cluster using **Deployments** and **Horizontal Pod Autoscalers**.
- Exposed the app using **ClusterIP** service and accessed it via **`kubectl port-forward`** on port 80.
- Configured auto-scaling to handle variable workloads based on CPU usage.

---

