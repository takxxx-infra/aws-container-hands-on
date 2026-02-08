#!/bin/bash
          
# k6スクリプトを作成
cat > /home/ec2-user/load-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

const TARGET_URL = __ENV.TARGET_URL || 'http://backend-app.sbcntr.local:8081/';
const VUS = __ENV.VUS ? parseInt(__ENV.VUS) : 100;
const ITERATIONS = __ENV.ITERATIONS ? parseInt(__ENV.ITERATIONS) : 1000000;

export const options = ITERATIONS ? {
  // 固定回数実行の設定
  vus: VUS,
  iterations: ITERATIONS,
} : {
  // 時間ベース実行の設定
  vus: VUS,
  duration: __ENV.DURATION || '10m',
};

export default function () {
  const response = http.get(TARGET_URL);

  check(response, {
    'ステータスコードが200': (r) => r.status === 200,
    'レスポンスタイムが3秒以内': (r) => r.timings.duration < 3000,
  });
}
EOF

# ファイルの所有者を設定
chown ec2-user:ec2-user /home/ec2-user/load-test.js