#!/bin/bash

MODE=$1  # 操作模式：toggle / expose / unexpose

if [[ "$MODE" != "toggle" && "$MODE" != "expose" && "$MODE" != "unexpose" ]]; then
  echo "❗ 用法: $0 [toggle|expose|unexpose]"
  exit 1
fi

echo "🔍 正在查找符合规则的服务（命名以 -nodeport 或 -ingress 结尾）..."

kubectl get svc -A | grep -E '(-nodeport|-ingress)' | awk -v mode="$MODE" '
{
  namespace = $1;
  name = $2;
  type = $3;

  if (mode == "toggle") {
    next;
  }
  else if (mode == "expose" && type == "ClusterIP") {
    next;
  }
  else if (mode == "unexpose" && type == "NodePort") {
    printf("🔧 [%s/%s] %s → %s 中...\n", namespace, name, type, targetType);
    cmd = "kubectl patch svc " name " -n " namespace " -p '\''{\"spec\":{\"type\":\"" targetType "\"}}'\''";
  }
  else {
    next;
  }

  system(cmd);
}

END {
  print "✅ 操作完成。"
}
'