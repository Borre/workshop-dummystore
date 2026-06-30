#!/bin/bash
# push-to-codearts.sh — Push cada app a su repo en CodeArts
# Ejecutar desde el repo local
# Requiere: credenciales SSH configuradas para codehub.devcloud

set -euo pipefail

BASE="/home/eduardo/dev/workshop-dummystore"
PROJECT="7fd3980908274cf0993b41c42f291411"
REMOTE="git@codehub.devcloud.la-north-2.huaweicloud.com:${PROJECT}"

echo "=== Push a CodeArts Repos ==="

push_subtree() {
    local app=$1
    local path=$2
    local branch="main"
    
    echo ""
    echo "▶  Pusheando $app..."
    
    # Check if repo has content
    git ls-remote --exit-code "${REMOTE}/${app}.git" HEAD > /dev/null 2>&1 && HAS_CONTENT=true || HAS_CONTENT=false
    
    if [ "$HAS_CONTENT" = false ]; then
        cd "$BASE"
        # Push the specific subdirectory as root to the remote
        git subtree push --prefix="${path}" "${REMOTE}/${app}.git" ${branch} 2>&1 || {
            echo "  ⚠️  git subtree push falló, intentando split + push..."
            # Alternative: use git filter-repo or manual push
            mkdir -p /tmp/codearts-push/${app}
            cp -r "${BASE}/${path}"/* /tmp/codearts-push/${app}/ 2>/dev/null || true
            cp "${BASE}/${path}"/.* /tmp/codearts-push/${app}/ 2>/dev/null || true
            cd /tmp/codearts-push/${app}
            git init
            git add -A
            git commit -m "Initial commit: ${app}"
            git remote add origin "${REMOTE}/${app}.git"
            git push -u origin main 2>&1 || echo "  ❌ Push failed for ${app}"
        }
        echo "  ✅ ${app} pushed"
    else
        echo "  ⚠️  Repo ya tiene contenido, saltando..."
    fi
}

# push_subtree "gateway-api" "apps/gateway-api"
# push_subtree "catalog-api" "apps/catalog-api"
# push_subtree "orders-api" "apps/orders-api"
# push_subtree "web-ui" "apps/web-ui"
# push_subtree "functiongraph-demo" "apps/functiongraph-demo"

echo ""
echo "⚠️  Para pushear necesitas configurar SSH key en CodeArts:"
echo "  1. Generar SSH key: ssh-keygen -t ed25519 -f ~/.ssh/codearts"
echo "  2. Agregar a CodeArts: https://devcloud.la-north-2.huaweicloud.com/codearts/settings/sshkeys"
echo "  3. ssh-add ~/.ssh/codearts"
echo ""
echo "  Luego descomentar las lineas de push_subtree arriba"
echo "  O pushear manual desde cada carpeta:"
for app in gateway-api catalog-api orders-api web-ui functiongraph-demo; do
    echo "  cd apps/$app && git init && git add -A && git commit -m 'init' && git remote add origin ${REMOTE}/${app}.git && git push -u origin main"
done
