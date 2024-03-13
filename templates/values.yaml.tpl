installCRDs: true

redis-ha:
  enabled: false

server:
  ingress:
    enabled: ${ argocd_ingress_enabled }
    annotations:
      kubernetes.io/ingress.class: ${ argocd_ingress_class }
      kubernetes.io/tls-acme: "${ argocd_ingress_tls_acme_enabled }"
      nginx.ingress.kubernetes.io/ssl-passthrough: "${ argocd_ingress_ssl_passthrough_enabled }"
    hosts:
      - ${ argocd_server_host }
    tls:
      - secretName: argocd-secret
        hosts:
          - ${ argocd_server_host }

server:    
  service:    
    type: NodePort    
    nodePortHttp: 31080    
    
    
params:
  server.insecure: true
