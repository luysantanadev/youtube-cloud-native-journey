# Namespace
kubectl create namespace monitoring

# Repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm search repo grafana/alloy
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --values .\\scripts\\05.01-kube-prometheus-stack.yaml `
  --wait

helm upgrade --install loki grafana-community/loki `
  --namespace monitoring `
  --values .\\scripts\\05.02-loki.yaml `
  --wait

helm upgrade --install tempo grafana-community/tempo-distributed `
  --namespace monitoring `
  --values .\scripts\05.03-tempo.yaml `
  --wait

helm upgrade --install pyroscope grafana/pyroscope `
  --namespace monitoring `
  --values .\\scripts\\05.04-pyroscope.yaml `
  --wait

helm upgrade --install alloy grafana/alloy `
  --namespace monitoring `
  --values .\\scripts\\05.05-alloy.yaml `
  --wait

kubectl apply -f .\\scripts\\05.06-grafana-datasource.yaml

kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &